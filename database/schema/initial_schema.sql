-- ThisOneアプリ用 Supabaseテーブル構造定義
-- SupabaseのSQL Editorで実行してください

-- 1. ユーザープロファイルテーブル（認証システムと連携）
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 2. タスクテーブル
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  priority INTEGER DEFAULT 0, -- 0: low, 1: medium, 2: high
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- 3. スケジュールテーブル  
CREATE TABLE IF NOT EXISTS public.schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  schedule_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME,
  is_all_day BOOLEAN DEFAULT FALSE,
  location TEXT,
  reminder_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. メモテーブル
CREATE TABLE IF NOT EXISTS public.memos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  tags TEXT[], -- タグ配列
  is_pinned BOOLEAN DEFAULT FALSE,
  color_tag TEXT DEFAULT '#FFD700', -- 色分け用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 設定テーブル（ユーザー設定）
CREATE TABLE IF NOT EXISTS public.user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_mode TEXT DEFAULT 'dark', -- 'dark', 'light', 'system'
  notification_enabled BOOLEAN DEFAULT TRUE,
  default_reminder_minutes INTEGER DEFAULT 15,
  first_day_of_week INTEGER DEFAULT 0, -- 0: Sunday, 1: Monday
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Row Level Security (RLS) の有効化
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- RLSポリシーの作成（ユーザーは自分のデータのみアクセス可能）

-- user_profiles ポリシー
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- tasks ポリシー
CREATE POLICY "Users can view own tasks" ON public.tasks
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tasks" ON public.tasks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tasks" ON public.tasks
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own tasks" ON public.tasks
    FOR DELETE USING (auth.uid() = user_id);

-- schedules ポリシー
CREATE POLICY "Users can view own schedules" ON public.schedules
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own schedules" ON public.schedules
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own schedules" ON public.schedules
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own schedules" ON public.schedules
    FOR DELETE USING (auth.uid() = user_id);

-- memos ポリシー
CREATE POLICY "Users can view own memos" ON public.memos
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own memos" ON public.memos
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own memos" ON public.memos
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own memos" ON public.memos
    FOR DELETE USING (auth.uid() = user_id);

-- user_settings ポリシー
CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.user_settings
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- インデックスの作成（パフォーマンス向上）
CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_tasks_created_at ON public.tasks(created_at);
CREATE INDEX idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX idx_schedules_user_id ON public.schedules(user_id);
CREATE INDEX idx_schedules_date ON public.schedules(schedule_date);
CREATE INDEX idx_memos_user_id ON public.memos(user_id);
CREATE INDEX idx_memos_created_at ON public.memos(created_at);

-- 更新日時の自動更新用トリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- メモ専用のスマートな更新トリガー関数
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

-- 各テーブルに updated_at 自動更新トリガーを設定
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON public.schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- メモテーブルには専用のスマートトリガーを使用
DROP TRIGGER IF EXISTS update_memos_updated_at ON public.memos;
CREATE TRIGGER update_memos_updated_at BEFORE UPDATE ON public.memos FOR EACH ROW EXECUTE FUNCTION update_memo_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 