# 段階的リファクタリング計画

## 目的
**既存コードを壊さず**、段階的にClean Architectureに移行する

## 重要な原則
1. **各Phaseでビルドが通ること**
2. **各Phaseでアプリが動作すること**
3. **既存コードは段階的に置き換える（一気に削除しない）**
4. **各Phase後にコミット**

---

## Phase 1: Repository層の追加（既存コードに影響なし）

### 目的
- Repository層の基礎を作成
- 既存のSupabaseServiceは残す

### 作業内容
```
lib/
├── repositories/              # 新規作成
│   ├── auth_repository.dart
│   ├── task_repository.dart
│   └── memo_repository.dart
└── services/                  # 既存（そのまま）
    ├── supabase_service.dart
    └── main_data_service.dart
```

### チェックリスト
- [ ] ディレクトリ作成
- [ ] Repository抽象クラス作成
- [ ] Repository実装クラス作成（SupabaseServiceをラップ）
- [ ] ビルド確認: `flutter analyze`
- [ ] コミット

---

## Phase 2: Riverpodの導入（main.dartのみ変更）

### 目的
- Riverpodの基礎設定
- 既存の状態管理は残す

### 作業内容
```dart
// pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.9

// main.dart（変更箇所のみ）
void main() {
  runApp(
    ProviderScope(  // ← 追加
      child: MyApp(),
    ),
  );
}
```

### チェックリスト
- [ ] flutter_riverpod追加
- [ ] ProviderScope追加
- [ ] lib/providers/ ディレクトリ作成
- [ ] Repository用Provider作成
- [ ] ビルド確認
- [ ] アプリ起動確認
- [ ] コミット

---

## Phase 3: UseCase層の追加（既存コードに影響なし）

### 目的
- UseCase層の基礎を作成
- まだ使用はしない

### 作業内容
```
lib/
├── usecases/                  # 新規作成
│   ├── task/
│   │   └── task_usecases.dart
│   └── memo/
│       └── memo_usecases.dart
```

### チェックリスト
- [ ] ディレクトリ作成
- [ ] UseCase作成
- [ ] ビルド確認
- [ ] コミット

---

## Phase 4: TaskScreenの移行（1画面のみ）

### 目的
- 実際に新しいアーキテクチャを使用
- 1画面だけで動作確認

### 作業内容
```dart
// 従来（そのまま残す）
class TaskScreen extends StatefulWidget {
  final MainDataService dataService;
  // ...
}

// 新規（別ファイルで作成）
class TaskScreenRiverpod extends ConsumerWidget {
  // Repository経由でデータ取得
  // ...
}
```

### チェックリスト
- [ ] TaskProvider作成
- [ ] TaskScreenをConsumerWidgetに変換（新ファイル）
- [ ] main.dartで切り替え可能にする
- [ ] 動作確認
- [ ] 問題なければ古いTaskScreenを削除
- [ ] コミット

---

## Phase 5: 他の画面の移行

### 目的
- 残りの画面を順次移行

### 作業内容
1. MemoScreen移行
2. ScheduleScreen移行
3. SettingsScreen移行

### チェックリスト（各画面ごと）
- [ ] Provider作成
- [ ] 画面をConsumerWidgetに変換
- [ ] 動作確認
- [ ] 古いコード削除
- [ ] コミット

---

## Phase 6: MainDataServiceの削除

### 目的
- 古い状態管理を完全に削除

### 作業内容
```dart
// 削除対象
- lib/services/main_data_service.dart

// main.dartから削除
- MainDataService関連のコード
```

### チェックリスト
- [ ] 全画面がRiverpod化されていることを確認
- [ ] MainDataService削除
- [ ] ビルド確認
- [ ] 全機能の動作確認
- [ ] コミット

---

## Phase 7: SupabaseServiceのリファクタリング

### 目的
- SupabaseServiceを小さくする
- Repository実装に統合

### 作業内容
```
Before:
lib/services/supabase_service.dart (1317行)

After:
lib/data/datasources/
├── supabase_auth_datasource.dart
├── supabase_task_datasource.dart
└── supabase_memo_datasource.dart
```

### チェックリスト
- [ ] DataSource層を作成
- [ ] Repository実装を更新
- [ ] SupabaseService削除
- [ ] ビルド確認
- [ ] 全機能の動作確認
- [ ] コミット

---

## Phase 8: ディレクトリ構造の整理（最終段階）

### 目的
- Clean Architectureの完全な構造に

### 作業内容
```
lib/
├── core/
│   ├── errors/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

### チェックリスト
- [ ] 段階的にファイルを移動
- [ ] importパスを更新（少しずつ）
- [ ] 各ステップでビルド確認
- [ ] コミット

---

## 現在の進捗

- [x] Phase 1: Repository層の追加
- [x] Phase 2: Riverpod導入
- [x] Phase 3: UseCase層追加
- [x] Phase 4: TaskScreen移行
- [x] Phase 5: 他画面移行
- [ ] Phase 6: MainDataService削除
- [ ] Phase 7: SupabaseService分割
- [ ] Phase 8: ディレクトリ整理

---

## 注意事項

### やってはいけないこと
❌ 一気に複数のPhaseを進める
❌ ビルドが通らない状態でコミット
❌ 動作確認せずに次のリファクタリング
❌ 既存コードを一気に削除

### やるべきこと
✅ 各Phase後に必ずビルド確認
✅ 各Phase後に動作確認
✅ 小さくコミット
✅ 問題が出たらすぐロールバック

- 開始日 : 2025/10/2