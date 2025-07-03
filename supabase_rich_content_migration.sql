-- memosテーブルにrich_contentカラムを追加するマイグレーション
-- SupabaseのSQL Editorで実行してください

-- rich_contentカラムを追加（リッチテキストのQuill Delta形式をJSON文字列として保存）
ALTER TABLE public.memos 
ADD COLUMN IF NOT EXISTS rich_content TEXT;

-- 既存のレコードのrich_contentはNULLのまま（プレーンテキストとして扱う）
-- 新しいメモではrich_contentとcontentの両方を保存し、
-- rich_contentが存在する場合はそちらを優先して表示する

-- インデックスは不要（検索対象にしない）
COMMENT ON COLUMN public.memos.rich_content IS 'Quill Delta format JSON for rich text content'; 