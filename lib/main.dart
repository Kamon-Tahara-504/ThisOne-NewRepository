import 'package:flutter/material.dart';
import 'gradients.dart';
import 'supabase_config.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabaseを初期化
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThisOne',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE85A3B), // 赤みの強いオレンジ（画像の色に近い）
          secondary: const Color(0xFFE85A3B), // サブカラーも同じ色
          surface: const Color(0xFF2B2B2B), // 全体のベース色
          background: const Color(0xFF2B2B2B), // 背景色
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
      home: const MyHomePage(title: 'ThisOne'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void _navigateToAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0), // 標準的なAppBarの高さ
        child: Container(
          decoration: BoxDecoration(
            gradient: createHorizontalOrangeYellowGradient(),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // 左寄せのタイトル
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20, // ヘッダーの文字のピクセル数
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(), // 右側にスペースを作る
                  // 右側にアイコンを配置（インスタグラム風）
                  IconButton(
                    onPressed: _navigateToAuth,
                    icon: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // Supabase認証画面へのボタン
            Container(
              decoration: BoxDecoration(
                gradient: createHorizontalOrangeYellowGradient(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _navigateToAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'ログイン / サインアップ',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: createOrangeYellowGradient(),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
