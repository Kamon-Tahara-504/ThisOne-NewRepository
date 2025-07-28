import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../gradients.dart';
import '../../utils/color_utils.dart';

class AddScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onAdd;

  const AddScheduleBottomSheet({
    super.key,
    required this.selectedDate,
    required this.onAdd,
  });

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  bool _isAllDay = false;
  String _selectedColorHex = '#9E9E9E';
  bool _isNotificationEnabled = false;
  int _reminderMinutes = 15;
  bool _showDetailedSettings = false;
  late PageController _pageController;

  // 通知時間オプション
  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5分前', 'minutes': 5},
    {'label': '15分前', 'minutes': 15},
    {'label': '30分前', 'minutes': 30},
    {'label': '1時間前', 'minutes': 60},
    {'label': '1日前', 'minutes': 1440},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addSchedule() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.onAdd({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': widget.selectedDate,
        'startTime': _startTime,
        'endTime': _endTime,
        'isAllDay': _isAllDay,
        'colorHex': _selectedColorHex,
        'notificationMode': _isNotificationEnabled ? 'reminder' : 'none',
        'reminderMinutes': _isNotificationEnabled ? _reminderMinutes : 0,
        'isAlarmEnabled': false,
        'createdAt': DateTime.now(),
      });
      Navigator.pop(context);
    }
  }

  Widget _buildColorOption(Map<String, dynamic> colorOption) {
    final isSelected = _selectedColorHex == colorOption['hex'];
    final colorHex = colorOption['hex'] as String;
    final isGradient = colorOption['isGradient'] as bool;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedColorHex = colorHex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : ColorUtils.getColorFromHex(colorHex),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2B2B2B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: PageView(
                  controller: _pageController,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _showDetailedSettings = index == 1;
                    });
                  },
                  children: [
                    SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
                      child: _buildBasicSettings(),
                    ),
                    SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
                      child: _buildDetailedSettings(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 第1段階：基本設定
  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示
        Text(
          '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // タイトル
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
              child: const Icon(
                Icons.event_note,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'スケジュール作成',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // タイトル入力
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
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
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'スケジュールのタイトルを入力...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 時間設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 終日設定
                Row(
                  children: [
                    const Text(
                      '終日',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isAllDay,
                      onChanged: (value) => setState(() => _isAllDay = value),
                      activeColor: const Color(0xFFE85A3B),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[700],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 時間設定
                AnimatedOpacity(
                  opacity: _isAllDay ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isAllDay,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '開始時間',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime,
                                  );
                                  if (time != null) {
                                    setState(() => _startTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A3A3A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[600]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '終了時間',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime,
                                  );
                                  if (time != null) {
                                    setState(() => _endTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A3A3A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[600]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
        const SizedBox(height: 10),
        
        // 色設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
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
                const SizedBox(height: 8),
                // カラーパレット（横スクロール一列）
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8), // 左端の余白
                      for (int i = 0; i < ColorUtils.colorLabelPalette.length; i++) ...[
                        _buildColorOption(ColorUtils.colorLabelPalette[i]),
                        if (i < ColorUtils.colorLabelPalette.length - 1)
                          const SizedBox(width: 12), // アイテム間の間隔
                      ],
                      const SizedBox(width: 8), // 右端の余白
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // ボタン
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    '詳細設定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _addSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 第2段階：詳細設定
  Widget _buildDetailedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示
        Text(
          '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // タイトル
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '詳細設定',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 説明入力
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '説明',
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
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '詳細な説明を入力...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 通知設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 通知スイッチ
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '通知を有効にする',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isNotificationEnabled,
                      onChanged: (value) => setState(() => _isNotificationEnabled = value),
                      activeColor: const Color(0xFFE85A3B),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[700],
                    ),
                  ],
                ),
                
                // 通知設定詳細
                AnimatedOpacity(
                  opacity: _isNotificationEnabled ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isNotificationEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '通知タイミング',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _reminderOptions.map((option) {
                            final isSelected = _reminderMinutes == option['minutes'];
                            return GestureDetector(
                              onTap: () => setState(() => _reminderMinutes = option['minutes']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE85A3B) : const Color(0xFF3A3A3A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey[600]!,
                                  ),
                                ),
                                child: Text(
                                  option['label'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // ボタン
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    '戻る',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _addSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'スケジュールを作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 