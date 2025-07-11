-- メモのupdated_atスマートトリガー マイグレーション
-- SupabaseのSQL Editorで実行してください

-- メモ専用のスマートな更新トリガー関数を作成
CREATE OR REPLACE FUNCTION update_memo_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- メモの実際の内容が変更された場合のみupdated_atを更新
    -- title, content, rich_content, mode, tags, color_tagの変更時のみ
    IF (OLD.title IS DISTINCT FROM NEW.title OR 
        OLD.content IS DISTINCT FROM NEW.content OR 
        OLD.rich_content IS DISTINCT FROM NEW.rich_content OR 
        OLD.mode IS DISTINCT FROM NEW.mode OR 
        OLD.tags IS DISTINCT FROM NEW.tags OR 
        OLD.color_tag IS DISTINCT FROM NEW.color_tag) THEN
        NEW.updated_at = NOW();
    ELSE
        -- is_pinnedのみの変更などの場合は、updated_atを保持
        NEW.updated_at = OLD.updated_at;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 既存のメモテーブルトリガーを削除
DROP TRIGGER IF EXISTS update_memos_updated_at ON public.memos;

-- 新しいスマートトリガーを適用
CREATE TRIGGER update_memos_updated_at 
    BEFORE UPDATE ON public.memos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_memo_updated_at_column(); 