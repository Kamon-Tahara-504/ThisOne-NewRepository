# Flutter App with Supabase

カスタムグラデーションテーマとSupabase連携を持つFlutterアプリケーションです。

## 機能

- **カスタムテーマ**: オレンジから黄色のグラデーション
- **Supabase連携**: 認証とデータベース操作
- **モダンUI**: Material 3デザイン

## セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Supabaseプロジェクトの作成

1. [Supabase](https://supabase.com)にアカウントを作成
2. 新しいプロジェクトを作成
3. プロジェクトのダッシュボードから以下の情報を取得：
   - **Project URL** (API設定から)
   - **Anon public key** (API設定から)

### 3. 設定ファイルの更新

`lib/supabase_config.dart` ファイルを開いて、以下の値を更新してください：

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL'; // ここを更新
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // ここを更新
  
  // ...
}
```

## プロジェクト構造

```
lib/
├── main.dart                 # アプリのエントリーポイント
├── gradients.dart           # グラデーション関数
├── supabase_config.dart     # Supabase設定
├── services/
│   └── supabase_service.dart # Supabaseサービスクラス
└── screens/
    └── auth_screen.dart     # 認証画面
```

## 利用可能な機能

### カスタムグラデーション
```dart
import 'gradients.dart';

// 水平グラデーション
Container(
  decoration: BoxDecoration(
    gradient: createHorizontalOrangeYellowGradient(),
  ),
  child: YourWidget(),
)

// 垂直グラデーション
Container(
  decoration: BoxDecoration(
    gradient: createVerticalOrangeYellowGradient(),
  ),
  child: YourWidget(),
)

// 円形グラデーション
Container(
  decoration: BoxDecoration(
    gradient: createRadialOrangeYellowGradient(),
  ),
  child: YourWidget(),
)
```

### Supabase認証
```dart
import 'services/supabase_service.dart';

final supabaseService = SupabaseService();

// ユーザー登録
await supabaseService.signUp(
  email: 'user@example.com',
  password: 'password123',
);

// ログイン
await supabaseService.signIn(
  email: 'user@example.com',
  password: 'password123',
);

// ログアウト
await supabaseService.signOut();
```

### データベース操作
```dart
// データを取得
final data = await supabaseService.getData('your_table_name');

// データを挿入
await supabaseService.insertData('your_table_name', {
  'column1': 'value1',
  'column2': 'value2',
});

// データを更新
await supabaseService.updateData(
  'your_table_name',
  {'column1': 'new_value'},
  'id',
  123,
);

// データを削除
await supabaseService.deleteData('your_table_name', 'id', 123);
```

### 認証画面の表示
```dart
import 'screens/auth_screen.dart';

// AuthScreenをNavigatorで表示
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AuthScreen()),
);
```

## アプリの実行

```bash
flutter run
```

## 注意事項

- 本番環境では環境変数を使用してAPIキーを管理することを推奨します
- Supabaseのセキュリティルール（RLS）を適切に設定してください
- 認証が必要な画面では、認証状態をチェックしてください

## 次のステップ

1. Supabaseダッシュボードでテーブルを作成
2. Row Level Security (RLS) を設定
3. 認証プロバイダーの設定（必要に応じて）
4. リアルタイム機能の実装（必要に応じて）

## Flutter学習リソース

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
