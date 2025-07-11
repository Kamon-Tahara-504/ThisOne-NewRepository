-- 既存のuser_profilesテーブルに電話番号フィールドを追加するマイグレーション
-- SupabaseのSQL Editorで実行してください

-- user_profilesテーブルにphone_numberカラムを追加（既に存在する場合はエラーを出さない）
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'phone_number'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone_number TEXT;
    END IF;
END $$;

-- 電話番号フィールドにインデックスを追加（検索の高速化用）
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone_number ON public.user_profiles(phone_number);

-- 同じ電話番号での重複を防ぐ場合は以下のコメントを外してください
-- CREATE UNIQUE INDEX IF NOT EXISTS uniq_user_profiles_phone_number ON public.user_profiles(phone_number) WHERE phone_number IS NOT NULL; 