# ThisOne - Database Schema & Migrations

このフォルダには、ThisOneアプリのSupabaseデータベース設計とマイグレーションファイルが含まれています。

## 📁 フォルダ構造

```
database/
├── schema/
│   └── initial_schema.sql          # 初期データベーススキーマ
├── migrations/
│   ├── 001_memo_mode.sql          # メモモード機能追加
│   ├── 002_phone_field.sql        # 電話番号フィールド追加
│   ├── 003_rich_content.sql       # リッチコンテンツ機能追加
│   └── 004_smart_trigger.sql      # スマートトリガー（ピン留め対応）
└── README.md                      # このファイル
```

## 🚀 セットアップ手順

### 1. 初期スキーマの作成
```sql
-- schema/initial_schema.sql を実行
-- 基本的なテーブル、インデックス、RLSポリシーを作成
```

### 2. マイグレーションの適用
必要に応じて以下のマイグレーションを順番に実行：

```sql
-- 001_memo_mode.sql - メモモード機能
-- 002_phone_field.sql - 電話番号フィールド
-- 003_rich_content.sql - リッチコンテンツ
-- 004_smart_trigger.sql - スマートトリガー
```

## 📋 各マイグレーションの説明

- **001_memo_mode**: メモテーブルに`mode`カラムを追加
- **002_phone_field**: ユーザープロファイルに電話番号フィールドを追加
- **003_rich_content**: メモテーブルに`rich_content`カラムを追加
- **004_smart_trigger**: ピン留め時に`updated_at`を更新しないスマートトリガー

## ⚠️ 注意事項

- マイグレーションは番号順に実行してください
- 本番環境では実行前にバックアップを取ってください
- 各マイグレーションは冪等性があるように設計されています 