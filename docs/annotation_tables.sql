-- Supabase tabloları için SQL script
-- Bu script'i Supabase SQL Editor'da çalıştırın

-- 1. note_files tablosu
CREATE TABLE IF NOT EXISTS note_files (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('image', 'pdf', 'document')),
  file_size INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. file_annotations tablosu
CREATE TABLE IF NOT EXISTS file_annotations (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  file_id TEXT REFERENCES note_files(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  drawing_strokes JSONB DEFAULT '[]'::jsonb,
  text_notes JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RLS (Row Level Security) politikaları
ALTER TABLE note_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_annotations ENABLE ROW LEVEL SECURITY;

-- note_files için RLS politikaları
CREATE POLICY "Users can view their own files" ON note_files
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own files" ON note_files
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own files" ON note_files
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own files" ON note_files
  FOR DELETE USING (auth.uid() = user_id);

-- file_annotations için RLS politikaları
CREATE POLICY "Users can view their own annotations" ON file_annotations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own annotations" ON file_annotations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own annotations" ON file_annotations
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own annotations" ON file_annotations
  FOR DELETE USING (auth.uid() = user_id);

-- 4. Storage bucket oluşturma
INSERT INTO storage.buckets (id, name, public)
VALUES ('note-files', 'note-files', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Storage politikaları
CREATE POLICY "Users can upload their own files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'note-files' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'note-files' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own files" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'note-files' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 6. Index'ler
CREATE INDEX IF NOT EXISTS idx_note_files_user_id ON note_files(user_id);
CREATE INDEX IF NOT EXISTS idx_note_files_created_at ON note_files(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_file_annotations_file_id ON file_annotations(file_id);
CREATE INDEX IF NOT EXISTS idx_file_annotations_user_id ON file_annotations(user_id);

-- 7. Trigger'lar (updated_at otomatik güncelleme)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_note_files_updated_at
  BEFORE UPDATE ON note_files
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_file_annotations_updated_at
  BEFORE UPDATE ON file_annotations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
