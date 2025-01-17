import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;
  String theme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notifications'),
            _buildSettingCard(
              icon: Icons.notifications,
              title: 'Push Notifications',
              toggle: true,
              toggleValue: pushNotifications,
              onChanged: (value) {
                setState(() {
                  pushNotifications = value;
                });
              },
            ),
            _buildSettingCard(
              icon: Icons.email,
              title: 'Email Notifications',
              toggle: true,
              toggleValue: emailNotifications,
              onChanged: (value) {
                setState(() {
                  emailNotifications = value;
                });
              },
            ),
            _buildSettingCard(
              icon: Icons.sms,
              title: 'SMS Notifications',
              toggle: true,
              toggleValue: smsNotifications,
              onChanged: (value) {
                setState(() {
                  smsNotifications = value;
                });
              },
            ),

            _buildSectionHeader('Preferences'),
            _buildSettingCard(
              icon: Icons.language,
              title: 'Language',
              value: 'English',
              onTap: () {},
            ),
            _buildSettingCard(
              icon: theme == 'Light' ? Icons.wb_sunny : Icons.nightlight_round,
              title: 'Theme',
              value: theme,
              onTap: () {
                setState(() {
                  theme = theme == 'Light' ? 'Dark' : 'Light';
                });
              },
            ),

            _buildSectionHeader('Help & Support'),
            _buildSettingCard(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            _buildSettingCard(
              icon: Icons.description,
              title: 'Terms & Privacy',
              onTap: () {},
            ),

            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Color(0xFF060644),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16,
                  color: Colors.white,
                  )
                ),
              ),
            ),

            SizedBox(height: 20),
            _buildLogoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? value,
    bool? toggle,
    bool? toggleValue,
    Function()? onTap,
    Function(bool)? onChanged,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(title),
        trailing: toggle != null
            ? Switch(
          value: toggleValue ?? false,
          onChanged: onChanged,
        )
            : value != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: Colors.grey)),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      color: Colors.red[50],
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(Icons.logout, color: Colors.red),
        title: Text('Logout', style: TextStyle(color: Colors.red)),
        onTap: () {},
      ),
    );
  }
}
