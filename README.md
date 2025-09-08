# ThisOne - 生産性向上アプリ

**ThisOne**は、タスク管理・スケジュール管理・メモ機能を統合したFlutter製の生産性向上アプリです。  
モダンなダークテーマとオレンジ-イエローのカスタムグラデーションが特徴的なUIを持ち、Supabaseをバックエンドとして使用しています。

##  主要機能

###  アプリ機能
- **タスク管理** ✅: タスクの追加・完了・削除・更新（Supabase完全連携済み）
- **メモ機能** ✅: リッチテキストエディタ搭載、自動保存機能 (Supabase完全連携済み)
- **ユーザー認証** ✅: サインアップ・ログイン・ログアウト（Supabase Auth完全連携）
- **アカウント管理** ✅: プロフィール編集、ユーザー情報管理（Supabase完全連携済み）
- **スケジュール管理** : カレンダー表示での予定管理（Supabase完全連携済み）
- **設定画面** : アプリケーション設定管理（基本UI実装済み）

###  UI/UX
- **カスタムテーマ**: オレンジ→黄色のグラデーション
- **ダークモード**: 統一された黒基調（#2B2B2B）のUI
- **Material 3**: 最新のマテリアルデザイン採用
- **タブナビゲーション**: 5つの主要機能へのアクセス
- **レスポンシブデザイン**: 各種画面サイズに対応
- **リッチテキストエディタ**: Flutter Quillによる高機能メモエディタ
- **国際化対応**: 日本語ロケール設定済み
- **アニメーション**: スムーズなページ遷移とヘッダー制御
- **カスタムスクロール**: ページスワイプとヘッダー表示制御

###  データ管理
- **Supabaseバックエンド**: PostgreSQLデータベース
- **認証システム**: Supabase Auth統合済み
- **セキュリティ**: Row Level Security (RLS) 実装済み
- **自動保存**: メモの変更内容を自動的に保存（デバウンス機能付き）
- **リアルタイムデータ同期**: 基盤実装済み
- **スマートトリガー**: メモの実際の内容変更時のみ更新時刻を更新
- **データベースマイグレーション**: 段階的な機能追加に対応

##  プロジェクト構造

```
lib/
├── main.dart                          # アプリエントリーポイント・ナビゲーション
├── gradients.dart                     # カスタムグラデーション関数群
├── supabase_config.dart               # Supabase接続設定
├── examples/
│   └── gradient_showcase.dart         # グラデーション表示例
├── services/
│   └── supabase_service.dart          # データベース操作サービス（認証・タスク・メモ・スケジュール）
├── screens/
│   ├── task_screen.dart               # タスク管理画面
│   ├── schedule_screen.dart           # スケジュール管理画面
│   ├── memo_screen.dart               # メモ一覧画面
│   ├── memo_detail_screen.dart        # メモ詳細・編集画面
│   ├── auth_screen.dart               # 認証画面（レガシー）
│   ├── unified_auth_screen.dart       # 統合認証画面
│   ├── account_screen.dart            # アカウント管理画面
│   └── settings_screen.dart           # 設定画面
├── widgets/
│   ├── app_bars/
│   │   ├── collapsible_app_bar.dart   # 折りたたみ可能なアプリバー
│   │   └── custom_app_bar.dart        # カスタムアプリバー
│   ├── auth/
│   │   ├── login_bottom_sheet.dart    # ログインボトムシート
│   │   └── signup_page.dart           # サインアップページ
│   ├── navigation/
│   │   └── custom_bottom_navigation_bar.dart # カスタムボトムナビゲーション
│   ├── overlays/
│   │   └── account_info_overlay.dart  # アカウント情報オーバーレイ
│   ├── schedule/
│   │   └── add_schedule_bottom_sheet.dart # スケジュール追加ボトムシート
│   ├── memo_back_header.dart          # メモ画面ヘッダー
│   ├── memo_filter_header.dart        # メモフィルターヘッダー
│   ├── memo_item_card.dart            # メモアイテムカード
│   ├── memo_save_manager.dart         # メモ自動保存管理
│   ├── empty_memo_state.dart          # 空のメモ状態表示
│   ├── color_palette.dart             # カラーパレット
│   ├── quill_color_panel.dart         # Quillカラーパネル
│   ├── quill_rich_editor.dart         # リッチテキストエディタ
│   └── quill_toolbar.dart             # エディタツールバー
└── utils/
    ├── calculator_utils.dart          # 計算ユーティリティ
    └── color_utils.dart               # カラーユーティリティ

database/
├── schema/
│   └── initial_schema.sql             # データベーススキーマ定義
└── migrations/
    ├── 001_memo_mode.sql              # メモモード追加
    ├── 002_phone_field.sql            # 電話番号フィールド追加
    ├── 003_rich_content.sql           # リッチコンテンツ対応
    ├── 004_smart_trigger.sql          # スマートトリガー実装
    └── 005_add_schedule_color.sql     # スケジュール色設定追加
```

