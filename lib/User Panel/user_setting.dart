import 'package:flutter/material.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

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
      backgroundColor: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        backgroundColor: UserTheme.primaryColor, // Matches #060644 (Primary)
        title: Text(
          'Settings',
          style: TextStyle(
            color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            ),
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
                  backgroundColor: UserTheme.primaryColor, // Matches #060644 (Primary)
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                  ),
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
          color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
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
      color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
        ),
        title: Text(
          title,
          style: TextStyle(
            color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
          ),
        ),
        trailing: toggle != null
            ? Switch(
          value: toggleValue ?? false,
          onChanged: onChanged,
          activeColor: UserTheme.primaryColor, // Matches #060644 (Primary)
        )
            : value != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
            ),
          ],
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      color: UserTheme.errorTextColor.withOpacity(0.1), // Light red shade
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: UserTheme.errorTextColor, // Matches #D32F2F (Error Text)
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: UserTheme.errorTextColor, // Matches #D32F2F (Error Text)
          ),
        ),
        onTap: () {},
      ),
    );
  }
}