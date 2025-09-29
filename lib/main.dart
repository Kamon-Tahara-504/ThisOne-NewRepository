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
import 'utils/error_handler.dart';
import 'models/memo.dart';
import 'models/task.dart';

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
    mass: 80.0 / speedMultiplier, // 質量を調整（小さいほど軽快）
    stiffness: 100.0 * speedMultiplier, // 剛性を調整（大きいほど速い）
    damping: 1.2, // 減衰を調整（大きいほど振動が少ない）
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
        // Androidシミュレーター対応：フォントファミリーを明示的に設定
        fontFamily: 'Roboto',
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
  // 定数定義
  static const int _taskPageIndex = 0;
  static const int _schedulePageIndex = 1;
  static const int _memoPageIndex = 2;
  static const int _settingsPageIndex = 3;
  static const int _memoTabIndex = 3;
  static const int _settingsTabIndex = 4;
  static const double _headerHeight = 54.0;
  static const double _scrollSensitivity = 10.0;
  static const double _scrollThreshold = 5.0;
  static const Duration _headerAnimationDuration = Duration(milliseconds: 200);

  // 状態変数
  int _currentIndex = 0;
  final List<Task> _tasks = [];
  final List<Memo> _memos = [];
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isLoadingMemos = true;
  AccountInfoOverlay? _accountInfoOverlay;
  String? _newlyCreatedMemoId;

  // コントローラー（メモリリーク対策）
  late PageController _pageController;
  final GlobalKey _scheduleScreenKey = GlobalKey();
  final Map<int, ScrollController> _scrollControllers = {};
  bool _isDisposed = false; // 二重dispose防止

  // ヘッダー制御
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0.0;

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

  // ScrollControllersを初期化（メモリリーク対策）
  void _initializeScrollControllers() {
    if (_isDisposed) return; // dispose後の初期化防止

    final pageCount = 4; // タスク、スケジュール、メモ、設定
    for (int i = 0; i < pageCount; i++) {
      // 既存のコントローラーがあれば先にdispose
      _scrollControllers[i]?.dispose();

      _scrollControllers[i] = ScrollController();
      _scrollControllers[i]!.addListener(() => _onScroll(i));
    }
  }

  // スクロール制御（メモリリーク対策）
  void _onScroll(int pageIndex) {
    if (_isDisposed || !mounted) return; // dispose後やマウント解除後の処理防止

    final controller = _scrollControllers[pageIndex];
    if (controller == null ||
        !controller.hasClients ||
        controller.hasClients == false)
      return;

    // 現在のページのみ監視
    final currentPageIndex = _getCurrentPageIndex();
    if (pageIndex != currentPageIndex) return;

    final currentPosition = controller.offset;
    final scrollDelta = currentPosition - _lastScrollPosition;

    // 最小スクロール量のフィルタ
    if (scrollDelta.abs() > _scrollSensitivity) {
      final shouldChangeState = _shouldChangeHeaderVisibility(scrollDelta);
      if (shouldChangeState && mounted) {
        setState(() {});
      }
    }

    // 前回位置を更新
    _lastScrollPosition = currentPosition;
  }

  // ヘッダーの表示/非表示を変更すべきかを判定
  bool _shouldChangeHeaderVisibility(double scrollDelta) {
    if (scrollDelta > 0) {
      // 下スクロール：ヘッダーを隠す
      if (_isHeaderVisible && scrollDelta > _scrollSensitivity) {
        _isHeaderVisible = false;
        return true;
      }
    } else {
      // 上スクロール：ヘッダーを表示
      if (!_isHeaderVisible && (-scrollDelta) > _scrollThreshold) {
        _isHeaderVisible = true;
        return true;
      }
    }
    return false;
  }

  // 現在のPageViewインデックスを取得
  int _getCurrentPageIndex() {
    switch (_currentIndex) {
      case _taskPageIndex:
        return _taskPageIndex;
      case _schedulePageIndex:
        return _schedulePageIndex;
      case _memoTabIndex:
        return _memoPageIndex;
      case _settingsTabIndex:
        return _settingsPageIndex;
      default:
        return _taskPageIndex;
    }
  }

  // 動的トップパディング計算
  double _calculateDynamicTopPadding(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseOffset = 4.0;
    final baseTop = statusBarHeight + baseOffset;

    // 表示時は通常、非表示時は詰める
    return _isHeaderVisible ? baseTop + _headerHeight : statusBarHeight;
  }

  // ヘッダー位置制御
  double _calculateHeaderTop(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseOffset = 4.0;
    final baseTop = statusBarHeight + baseOffset;

    // 表示/非表示の切り替え
    return _isHeaderVisible ? baseTop : baseTop - _headerHeight;
  }

  // PageViewのページ変更処理
  void _onPageChanged(int index) {
    // PageViewのインデックスを_currentIndexに変換
    // PageView: 0=タスク, 1=カレンダー, 2=メモ, 3=設定
    // _currentIndex: 0=タスク, 1=カレンダー, 2=作成ボタン, 3=メモ, 4=設定
    final newCurrentIndex = _convertPageIndexToTabIndex(index);
    setState(() {
      _currentIndex = newCurrentIndex;
    });
  }

  // PageViewのインデックスをタブインデックスに変換
  int _convertPageIndexToTabIndex(int pageIndex) {
    switch (pageIndex) {
      case _taskPageIndex:
        return _taskPageIndex;
      case _schedulePageIndex:
        return _schedulePageIndex;
      case _memoPageIndex:
        return _memoTabIndex;
      case _settingsPageIndex:
        return _settingsTabIndex;
      default:
        return _taskPageIndex;
    }
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
    if (_isDisposed) return; // 二重dispose防止
    _isDisposed = true;

    try {
      _pageController.dispose();
    } catch (e) {
      debugPrint('PageController dispose error: $e');
    }

    // ScrollControllersを安全に解放
    for (final entry in _scrollControllers.entries) {
      try {
        entry.value.dispose();
      } catch (e) {
        debugPrint('ScrollController dispose error for ${entry.key}: $e');
      }
    }
    _scrollControllers.clear();

    // AccountInfoOverlayを安全に解放
    try {
      _accountInfoOverlay?.dispose();
      _accountInfoOverlay = null;
    } catch (e) {
      debugPrint('AccountInfoOverlay dispose error: $e');
    }

    super.dispose();
  }

  // Supabaseからタスクを読み込み（型安全版・メモリリーク対策）
  Future<void> _loadTasks() async {
    if (_isDisposed || !mounted) return;

    try {
      final tasks = await _supabaseService.getUserTasksTyped();
      if (!_isDisposed && mounted) {
        setState(() {
          _tasks.clear();
          _tasks.addAll(tasks);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの読み込み',
          onRetry: _loadTasks,
        );
      }
    }
  }

  // Supabaseからメモを読み込み（型安全版・メモリリーク対策）
  Future<void> _loadMemos() async {
    if (_isDisposed || !mounted) return;

    try {
      final memos = await _supabaseService.getUserMemosTyped();
      if (!_isDisposed && mounted) {
        setState(() {
          _memos.clear();
          _memos.addAll(memos);
          _isLoadingMemos = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoadingMemos = false;
        });
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'メモの読み込み',
          onRetry: _loadMemos,
        );
      }
    }
  }

  // Supabaseにタスクを追加（メモリリーク対策）
  Future<void> _addTask(String title) async {
    if (_isDisposed || !mounted || title.trim().isEmpty) return;

    try {
      final newTask = await _supabaseService.addTaskTyped(title: title.trim());

      if (!_isDisposed && mounted) {
        if (newTask != null) {
          setState(() {
            _tasks.add(newTask);
          });
        } else {
          // 認証されていない場合はローカルに保存
          final localTask = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: 'local',
            title: title.trim(),
            isCompleted: false,
            priority: TaskPriority.low,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          setState(() {
            _tasks.add(localTask);
          });

          AppErrorHandler.showInfo(context, 'ログインしていないため、タスクはローカルに保存されました');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの保存',
          onRetry: () => _addTask(title),
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
            child: CircularProgressIndicator(color: Color(0xFFE85A3B)),
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
            child: CircularProgressIndicator(color: Color(0xFFE85A3B)),
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
                physics:
                    const PageScrollPhysics(), // 標準のPageScrollPhysicsでページスナップを確実にする
                onPageChanged: _onPageChanged,
                children: pages,
              ),
            ),
          ),
          // アニメーションヘッダー
          AnimatedPositioned(
            duration: _headerAnimationDuration,
            curve: Curves.easeInOut,
            top: _calculateHeaderTop(context),
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー
                CollapsibleAppBar(
                  onAccountButtonPressed:
                      () => accountInfoOverlay.handleAccountButtonPressed(),
                  scrollProgress: _isHeaderVisible ? 0.0 : 1.0,
                ),
                // ガイドライン
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE85A3B),
                        const Color(0xFFFFA726),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ヘッダー文字マスク
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).padding.top + 15,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2B2B2B),
                      const Color(0xFF2B2B2B),
                      const Color(0xFF2B2B2B).withValues(alpha: 0.0),
                      const Color(0xFF2B2B2B).withValues(alpha: 0.0),
                    ],
                    stops: [0.0, 0.6, 0.85, 1.0],
                  ),
                ),
              ),
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
        onMemoCreated:
            (title, mode, colorHex) => _createMemo(title, mode, colorHex),
        onScheduleCreate: _handleScheduleCreate,
      ),
    );
  }

  // スケジュール作成処理
  void _handleScheduleCreate() {
    // スケジュール画面がアクティブな場合、スケジュール作成ボトムシートを開く
    if (_currentIndex == _schedulePageIndex) {
      final scheduleScreenState = _scheduleScreenKey.currentState as dynamic;
      scheduleScreenState?.addScheduleFromExternal();
    }
  }

  // _createMemo メソッドは CustomBottomNavigationBar で使用されるため保持
  Future<void> _createMemo(String title, String mode, String colorHex) async {
    if (!mounted) return;

    try {
      // modeをMemoModeに変換
      final memoMode = MemoMode.fromString(mode);
      final newMemo = await _supabaseService.addMemoTyped(
        title: title,
        mode: memoMode,
        colorHex: colorHex,
      );

      if (!mounted) return;

      if (newMemo != null) {
        // 新しく作成されたメモのIDを設定
        setState(() {
          _newlyCreatedMemoId = newMemo.id;
        });

        // メモリストを再読み込み
        _loadMemos();
      } else {
        if (mounted) {
          AppErrorHandler.showInfo(context, 'ログインしていないため、メモはローカルに保存されました');
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'メモの作成',
          onRetry: () => _createMemo(title, mode, colorHex),
        );
      }
    }
  }
}
