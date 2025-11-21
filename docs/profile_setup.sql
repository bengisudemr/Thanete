-- Profil özellikleri için Supabase kurulum script'i
-- Bu script'i Supabase SQL Editor'da çalıştırın

-- 1. profiles tablosunu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  avatar_url TEXT,
  birth_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Eksik sütunları ekle (eğer tablo zaten varsa)
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS name TEXT;

ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS birth_date TIMESTAMPTZ;

ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3. RLS (Row Level Security) politikaları
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Eğer politikalar zaten varsa önce sil
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Profil görüntüleme politikası
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Profil güncelleme politikası
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Profil oluşturma politikası
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 4. avatars storage bucket oluştur
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 5. avatars storage politikaları
-- Eğer politikalar zaten varsa önce sil
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

-- Avatar yükleme politikası
-- Path format: userId/fileName, so foldername(name)[1] is userId
CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatar görüntüleme politikası
CREATE POLICY "Users can view own avatar" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatar silme politikası
CREATE POLICY "Users can delete own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatar güncelleme politikası (upsert için)
CREATE POLICY "Users can update own avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 6. updated_at için trigger (eğer yoksa)
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_updated_at();
