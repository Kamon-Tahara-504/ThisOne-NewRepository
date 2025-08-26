-- スケジュールテーブルに色情報フィールドを追加
-- SupabaseのSQL Editorで実行してください

-- schedules テーブルに color_hex フィールドを追加
ALTER TABLE public.schedules 
ADD COLUMN color_hex TEXT DEFAULT '#E85A3B';

-- 既存のスケジュールにデフォルト色を設定
UPDATE public.schedules 
SET color_hex = '#E85A3B' 
WHERE color_hex IS NULL;
