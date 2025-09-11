import 'package:flutter/material.dart';
import '../gradients.dart';
import 'account_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const SettingsScreen({super.key, this.scrollController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Column(
        children: [
          // ヘッダーエリア
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '設定',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 設定リスト
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingItem(
                  icon: Icons.person,
                  title: 'アカウント',
                  subtitle: 'プロフィールとアカウント設定',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.notifications,
                  title: '通知',
                  subtitle: '通知とリマインダーの設定',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.palette,
                  title: 'テーマ',
                  subtitle: 'アプリの外観をカスタマイズ',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.backup,
                  title: 'データ',
                  subtitle: 'バックアップと同期',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'プライバシー',
                  subtitle: 'セキュリティとプライバシー設定',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.help,
                  title: 'ヘルプ',
                  subtitle: 'よくある質問とサポート',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.info,
                  title: 'アプリについて',
                  subtitle: 'バージョン情報とライセンス',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: createOrangeYellowGradient(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[500]),
        onTap: onTap,
      ),
    );
  }
}
