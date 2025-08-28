
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'services/supabase_service.dart';
import 'widgets/app_bars/collapsible_app_bar.dart';
import 'widgets/overlays/account_info_overlay.dart';
import 'widgets/navigation/custom_bottom_navigation_bar.dart';
import 'screens/task_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/memo_screen.dart';
import 'screens/settings_screen.dart';

// カスタムScrollPhysics for スワイプアニメーション速度調整
class CustomPageScrollPhysics extends ScrollPhysics {
  final double speedMultiplier;
  
  const CustomPageScrollPhysics({
    super.parent,
    this.speedMultiplier = 1.0, // 1.0が標準速度、大きいほど速い、小さいほど遅い
  });

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(
      parent: buildParent(ancestor),
      speedMultiplier: speedMultiplier,
    );
  }

  @override
  SpringDescription get spring => SpringDescription(
        mass: 80.0 / speedMultiplier,        // 質量を調整（小さいほど軽快）
        stiffness: 100.0 * speedMultiplier,  // 剛性を調整（大きいほど速い）
        damping: 1.2,                        // 減衰を調整（大きいほど振動が少ない）
      );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabaseを初期化
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThisOne',
      // 日本語ロケール設定
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語
        Locale('en', 'US'), // 英語（フォールバック）
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE85A3B), // 赤みの強いオレンジ（画像の色に近い）
          secondary: const Color(0xFFE85A3B), // サブカラーも同じ色
          surface: const Color(0xFF2B2B2B), // 全体のベース色
          onPrimary: Colors.white, // オレンジの上の文字色
          onSurface: Colors.white, // サーフェス上の文字色
        ),
        scaffoldBackgroundColor: const Color(0xFF2B2B2B), // Scaffoldの背景色
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // 透明にしてグラデーションを表示
          foregroundColor: Colors.white, // AppBarの文字色
          elevation: 0, // 影を削除
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE85A3B), // FABを程よいオレンジに
          foregroundColor: Colors.white, // FABのアイコン色
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _memos = [];
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isLoadingMemos = true;
  AccountInfoOverlay? _accountInfoOverlay;
  String? _newlyCreatedMemoId; // 新しく作成されたメモのIDを管理
  
  // PageViewController を追加
  late PageController _pageController;

  // GlobalKey for ScheduleScreen
  final GlobalKey _scheduleScreenKey = GlobalKey();

  // スクロール管理のための変数
  final Map<int, ScrollController> _scrollControllers = {};
  double _headerScrollProgress = 0.0; // 0.0=完全表示, 1.0=完全隠れ
  final double _maxScrollDistance = 100.0; // この距離をスクロールすると完全に隠れる

  @override
  void initState() {
    super.initState();
    // PageControllerを初期化
    _pageController = PageController(initialPage: 0);
    
    // ScrollControllersを初期化
    _initializeScrollControllers();
    
    _loadTasks();
    _loadMemos();
    // 認証状態の変更を監視
    _supabaseService.authStateChanges.listen((AuthState data) {
      _loadTasks();
      _loadMemos();
    });
  }

  // ScrollControllersを初期化
  void _initializeScrollControllers() {
    // 各画面用のScrollControllerを作成
    for (int i = 0; i < 4; i++) { // タスク、スケジュール、メモ、設定
      _scrollControllers[i] = ScrollController();
      _scrollControllers[i]!.addListener(() => _onScroll(i));
    }
  }

  // スクロール監視関数（段階的な変化）
  void _onScroll(int pageIndex) {
    final controller = _scrollControllers[pageIndex];
    if (controller == null || !controller.hasClients) return;
    
    // 現在のページのみ監視
    final currentPageIndex = _getCurrentPageIndex();
    if (pageIndex != currentPageIndex) return;
    
    final currentPosition = controller.offset;
    
    // スクロール進行度を計算（0.0〜1.0）
    final newProgress = (currentPosition / _maxScrollDistance).clamp(0.0, 1.0);
    
    // 進行度が変わった場合のみ更新
    if ((_headerScrollProgress - newProgress).abs() > 0.01) {
      setState(() {
        _headerScrollProgress = newProgress;
      });
      
      // デバッグ出力
      print('📊 ヘッダー進行度: ${(_headerScrollProgress * 100).toStringAsFixed(1)}% (スクロール: ${currentPosition.toStringAsFixed(1)}px)');
    }
  }

  // 現在のPageViewインデックスを取得
  int _getCurrentPageIndex() {
    switch (_currentIndex) {
      case 0: return 0; // タスク
      case 1: return 1; // スケジュール
      case 3: return 2; // メモ
      case 4: return 3; // 設定
      default: return 0;
    }
  }

  // ヘッダーの隠れ具合に応じて動的にトップパディングを計算
  double _calculateDynamicTopPadding(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final baseHeaderHeight = 40.0 + 2.0; // AppBar高さ + ガイドライン高さ
    final totalHeaderHeight = statusBarHeight + baseHeaderHeight + 12.0; // 基本オフセット含む
    
    // ヘッダーが隠れた分だけコンテンツを上に詰める
    final hiddenAmount = _headerScrollProgress * (statusBarHeight - 10); // ヘッダーの隠れた分
    final adjustedPadding = totalHeaderHeight - hiddenAmount;
    
    // 最小値として statusBarHeight を保持（完全に上に行きすぎないように）
    final finalPadding = adjustedPadding.clamp(statusBarHeight, totalHeaderHeight);
    
    // デバッグ出力
    if (_headerScrollProgress > 0) {
      print('🔧 パディング調整 - 進行度: ${(_headerScrollProgress * 100).toInt()}%, 隠れた量: ${hiddenAmount.toStringAsFixed(1)}px, パディング: ${finalPadding.toStringAsFixed(1)}px');
    }
    
    return finalPadding;
  }

  // AccountInfoOverlayの遅延初期化
  AccountInfoOverlay get accountInfoOverlay {
    _accountInfoOverlay ??= AccountInfoOverlay(
      context: context,
      onTasksNeedReload: _loadTasks,
    );
    return _accountInfoOverlay!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // ScrollControllersを解放
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    _accountInfoOverlay?.dispose();
    super.dispose();
  }

  // Supabaseからタスクを読み込み
  Future<void> _loadTasks() async {
    try {
      final tasks = await _supabaseService.getUserTasks();
      setState(() {
        _tasks.clear();
        // Supabaseデータを内部形式に変換
        _tasks.addAll(tasks.map((task) => {
          'id': task['id'],
          'title': task['title'],
          'isCompleted': task['is_completed'],
          'createdAt': DateTime.parse(task['created_at']),
          'description': task['description'],
          'dueDate': task['due_date'] != null ? DateTime.parse(task['due_date']) : null,
          'priority': task['priority'],
        }));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タスクの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  // Supabaseからメモを読み込み
  Future<void> _loadMemos() async {
    try {
      final memos = await _supabaseService.getUserMemos();
      setState(() {
        _memos.clear();
        // Supabaseデータを内部形式に変換（データベース側でソート済み）
        _memos.addAll(memos.map((memo) => {
          'id': memo['id'],
          'title': memo['title'],
          'content': memo['content'] ?? '',
          'mode': memo['mode'] ?? 'memo',
          'rich_content': memo['rich_content'],
          'is_pinned': memo['is_pinned'] ?? false, // ピン留め状態を追加
          'tags': memo['tags'] ?? [], // タグを追加
          'color_tag': memo['color_tag'] ?? '#FFD700', // 色タグを追加
          'createdAt': DateTime.parse(memo['created_at']).toLocal(),
          'updatedAt': DateTime.parse(memo['updated_at']).toLocal(),
        }));
        _isLoadingMemos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMemos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの読み込みに失敗しました: $e')),
        );
      }
    }
  }



  // Supabaseにタスクを追加
  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;

    try {
      final newTask = await _supabaseService.addTask(title: title.trim());
      
      if (newTask != null) {
        setState(() {
          _tasks.add({
            'id': newTask['id'],
            'title': newTask['title'],
            'isCompleted': newTask['is_completed'],
            'createdAt': DateTime.parse(newTask['created_at']),
            'description': newTask['description'],
            'dueDate': newTask['due_date'] != null ? DateTime.parse(newTask['due_date']) : null,
            'priority': newTask['priority'],
          });
        });
      } else {
        // 認証されていない場合はローカルに保存
        setState(() {
          _tasks.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': title.trim(),
            'isCompleted': false,
            'createdAt': DateTime.now(),
            'description': null,
            'dueDate': null,
            'priority': 0,
          });
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログインしていないため、タスクはローカルに保存されました'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タスクの保存に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PageViewで表示する画面のリストを作成
    final List<Widget> pages = [
      // 0: タスク画面
      _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE85A3B),
              ),
            )
          : TaskScreen(
              tasks: _tasks,
              onTasksChanged: (updatedTasks) {
                setState(() {
                  _tasks.clear();
                  _tasks.addAll(updatedTasks);
                });
              },
              scrollController: _scrollControllers[0],
            ),
      // 1: カレンダー画面
      ScheduleScreen(
        key: _scheduleScreenKey,
        scrollController: _scrollControllers[1],
      ),
      // 2: メモ画面
      _isLoadingMemos 
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE85A3B),
              ),
            )
          : MemoScreen(
              memos: _memos,
              onMemosChanged: (updatedMemos) {
                setState(() {
                  _memos.clear();
                  _memos.addAll(updatedMemos);
                });
              },
              newlyCreatedMemoId: _newlyCreatedMemoId,
              onPopAnimationComplete: () {
                setState(() {
                  _newlyCreatedMemoId = null;
                });
              },
              scrollController: _scrollControllers[2],
            ),
      // 3: 設定画面
      SettingsScreen(scrollController: _scrollControllers[3]),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // メインコンテンツ（PageView）- 動的パディング調整
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: _calculateDynamicTopPadding(context), // ヘッダーの隠れ具合に応じて調整
              ),
              child: PageView(
                controller: _pageController,
                physics: const PageScrollPhysics(), // 標準のPageScrollPhysicsでページスナップを確実にする
                onPageChanged: (index) {
          // PageViewのインデックスを_currentIndexに変換
          // PageView: 0=タスク, 1=カレンダー, 2=メモ, 3=設定
          // _currentIndex: 0=タスク, 1=カレンダー, 2=作成ボタン, 3=メモ, 4=設定
          int newCurrentIndex;
          switch (index) {
            case 0: // タスク
              newCurrentIndex = 0;
              break;
            case 1: // カレンダー
              newCurrentIndex = 1;
              break;
            case 2: // メモ
              newCurrentIndex = 3;
              break;
            case 3: // 設定
              newCurrentIndex = 4;
              break;
            default:
              newCurrentIndex = 0;
          }
          
          setState(() {
            _currentIndex = newCurrentIndex;
          });
        },
                children: pages,
              ),
            ),
          ),
          // ヘッダーを配置（シンプル構造）
          Positioned(
            top: MediaQuery.of(context).padding.top + 12, // ステータスバー下に配置
            left: 0,
            right: 0,
            child: ClipRect( // 見切れライン制御
              child: CollapsibleAppBar(
                onAccountButtonPressed: () => accountInfoOverlay.handleAccountButtonPressed(),
                scrollProgress: _headerScrollProgress,
              ),
            ),
          ),
          // ステータスバー領域のオーバーレイ（境界線なし）
          if (_headerScrollProgress < 0.95) // 95%以上で完全非表示
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).padding.top,
                  color: const Color(0xFF2B2B2B), // グラデーション削除で境界線回避
                  child: _headerScrollProgress > 0.1 ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_headerScrollProgress * 100).toInt()}%', // 進行度表示
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_headerScrollProgress > 0.2)
                          Text(
                            '🚀', // 最適化ヘッダーアイコン
                            style: TextStyle(fontSize: 8),
                          ),
                      ],
                    ),
                  ) : null,
                ),
              ),
            ),
          // テスト用のボタン（右下に配置）
          Positioned(
            right: 16,
            top: 100,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.red,
              onPressed: () {
                // 段階的テスト：0% → 50% → 100% → 0%の順でテスト
                double newProgress;
                if (_headerScrollProgress < 0.25) {
                  newProgress = 0.5; // 50%に
                } else if (_headerScrollProgress < 0.75) {
                  newProgress = 1.0; // 100%に
                } else {
                  newProgress = 0.0; // 0%に戻す
                }
                
                final currentPadding = _calculateDynamicTopPadding(context);
                print('🔧 最適化ヘッダーテスト - ${(_headerScrollProgress * 100).toInt()}% → ${(newProgress * 100).toInt()}%');
                print('🔧 現在のページインデックス: $_currentIndex');
                print('🔧 現在のトップパディング: ${currentPadding.toStringAsFixed(1)}px');
                print('🔧 最適化完了: シンプル構造で確実な動作');
                setState(() {
                  _headerScrollProgress = newProgress;
                });
              },
              child: Icon(_headerScrollProgress > 0.5 ? Icons.expand_more : Icons.expand_less),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTabChanged: (index) => setState(() => _currentIndex = index),
        pageController: _pageController,
        supabaseService: _supabaseService,
        onTaskAdded: (title) => _addTask(title),
        onMemoCreated: (title, mode, colorHex) => _createMemo(title, mode, colorHex),
        onScheduleCreate: () {
          // スケジュール画面がアクティブな場合、スケジュール作成ボトムシートを開く
          if (_currentIndex == 1) {
            final scheduleScreenState = _scheduleScreenKey.currentState as dynamic;
            if (scheduleScreenState != null) {
              scheduleScreenState.addScheduleFromExternal();
            }
          }
        },
      ),
    );
  }




  // _createMemo メソッドは CustomBottomNavigationBar で使用されるため保持
  Future<void> _createMemo(String title, String mode, String colorHex) async {
    if (!mounted) return; // 最初にmountedをチェック
    final currentContext = context; // Contextをローカル変数で保存
    
    try {
      final newMemo = await _supabaseService.addMemo(
        title: title,
        mode: mode,
        colorHex: colorHex,
      );
      
      if (!mounted) return; // 非同期処理後に再度チェック
      
      if (newMemo != null) {
        // 新しく作成されたメモのIDを設定
        setState(() {
          _newlyCreatedMemoId = newMemo['id'];
        });
        
        // メモリストを再読み込み
        _loadMemos();
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('メモ「$title」を作成しました')),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('ログインしていないため、メモはローカルに保存されました'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // エラー処理でも再度チェック
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('メモの作成に失敗しました: $e'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
        ),
    );
    }
  }
}