##  データベース構造

### テーブル一覧
```sql
-- ユーザープロファイル
user_profiles (id, user_id, display_name, phone_number, avatar_url, created_at, updated_at)

-- タスク管理（完全実装済み）
tasks (id, user_id, title, description, is_completed, priority, due_date, created_at, updated_at, completed_at)

-- メモ機能（完全実装済み）
memos (id, user_id, title, content, mode, rich_content, is_pinned, color_tag, created_at, updated_at)

-- スケジュール管理（完全実装済み）
schedules (id, user_id, title, description, schedule_date, start_time, end_time, is_all_day, location, reminder_minutes, color_hex, created_at, updated_at)

-- ユーザー設定（準備済み）
user_settings (id, user_id, theme_mode, notification_enabled, default_reminder_minutes, first_day_of_week, created_at, updated_at)
```

##  セットアップ手順

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Supabaseプロジェクトの設定

1. [Supabase](https://supabase.com)でアカウント作成・プロジェクト作成
2. ダッシュボードの「Settings」→「API」から以下を取得：
   - **Project URL**
   - **Anon public key**

### 3. データベーススキーマの作成

1. Supabaseダッシュボードの「SQL Editor」を開く
2. `database/schema/initial_schema.sql`の内容をコピー&実行
3. 必要に応じてマイグレーションファイルも実行：
   - `database/migrations/001_memo_mode.sql`
   - `database/migrations/002_phone_field.sql`
   - `database/migrations/003_rich_content.sql`
   - `database/migrations/004_smart_trigger.sql`
   - `database/migrations/005_add_schedule_color.sql`

### 4. 設定ファイルの更新

`lib/supabase_config.dart`を編集：

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 5. アプリの実行

```bash
flutter run --verbose
```

##  現在の実装状況

### ✅ 完了機能
- [x] 基本UI・ナビゲーション設計
- [x] カスタムグラデーションシステム
- [x] **認証システム（Supabase完全連携）**
  - [x] サインアップ・ログイン・ログアウト
  - [x] 認証状態管理
  - [x] エラーハンドリング
  - [x] 統合認証画面（サインアップ・ログイン統合）
- [x] **タスク管理（Supabase完全連携）**
  - [x] タスクの追加・完了・削除・更新
  - [x] 優先度・期日管理
  - [x] リアルタイム同期
- [x] **メモ機能（Supabase完全連携）**
  - [x] リッチテキストエディタ（Flutter Quill）
  - [x] 自動保存機能（デバウンス機能付き）
  - [x] メモの追加・編集・削除
  - [x] リッチコンテンツ保存（JSON Delta形式）
  - [x] カラータグ・ピン留め機能
  - [x] メモモード（memo/note）対応
- [x] **スケジュール管理（Supabase完全連携）**
  - [x] カレンダー表示（table_calendar）
  - [x] スケジュールの追加・編集・削除
  - [x] 日時指定・終日設定
  - [x] リマインダー設定
  - [x] カラーテーマ対応
- [x] **アカウント管理（Supabase完全連携）**
  - [x] ユーザープロフィール編集
  - [x] 表示名・電話番号管理
  - [x] プロフィール自動作成
- [x] **設定画面（基本UI実装）**
  - [x] アカウント設定への遷移
  - [x] 通知・テーマ・データ・プライバシー設定項目
  - [x] ヘルプ・アプリ情報項目
- [x] Supabase設定・サービス層
- [x] データベーススキーマ設計・作成
- [x] RLSセキュリティ設定
- [x] 国際化設定（日本語対応）
- [x] アニメーション・UI/UX改善
- [x] カスタムスクロール制御

### 🚧 開発中・今後の予定
- [ ] **設定画面の機能実装**
  - [ ] テーマ設定（ダーク/ライト/システム）
  - [ ] 通知設定（リマインダー・プッシュ通知）
  - [ ] データ設定（バックアップ・エクスポート）
  - [ ] プライバシー設定
  - [ ] ヘルプ・サポート機能
- [ ] **追加機能**
  - [ ] プッシュ通知機能
  - [ ] データエクスポート・インポート機能
  - [ ] オフライン対応
  - [ ] タスクとスケジュールの連携機能
  - [ ] モバイル通知欄でのタスク表示
  - [ ] 他言語対応（英語）
  - [ ] データ同期の最適化
  - [ ] パフォーマンス向上
  - [ ] タスクの機能改善
  - [ ] タスク作成画面のUI/UX作成
  - [ ] タスクでのアラーム機能実装
  - [ ] 設定画面の実装

##  技術スタック

- **Frontend**: Flutter 3.7.2+ (Dart)
- **Backend**: Supabase (PostgreSQL)
- **認証**: Supabase Auth
- **状態管理**: StatefulWidget + Stream監視
- **UI**: Material 3 + カスタムテーマ
- **カレンダー**: table_calendar パッケージ
- **リッチテキスト**: flutter_quill パッケージ
- **国際化**: intl + flutter_localizations
- **フォント**: google_fonts パッケージ
- **アニメーション**: Flutter Animation Framework
- **データベース**: PostgreSQL with RLS

##  主要な依存関係

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Supabase dependencies
  supabase_flutter: ^2.5.6
  
  # UI関連
  table_calendar: ^3.0.9
  google_fonts: ^6.1.0
  
  # 国際化
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
  
  # リッチテキストエディタ
  flutter_quill: ^11.4.1
  flutter_quill_extensions: ^11.0.0
```

##  開発環境

- **Flutter SDK**: 3.7.2+
- **Dart**: 3.0+
- **プラットフォーム**: iOS, Android, Web対応

##  セキュリティ

- **Row Level Security (RLS)**: 各ユーザーは自分のデータのみアクセス可能
- **認証必須**: 全ての機能で認証が必要
- **APIキー管理**: 本番環境では環境変数使用推奨
- **自動ログアウト**: セッション管理による安全な認証状態管理

### 自動保存システム
- メモ編集中の内容を自動的に保存（デバウンス機能付き）
- ネットワーク接続状態を考慮した堅牢な保存機能
- 保存状態の視覚的フィードバック
- スマートトリガーによる効率的な更新時刻管理

### リッチテキストエディタ
- 太字、斜体、下線などの基本的なテキスト装飾
- カラーパレットによる文字色・背景色変更
- インデント・リスト機能
- JSON Delta形式での効率的なデータ保存
- カスタムツールバーとカラーパネル

### 統合認証システム
- Supabase Authによる安全な認証
- 自動プロフィール作成
- 認証状態の監視とリアルタイム更新
- 統合認証画面（サインアップ・ログイン統合）

### スケジュール管理システム
- カレンダー表示による直感的な予定管理
- 日時指定・終日設定対応
- リマインダー機能
- カラーテーマによる視覚的分類
- Supabase完全連携によるデータ同期

### UI/UX改善
- スムーズなページ遷移アニメーション
- カスタムスクロール制御
- ヘッダーの動的表示/非表示
- レスポンシブデザイン対応

##  参考リソース

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Material 3 Design](https://m3.material.io/)
- [Table Calendar Package](https://pub.dev/packages/table_calendar)
- [Flutter Quill Documentation](https://pub.dev/packages/flutter_quill)

##  commitメッセージ

- feat：新機能追加
- fix：バグ修正
- hotfix：クリティカルなバグ修正
- add：新規（ファイル）機能追加
- update：機能修正（バグではない）
- change：仕様変更
- clean：整理（リファクタリング等）
- disable：無効化（コメントアウト等）
- remove：削除（ファイル）
- upgrade：バージョンアップ
- revert：変更取り消し
- docs：ドキュメント修正（README、コメント等）
- tyle：コードフォーマット修正（インデント、スペース等）
- perf：パフォーマンス改善
- test：テストコード追加・修正
- ci：CI/CD 設定変更（GitHub Actions 等）
- build：ビルド関連変更（依存関係、ビルドツール設定等）
- chore：雑務的変更（ユーザーに直接影響なし）
 

##  Contributing

プロジェクトへの貢献は歓迎します！  
新しい機能の提案やバグ報告は、GitHubのIssueでお知らせください。

*README最終更新: 2025年 9月8日*  
*これらのREADME.mdはAIによる分析と現在の実装状況に基づく生成です*
