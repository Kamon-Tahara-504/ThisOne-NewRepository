import 'package:flutter/material.dart';
import '../../gradients.dart';
import '../../services/supabase_service.dart';
import '../../utils/color_utils.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final PageController pageController;
  final SupabaseService supabaseService;
  final Function(String) onTaskAdded;
  final Function(String, String, String) onMemoCreated;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.pageController,
    required this.supabaseService,
    required this.onTaskAdded,
    required this.onMemoCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    _buildNavItem(context, 0, Icons.task_alt, 'タスク'),
                    _buildNavItem(context, 1, Icons.calendar_today, 'カレンダー'),
                    _buildCreateButton(context),
                    _buildNavItem(context, 3, Icons.note_alt, 'メモ'),
                    _buildNavItem(context, 4, Icons.settings, '設定'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
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
          pageController.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          onTabChanged(index);
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

  Widget _buildCreateButton(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, 5), // 上に移動から下に移動に変更
        child: GestureDetector(
          onTap: () {
            // 作成ボタンのアクション（現在アクティブなタブに応じて）
            if (currentIndex == 0) {
              // タスク作成（TaskScreenに委譲）
              _showCreateTaskDialog(context);
            } else if (currentIndex == 1) {
              // スケジュール作成（ScheduleScreenに委譲）
              _showCreateScheduleDialog(context);
            } else if (currentIndex == 3) {
              // メモ作成（MemoScreenに委譲）
              _showCreateMemoDialog(context);
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

  void _showCreateTaskDialog(BuildContext context) {
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
                supabaseService.getCurrentUser() != null 
                    ? 'アカウントに保存されます'
                    : 'ローカルに保存されます（ログインして同期）',
                style: TextStyle(
                  color: supabaseService.getCurrentUser() != null 
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
               hintText: 'タスクを入力してください',
               hintStyle: TextStyle(color: Colors.grey[400]),
               enabledBorder: UnderlineInputBorder(
                 borderSide: BorderSide(color: Colors.grey[600]!),
               ),
               focusedBorder: const UnderlineInputBorder(
                 borderSide: BorderSide(color: Color(0xFFE85A3B)),
               ),
             ),
             autofocus: false,
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
                gradient: createHorizontalOrangeYellowGradient(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    onTaskAdded(controller.text.trim());
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

  void _showCreateScheduleDialog(BuildContext context) {
    // スケジュール作成のシンプルな実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('スケジュール作成機能（開発中）')),
    );
  }

  void _showCreateMemoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CreateMemoBottomSheet(
          supabaseService: supabaseService,
          onMemoCreated: onMemoCreated,
        );
      },
    );
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF2B2B2B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Row(
                    children: [
                      const Icon(
                        Icons.note_add,
                        color: Color(0xFFE85A3B),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'メモを作成',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.supabaseService.getCurrentUser() != null 
                            ? 'アカウントに保存'
                            : 'ローカルに保存',
                        style: TextStyle(
                          color: widget.supabaseService.getCurrentUser() != null 
                              ? const Color(0xFFE85A3B)
                              : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // タイトル入力
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'タイトル',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                                                 child: TextField(
                           controller: _titleController,
                           style: const TextStyle(color: Colors.white, fontSize: 16),
                           decoration: const InputDecoration(
                             hintText: 'メモのタイトルを入力...',
                             hintStyle: TextStyle(color: Colors.grey),
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.all(16),
                           ),
                           autofocus: false,
                         ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // モード選択
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'メモの種類',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMode = 'memo'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: _selectedMode == 'memo' 
                                      ? createHorizontalOrangeYellowGradient()
                                      : null,
                                  color: _selectedMode == 'memo' 
                                      ? null 
                                      : const Color(0xFF3A3A3A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedMode == 'memo' 
                                        ? Colors.transparent 
                                        : Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.edit_note,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'メモ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMode = 'rich'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: _selectedMode == 'rich' 
                                      ? createHorizontalOrangeYellowGradient()
                                      : null,
                                  color: _selectedMode == 'rich' 
                                      ? null 
                                      : const Color(0xFF3A3A3A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedMode == 'rich' 
                                        ? Colors.transparent 
                                        : Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'リッチ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // 色選択
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '色ラベル',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                                            const SizedBox(height: 16),
                      // カラーパレット（2行5列のグリッド）
                      Column(
                        children: [
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
                                        (colorHex) => setState(() => _selectedColorHex = colorHex),
                                      ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // 作成ボタン
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: createHorizontalOrangeYellowGradient(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = _titleController.text.trim().isNotEmpty 
                            ? _titleController.text.trim() 
                            : '無題';
                        Navigator.pop(context);
                        await widget.onMemoCreated(title, _selectedMode, _selectedColorHex);
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 