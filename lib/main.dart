
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gradients.dart';
import 'supabase_config.dart';
import 'services/supabase_service.dart';
import 'utils/color_utils.dart'; // 色分けラベル用のユーティリティを追加
import 'widgets/app_bars/custom_app_bar.dart';
import 'screens/auth_screen.dart';
import 'screens/account_screen.dart';
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
  OverlayEntry? _accountOverlay;
  String? _newlyCreatedMemoId; // 新しく作成されたメモのIDを管理
  
  // PageViewController を追加
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // PageControllerを初期化
    _pageController = PageController(initialPage: 0);
    _loadTasks();
    _loadMemos();
    // 認証状態の変更を監視
    _supabaseService.authStateChanges.listen((AuthState data) {
      _loadTasks();
      _loadMemos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _navigateToAccountOrAuth() async {
    final user = _supabaseService.getCurrentUser();
    
    if (user != null) {
      // ログイン済みの場合はアカウント画面に移動
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountScreen()),
      );
      
      // アカウント画面から戻った時にタスクを再読み込み（ログアウトした可能性）
      if (result == true || result == null) {
        _loadTasks();
      }
    } else {
      // 未ログインの場合は認証画面に移動
      final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
      
      // 認証画面から戻った時にタスクを再読み込み
      if (result == true) {
        _loadTasks();
      }
    }
  }

  void _handleAccountButtonPressed() {
    final user = _supabaseService.getCurrentUser();
    
    if (user != null) {
      // ログイン済みの場合：アカウント情報を表示
      if (_accountOverlay != null) {
        // 既に表示されている場合は閉じる
        _closeAccountOverlay();
      } else {
        // まだ表示されていない場合は開く
        _showAccountInfoOverlay();
      }
    } else {
      // 未ログインの場合：認証画面に移動
      _navigateToAccountOrAuth();
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
            ),
      // 1: カレンダー画面
      const ScheduleScreen(),
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
            ),
      // 3: 設定画面
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        onAccountButtonPressed: _handleAccountButtonPressed,
      ),
      body: PageView(
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B), // 黒背景
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // グラデーションガイドライン（上部）
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: createHorizontalOrangeYellowGradient(),
              ),
            ),
            // ナビゲーションバー本体
            Container(
              color: const Color(0xFF2B2B2B),
              child: SafeArea(
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      _buildNavItem(0, Icons.task_alt, 'タスク'),
                      _buildNavItem(1, Icons.calendar_today, 'カレンダー'),
                      _buildCreateButton(),
                      _buildNavItem(3, Icons.note_alt, 'メモ'),
                      _buildNavItem(4, Icons.settings, '設定'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _closeAccountOverlay() {
    if (_accountOverlay != null) {
      _accountOverlay!.remove();
      _accountOverlay = null;
    }
  }

  void _showAccountInfoOverlay() async {
    final user = _supabaseService.getCurrentUser();
    if (user == null) return;

    // 既存のオーバーレイがあれば先に閉じる
    _closeAccountOverlay();

    final overlay = Overlay.of(context);

    _accountOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _closeAccountOverlay(), // タップで閉じる
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // ポップアップ本体
            Positioned(
              top: MediaQuery.of(context).padding.top + 40 + 8, // ヘッダー高さ + 余白
              right: 16, // 右端から16px
              child: GestureDetector(
                onTap: () {}, // ポップアップ内のタップは伝播を止める
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildAccountInfoContent(user),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_accountOverlay!);
  }

  Widget _buildAccountInfoContent(dynamic user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabaseService.getUserProfile(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        
        return Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ログイン状態表示
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: const Color(0xFFE85A3B),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => createHorizontalOrangeYellowGradient().createShader(bounds),
                    child: const Text(
                      'ログイン中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ユーザー名
              Text(
                'ユーザー名',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userProfile?['display_name']?.isNotEmpty == true
                    ? userProfile!['display_name']
                    : '未設定',
                style: TextStyle(
                  color: userProfile?['display_name']?.isNotEmpty == true
                      ? Colors.white
                      : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              // メールアドレス
              Text(
                'メールアドレス',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? '未設定',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
                             // アカウント管理リンク
                              GestureDetector(
                 onTap: () {
                   _closeAccountOverlay();
                   _navigateToAccountOrAuth();
                 },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(1), // グラデーション境界線の幅
                  decoration: BoxDecoration(
                    gradient: createHorizontalOrangeYellowGradient(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A), // 背景色を元に戻す
                      borderRadius: BorderRadius.circular(7), // 少し小さくして境界線を見せる
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => createHorizontalOrangeYellowGradient().createShader(bounds),
                      child: const Text(
                        'アカウント管理',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // 作成ボタン（index 2）の場合はページ遷移しない
          if (index == 2) {
            return;
          }
          
          // _currentIndexからPageViewのインデックスに変換
          // _currentIndex: 0=タスク, 1=カレンダー, 2=作成ボタン, 3=メモ, 4=設定
          // PageView: 0=タスク, 1=カレンダー, 2=メモ, 3=設定
          int pageIndex;
          switch (index) {
            case 0: // タスク
              pageIndex = 0;
              break;
            case 1: // カレンダー
              pageIndex = 1;
              break;
            case 3: // メモ
              pageIndex = 2;
              break;
            case 4: // 設定
              pageIndex = 3;
              break;
            default:
              pageIndex = 0;
          }
          
          // PageViewをアニメーション付きで移動
          _pageController.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => isSelected
                    ? createHorizontalOrangeYellowGradient().createShader(bounds)
                    : LinearGradient(
                        colors: [Colors.grey[500]!, Colors.grey[500]!],
                      ).createShader(bounds),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => isSelected
                    ? createHorizontalOrangeYellowGradient().createShader(bounds)
                    : LinearGradient(
                        colors: [Colors.grey[500]!, Colors.grey[500]!],
                      ).createShader(bounds),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, 5), // 上に移動から下に移動に変更
        child: GestureDetector(
          onTap: () {
            // 作成ボタンのアクション（現在アクティブなタブに応じて）
            if (_currentIndex == 0) {
              // タスク作成（TaskScreenに委譲）
              _showCreateTaskDialog();
            } else if (_currentIndex == 1) {
              // スケジュール作成（ScheduleScreenに委譲）
              _showCreateScheduleDialog();
            } else if (_currentIndex == 3) {
              // メモ作成（MemoScreenに委譲）
              _showCreateMemoDialog();
            }
          },
          child: Container(
            width: 60, // さらに少し大きくしてはみ出し効果を強調
            height: 60,
            decoration: BoxDecoration(
              gradient: createOrangeYellowGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE85A3B).withValues(alpha: 0.4), // 影を少し濃く
                  blurRadius: 12, // 影を大きく
                  offset: const Offset(0, 4), // 影の位置も調整
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // 追加の影で立体感
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Color(0xFF2B2B2B), // UIデザインで使われている黒色に変更
              size: 34, // アイコンサイズも少し大きく
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3A3A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
            'タスク追加',
            style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                _supabaseService.getCurrentUser() != null 
                    ? 'アカウントに保存されます'
                    : 'ローカルに保存されます（ログインして同期）',
                style: TextStyle(
                  color: _supabaseService.getCurrentUser() != null 
                      ? const Color(0xFFE85A3B)
                      : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'タスク名',
              labelStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE85A3B)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: createOrangeYellowGradient(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    // 直接MainScreenのタスクリストに追加
                    _addTask(controller.text.trim());
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('タスク「${controller.text.trim()}」を追加しました')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  '追加',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateScheduleDialog() {
    // スケジュール作成のシンプルな実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('スケジュール作成機能（開発中）')),
    );
  }

  void _showCreateMemoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CreateMemoBottomSheet(
          supabaseService: _supabaseService,
          onMemoCreated: (title, mode, colorHex) async {
            await _createMemo(title, mode, colorHex);
          },
        );
      },
    );
  }



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

// メモ作成ボトムシート（独立したStatefulWidget）
class _CreateMemoBottomSheet extends StatefulWidget {
  final SupabaseService supabaseService;
  final Function(String, String, String) onMemoCreated;

  const _CreateMemoBottomSheet({
    required this.supabaseService,
    required this.onMemoCreated,
  });

  @override
  State<_CreateMemoBottomSheet> createState() => _CreateMemoBottomSheetState();
}

class _CreateMemoBottomSheetState extends State<_CreateMemoBottomSheet> {
  late TextEditingController _titleController;
  String _selectedMode = 'memo';
  String _selectedColorHex = ColorUtils.defaultColorHex;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 色選択オプション（強化版）
  Widget _buildEnhancedColorOption(Map<String, dynamic> colorItem, String selectedColorHex, Function(String) onColorSelected) {
    final colorHex = colorItem['hex'] as String;
    final isGradient = colorItem['isGradient'] as bool;
    final color = colorItem['color'] as Color?;
    final isSelected = selectedColorHex == colorHex;

    return GestureDetector(
      onTap: () => onColorSelected(colorHex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 入力欄以外をタップしたときにキーボードを隠す
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF2B2B2B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトルとグラデーション
                  Row(
                    children: [
                                          const Text(
                      'メモ作成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                      const Spacer(),
                      // 閉じるボタン
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // サブタイトル
                  Row(
                    children: [
                      Icon(
                        widget.supabaseService.getCurrentUser() != null 
                            ? Icons.cloud_done 
                            : Icons.storage,
                        size: 16,
                        color: widget.supabaseService.getCurrentUser() != null 
                            ? const Color(0xFFE85A3B)
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.supabaseService.getCurrentUser() != null 
                            ? 'アカウントに保存されます'
                            : 'ローカルに保存されます（ログインして同期）',
                        style: TextStyle(
                          color: widget.supabaseService.getCurrentUser() != null 
                              ? const Color(0xFFE85A3B)
                              : Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // メインコンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル入力
                  Text(
                    'タイトル',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'メモのタイトルを入力...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 色選択
                  Text(
                    '色ラベル',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      children: [
                        // 選択された色のプレビュー
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: ColorUtils.colorLabelPalette
                                    .firstWhere((color) => color['hex'] == _selectedColorHex)['isGradient']
                                    ? ColorUtils.getGradientFromHex(_selectedColorHex)
                                    : null,
                                color: ColorUtils.colorLabelPalette
                                    .firstWhere((color) => color['hex'] == _selectedColorHex)['isGradient']
                                    ? null
                                    : ColorUtils.colorLabelPalette
                                        .firstWhere((color) => color['hex'] == _selectedColorHex)['color'],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '選択中の色',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // カラーパレット（5x2のグリッド）
                        for (int row = 0; row < 2; row++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int col = 0; col < 5; col++)
                                  if (row * 5 + col < ColorUtils.colorLabelPalette.length)
                                    _buildEnhancedColorOption(
                                      ColorUtils.colorLabelPalette[row * 5 + col],
                                      _selectedColorHex,
                                      (colorHex) {
                                        setState(() {
                                          _selectedColorHex = colorHex;
                                        });
                                      },
                                    ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // モード選択
                  Text(
                    'モード',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedMode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      dropdownColor: const Color(0xFF3A3A3A),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: const [
                        DropdownMenuItem(
                          value: 'memo',
                          child: Text('メモモード'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMode = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // 作成ボタン
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: createOrangeYellowGradient(),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE85A3B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          await widget.onMemoCreated(_titleController.text.trim(), _selectedMode, _selectedColorHex);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'メモを作成',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
