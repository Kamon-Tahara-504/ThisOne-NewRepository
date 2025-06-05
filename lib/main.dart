import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gradients.dart';
import 'supabase_config.dart';
import 'services/supabase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/task_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/memo_screen.dart';
import 'screens/settings_screen.dart';

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
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // 認証状態の変更を監視
    _supabaseService.authStateChanges.listen((AuthState data) {
      _loadTasks();
    });
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

  void _navigateToAuth() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
    
    // 認証画面から戻った時にタスクを再読み込み
    if (result == true) {
      _loadTasks();
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
    // 中央の作成ボタン（index 2）は画面を表示しないので、インデックスを調整
    Widget currentScreen;
    if (_currentIndex == 0) {
      currentScreen = _isLoading 
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
            );
    } else if (_currentIndex == 1) {
      currentScreen = const ScheduleScreen();
    } else if (_currentIndex == 3) {
      currentScreen = const MemoScreen();
    } else if (_currentIndex == 4) {
      currentScreen = const SettingsScreen();
    } else {
      // デフォルトはタスク画面
      currentScreen = _isLoading 
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
            );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40.0), // 56pxから40pxに縮小
        child: Container(
          color: const Color(0xFF2B2B2B), // 全体を黒背景に統一
          child: Column(
            children: [
              // ステータスバー部分（黒背景に変更）
              Container(
                height: MediaQuery.of(context).padding.top,
                width: double.infinity,
                color: const Color(0xFF2B2B2B), // 黒背景
              ),
              // AppBar部分（黒背景）
              Expanded(
                child: Container(
                  color: const Color(0xFF2B2B2B), // サブカラーの黒
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // 縦パディングを追加
                          child: Row(
                            children: [
                              // ヘッダー左寄せのタイトル 
                              Transform.translate(
                                offset: const Offset(0, -6), // 2px上に移動
                                child: Text(
                                  'ThisOne',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500, // 文字の太さ
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const Spacer(), // 右側にスペースを作る
                              // 右側にアイコンを配置（インスタグラム風）
                              IconButton(
                                onPressed: _navigateToAuth,
                                padding: const EdgeInsets.all(4), // アイコンボタンのパディングを縮小
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                icon: Icon(
                                  _supabaseService.getCurrentUser() != null 
                                      ? Icons.person 
                                      : Icons.person_outline,
                                  color: _supabaseService.getCurrentUser() != null 
                                      ? const Color(0xFFE85A3B)
                                      : Colors.white,
                                  size: 26, // 24pxから26pxに拡大
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // グラデーションガイドライン
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: createHorizontalOrangeYellowGradient(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: currentScreen,
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
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
    // メモ作成のシンプルな実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('メモ作成機能（開発中）')),
    );
  }
}