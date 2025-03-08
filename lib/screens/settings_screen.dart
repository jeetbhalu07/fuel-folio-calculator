
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_provider.dart';
import '../models/calculation_history_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real app, you would use package_info_plus to get the actual version
    setState(() {
      _appVersion = prefs.getString('appVersion') ?? '1.0.0';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Appearance section
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(),
          
          const Divider(),
          
          // Data section
          _buildSectionHeader('Data Management'),
          _buildClearHistoryOption(),
          
          const Divider(),
          
          // About section
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: _appVersion,
          ),
          _buildListTile(
            icon: Icons.rate_review_outlined,
            title: 'Rate This App',
            onTap: () => _launchPlayStore(),
          ),
          _buildListTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: () => _shareApp(),
          ),
          _buildListTile(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            onTap: () => _launchEmail(),
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchURL('https://example.com/privacy'),
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchURL('https://example.com/terms'),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      children: [
        _buildListTile(
          icon: Icons.brightness_6_outlined,
          title: 'Theme',
          subtitle: _getThemeModeName(themeProvider.themeMode),
          onTap: () => _showThemeDialog(themeProvider),
        ),
      ],
    );
  }
  
  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }
  
  void _showThemeDialog(ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(ThemeMode.system, 'System Default', provider),
            _buildThemeOption(ThemeMode.light, 'Light Mode', provider),
            _buildThemeOption(ThemeMode.dark, 'Dark Mode', provider),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeOption(ThemeMode mode, String name, ThemeProvider provider) {
    return RadioListTile<ThemeMode>(
      title: Text(name),
      value: mode,
      groupValue: provider.themeMode,
      onChanged: (ThemeMode? value) {
        if (value != null) {
          provider.setThemeMode(value);
          Navigator.pop(context);
        }
      },
    );
  }
  
  Widget _buildClearHistoryOption() {
    return _buildListTile(
      icon: Icons.delete_outline,
      title: 'Clear Calculation History',
      onTap: () => _showClearHistoryDialog(),
    );
  }
  
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear your calculation history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final historyProvider = Provider.of<CalculationHistoryProvider>(context, listen: false);
              historyProvider.clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
  
  void _launchPlayStore() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=app.fuelcalculator.pro'
    );
    await _launchURL(url.toString());
  }
  
  void _shareApp() {
    // In real app, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality would open here')),
    );
  }
  
  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@fuelcalculator.app',
      queryParameters: {
        'subject': 'Fuel Calculator Pro Support',
      }
    );
    await _launchURL(emailLaunchUri.toString());
  }
  
  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }
}
