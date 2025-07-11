-- memosテーブルにmodeカラムを追加するマイグレーション
-- SupabaseのSQL Editorで実行してください

-- modeカラムを追加（デフォルトは'memo'）
ALTER TABLE public.memos 
ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT 'memo';

-- 既存のレコードにデフォルト値を設定
UPDATE public.memos 
SET mode = 'memo' 
WHERE mode IS NULL;

-- mode カラムにNOT NULL制約を追加
ALTER TABLE public.memos 
ALTER COLUMN mode SET NOT NULL;

-- modeカラムのインデックスを作成（検索パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_memos_mode ON public.memos(mode); 