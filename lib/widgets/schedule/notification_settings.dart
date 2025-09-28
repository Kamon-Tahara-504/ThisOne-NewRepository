import 'package:flutter/material.dart';
import '../../gradients.dart';

class NotificationSettings extends StatelessWidget {
  final bool isEnabled;
  final List<Map<String, dynamic>> reminderOptions;
  final bool isCustomReminder;
  final int reminderMinutes;
  final int customValue;
  final String customUnit; // 'minutes' | 'hours' | 'days'
  final ValueChanged<bool> onEnabledChange;
  final ValueChanged<int> onSelectPresetMinutes;
  final VoidCallback onTapCustom;

  const NotificationSettings({
    super.key,
    required this.isEnabled,
    required this.reminderOptions,
    required this.isCustomReminder,
    required this.reminderMinutes,
    required this.customValue,
    required this.customUnit,
    required this.onEnabledChange,
    required this.onSelectPresetMinutes,
    required this.onTapCustom,
  });

  String _customLabel() {
    final unitLabel =
        customUnit == 'minutes'
            ? '分'
            : customUnit == 'hours'
            ? '時間'
            : '日';
    return 'カスタム ($customValue$unitLabel前)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '通知設定',
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
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final segmentCount = 2;
                    final segmentWidth =
                        (constraints.maxWidth - 4) / segmentCount;
                    final knobLeft = isEnabled ? 2.0 + segmentWidth : 2.0;
                    return SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F2F2F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            left: knobLeft,
                            top: 2,
                            bottom: 2,
                            width: segmentWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient:
                                    createHorizontalOrangeYellowGradient(),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => onEnabledChange(false),
                                  child: Center(
                                    child: Text(
                                      '通知なし',
                                      style: TextStyle(
                                        color:
                                            !isEnabled
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => onEnabledChange(true),
                                  child: Center(
                                    child: Text(
                                      '通知あり',
                                      style: TextStyle(
                                        color:
                                            isEnabled
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: isEnabled ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !isEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          children:
                              reminderOptions.map((option) {
                                final isCustomOption = option['minutes'] == -1;
                                final optionMinutes = option['minutes'] as int;
                                final isSelected =
                                    isCustomOption
                                        ? isCustomReminder
                                        : reminderMinutes == optionMinutes &&
                                            !isCustomReminder;
                                final label =
                                    isCustomOption && isCustomReminder
                                        ? _customLabel()
                                        : option['label'] as String;

                                return GestureDetector(
                                  onTap: () {
                                    if (isCustomOption) {
                                      onTapCustom();
                                    } else {
                                      onSelectPresetMinutes(optionMinutes);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFFE85A3B)
                                              : const Color(0xFF3A3A3A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.transparent
                                                : Colors.grey[600]!,
                                      ),
                                    ),
                                    child: Text(
                                      label,
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
      ],
    );
  }
}
