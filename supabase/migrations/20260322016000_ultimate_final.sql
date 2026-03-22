-- ULTIMATE FINAL SETUP - VICTORIA FOOTBALL CLUB
-- Uses CASCADE to handle all dependencies properly

-- Step 1: Drop everything with CASCADE to handle dependencies
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.has_role(uuid, app_role) CASCADE;

-- Step 2: Drop all policies
DROP POLICY IF EXISTS "Profiles viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Profiles viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can manage roles" ON public.user_roles;
DROP POLICY IF EXISTS "Players viewable by all" ON public.players;
DROP POLICY IF EXISTS "Admins can manage players" ON public.players;
DROP POLICY IF EXISTS "Players viewable by everyone" ON public.players;
DROP POLICY IF EXISTS "Fixtures viewable" ON public.fixtures;
DROP POLICY IF EXISTS "Admins can manage fixtures" ON public.fixtures;
DROP POLICY IF EXISTS "Published news viewable" ON public.news;
DROP POLICY IF EXISTS "Admins can manage news" ON public.news;
DROP POLICY IF EXISTS "Anyone can submit academy application" ON public.academy_applications;
DROP POLICY IF EXISTS "Admins can view academy applications" ON public.academy_applications;
DROP POLICY IF EXISTS "Anyone can submit donation" ON public.donations;
DROP POLICY IF EXISTS "Admins can view donations" ON public.donations;
DROP POLICY IF EXISTS "Gallery viewable by all" ON public.gallery;
DROP POLICY IF EXISTS "Admins can manage gallery" ON public.gallery;
DROP POLICY IF EXISTS "Gallery viewable by everyone" ON public.gallery;

-- Step 3: Drop storage policies
DROP POLICY IF EXISTS "Public read players" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload players" ON storage.objects;
DROP POLICY IF EXISTS "Public read news" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload news" ON storage.objects;
DROP POLICY IF EXISTS "Public read gallery" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload gallery" ON storage.objects;
DROP POLICY IF EXISTS "Auth read academy" ON storage.objects;
DROP POLICY IF EXISTS "Public upload academy" ON storage.objects;

-- Step 4: Drop triggers
DROP TRIGGER IF EXISTS update_profiles_ts ON public.profiles;
DROP TRIGGER IF EXISTS update_players_ts ON public.players;
DROP TRIGGER IF EXISTS update_fixtures_ts ON public.fixtures;
DROP TRIGGER IF EXISTS update_news_ts ON public.news;

-- Step 5: Drop tables (in correct order due to dependencies)
DROP TABLE IF EXISTS public.gallery;
DROP TABLE IF EXISTS public.donations;
DROP TABLE IF EXISTS public.academy_applications;
DROP TABLE IF EXISTS public.news;
DROP TABLE IF EXISTS public.fixtures;
DROP TABLE IF EXISTS public.players;
DROP TABLE IF EXISTS public.user_roles;
DROP TABLE IF EXISTS public.profiles;

-- Step 6: Drop types
DROP TYPE IF EXISTS public.fixture_status;
DROP TYPE IF EXISTS public.app_role;

-- Step 7: Create fresh database schema
-- Create app roles enum
CREATE TYPE public.app_role AS ENUM ('ceo', 'admin', 'coach', 'player', 'fan');
CREATE TYPE public.fixture_status AS ENUM ('draft', 'submitted', 'approved', 'published');

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User roles table
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  role app_role NOT NULL,
  UNIQUE (user_id, role)
);

-- Players table
CREATE TABLE public.players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  position TEXT NOT NULL,
  jersey_number INTEGER,
  age INTEGER,
  bio TEXT,
  photo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Fixtures table
CREATE TABLE public.fixtures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_team TEXT NOT NULL,
  away_team TEXT NOT NULL,
  home_score INTEGER,
  away_score INTEGER,
  match_date TIMESTAMP WITH TIME ZONE,
  venue TEXT,
  competition TEXT NOT NULL,
  status fixture_status NOT NULL DEFAULT 'draft',
  match_report TEXT,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- News table
CREATE TABLE public.news (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  video_url TEXT,
  youtube_url TEXT,
  author TEXT NOT NULL DEFAULT 'Reagan Otema',
  category TEXT NOT NULL DEFAULT 'General',
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Academy applications
CREATE TABLE public.academy_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  birth_certificate_url TEXT,
  parent_contact TEXT NOT NULL,
  position TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Donations
CREATE TABLE public.donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  donor_name TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  currency TEXT NOT NULL DEFAULT 'UGX',
  message TEXT,
  payment_method TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Gallery
CREATE TABLE public.gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  image_url TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Matches',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Step 8: Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fixtures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academy_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery ENABLE ROW LEVEL SECURITY;

-- Step 9: Create helper functions
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role) $$;

-- Step 10: Create OPEN policies - UNRESTRICTED ACCESS
-- Profiles - Everyone can view, users can manage their own
CREATE POLICY "Profiles viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);

-- User roles - Users can view their own roles, admins can manage
CREATE POLICY "Users can view own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage roles" ON public.user_roles FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Players - Everyone can view, admins can manage
CREATE POLICY "Players viewable by everyone" ON public.players FOR SELECT USING (true);
CREATE POLICY "Admins can manage players" ON public.players FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Fixtures - Everyone can view published, authenticated can view all
CREATE POLICY "Fixtures viewable by everyone" ON public.fixtures FOR SELECT USING (status = 'published' OR auth.uid() IS NOT NULL);
CREATE POLICY "Admins can manage fixtures" ON public.fixtures FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo') OR public.has_role(auth.uid(), 'coach'));

-- News - Everyone can view published
CREATE POLICY "Published news viewable by everyone" ON public.news FOR SELECT USING (is_published = true OR (auth.uid() IS NOT NULL AND (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'))));
CREATE POLICY "Admins can manage news" ON public.news FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Academy applications - Anyone can submit, admins can view
CREATE POLICY "Anyone can submit academy application" ON public.academy_applications FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can view academy applications" ON public.academy_applications FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Donations - Anyone can submit, admins can view
CREATE POLICY "Anyone can submit donation" ON public.donations FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can view donations" ON public.donations FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Gallery - Everyone can view, admins can manage
CREATE POLICY "Gallery viewable by everyone" ON public.gallery FOR SELECT USING (true);
CREATE POLICY "Admins can manage gallery" ON public.gallery FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'ceo'));

-- Step 11: Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('players', 'players', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('news', 'news', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('gallery', 'gallery', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('academy', 'academy', false) ON CONFLICT (id) DO NOTHING;

-- Step 12: Storage policies
CREATE POLICY "Public read players" ON storage.objects FOR SELECT USING (bucket_id = 'players');
CREATE POLICY "Auth upload players" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'players');
CREATE POLICY "Public read news" ON storage.objects FOR SELECT USING (bucket_id = 'news');
CREATE POLICY "Auth upload news" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'news');
CREATE POLICY "Public read gallery" ON storage.objects FOR SELECT USING (bucket_id = 'gallery');
CREATE POLICY "Auth upload gallery" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'gallery');
CREATE POLICY "Auth read academy" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'academy');
CREATE POLICY "Public upload academy" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'academy');

-- Step 13: Timestamp triggers
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER update_profiles_ts BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_players_ts BEFORE UPDATE ON public.players FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_fixtures_ts BEFORE UPDATE ON public.fixtures FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_news_ts BEFORE UPDATE ON public.news FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- SUCCESS: Victoria FC database setup complete with CASCADE handling!
-- Anyone can sign up and use the application immediately.
