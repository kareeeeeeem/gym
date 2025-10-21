import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

// =========================================================================
// 1. CORE WIDGETS AND DEFINITIONS (All Code/Comments are in English)
// =========================================================================

// -------------------------------------------------------------------------
// 1.1 Color Definitions
// -------------------------------------------------------------------------
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); 
  static const Color primaryColor = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFF00C4CC); 
  static const Color cardBackgroundColor = Color(0xFF222222); 
  static const Color lightGrayColor = Color(0xFF333333); 
  static const Color redColor = Color(0xFFEA4E79); 
  
  static const List<Color> primaryG = [
    Color(0xFF92A3FD), 
    Color(0xFF9DCEFF), 
  ];
  
  static const List<Color> secondaryG = [
    Color(0xFFC58BF2), 
    Color(0xFFEEA4CE),
  ];
}

// -------------------------------------------------------------------------
// 1.2 Placeholder Page (Base structure for all settings screens)
// -------------------------------------------------------------------------

class PlaceholderPage extends StatelessWidget {
  // Title is now an English UI string
  final String title; 
  final Widget content;
  const PlaceholderPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor, 
      appBar: AppBar(
        // The title displayed on the screen (English)
        title: Text(title, style: const TextStyle(color: AppColors.whiteColor)), 
        backgroundColor: AppColors.blackColor, 
        iconTheme: const IconThemeData(color: AppColors.whiteColor), 
        elevation: 0,
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(25),
        child: content,
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 1.3 Round Button 
// -------------------------------------------------------------------------

enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  // Title is now an English UI string
  final String title; 
  final RoundButtonType type;
  final VoidCallback? onPressed;
  final double height;
  final double width;

  const RoundButton({
    super.key,
    required this.title,
    required this.type,
    required this.onPressed,
    this.height = 50, 
    this.width = double.maxFinite
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: type == RoundButtonType.primaryBG ? AppColors.primaryG : AppColors.secondaryG,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(999), 
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.4), 
                blurRadius: 10, 
                offset: const Offset(0, 4))
          ]),
      child: MaterialButton(
        minWidth: double.maxFinite,
        height: height,
        onPressed: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textColor: AppColors.whiteColor,
        child: Text(
          title, // The button title (English)
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.whiteColor,
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 1.4 Setting Row
// -------------------------------------------------------------------------

class SettingRow extends StatelessWidget {
  final IconData iconData; 
  // Title is now an English UI string
  final String title; 
  final VoidCallback? onPressed;
  final Widget? trailing; 

  const SettingRow({Key? key, required this.iconData, required this.title, required this.onPressed, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData, 
              size: 20, 
              color: AppColors.primaryColor
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title, // The row title (English)
                style: const TextStyle(
                  color: AppColors.whiteColor, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.darkGrayColor), 
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 1.5 Link Launching Function (Handles Web, Email, and WhatsApp links)
// -------------------------------------------------------------------------

void showLinkAction(BuildContext context, String linkType, String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Check for WhatsApp links
      if (url.contains('wa.me') || url.contains('whatsapp')) {
         if (await canLaunchUrl(uri)) {
             await launchUrl(uri, mode: LaunchMode.externalApplication);
         } else {
             // Fallback attempt for WhatsApp using a different URL scheme
             final phoneNumber = url.split('/').last.split('?').first;
             final fallbackUri = Uri.parse("whatsapp://send?phone=$phoneNumber");
             if (await canLaunchUrl(fallbackUri)) {
                  await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
             } else {
                 if (context.mounted) {
                     // English Snackbar message
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Failed to open WhatsApp. Ensure the app is installed.')));
                 }
             }
         }
      } 
      // Standard links (web or email)
      else if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } 
      // Failed to launch
      else {
         if (context.mounted) {
             // English Snackbar message
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to open $linkType link.')));
         }
      }
    } catch (e) {
       if (context.mounted) {
           // English Snackbar message
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ An unexpected error occurred while opening the link.')));
       }
    }
}


// =========================================================================
// 2. VIEW PAGES (Screens)
// =========================================================================


// -------------------------------------------------------------------------
// 2.1 Notification Settings View 
// -------------------------------------------------------------------------

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool _isWorkoutNotificationsEnabled = true;
  bool _isDietTipsEnabled = false;
  bool _isGoalRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Notifications Screen Title (English)
    return PlaceholderPage(
      title: "Notifications", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manage your notification preferences: (English)
          const Text(
            "Manage your notification preferences:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),

          // Workout Reminders Row (English)
          SettingRow(
            iconData: Icons.fitness_center,
            title: "Workout Reminders", 
            onPressed: () {
              setState(() {
                _isWorkoutNotificationsEnabled = !_isWorkoutNotificationsEnabled;
              });
            },
            trailing: Switch(
              value: _isWorkoutNotificationsEnabled,
              onChanged: (val) {
                setState(() {
                  _isWorkoutNotificationsEnabled = val;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
          
          // Diet & Nutrition Tips Row (English)
          SettingRow(
            iconData: Icons.fastfood,
            title: "Diet & Nutrition Tips", 
            onPressed: () {
              setState(() {
                _isDietTipsEnabled = !_isDietTipsEnabled;
              });
            },
            trailing: Switch(
              value: _isDietTipsEnabled,
              onChanged: (val) {
                setState(() {
                  _isDietTipsEnabled = val;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ),

          // Goal Reminders Row (English)
          SettingRow(
            iconData: Icons.flag,
            title: "Goal Reminders", 
            onPressed: () {
              setState(() {
                _isGoalRemindersEnabled = !_isGoalRemindersEnabled;
              });
            },
            trailing: Switch(
              value: _isGoalRemindersEnabled,
              onChanged: (val) {
                setState(() {
                  _isGoalRemindersEnabled = val;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 2.2 Account Management View 
// -------------------------------------------------------------------------

class AccountManagementView extends StatelessWidget {
  final VoidCallback? onLogout;

  const AccountManagementView({super.key, this.onLogout});
  
  void _handleLogout(BuildContext context) {
    if (onLogout != null) {
      onLogout!();
    } else {
       // English Snackbar message: Placeholder Logout function.
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logout function (Placeholder)."))); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Account Management Screen Title (English)
    return PlaceholderPage(
      title: "Account Management", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account preferences and security actions: (English)
          const Text(
            "Account preferences and security actions:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),

          // Edit Personal Data Row (English)
          SettingRow(
            iconData: Icons.edit,
            title: "Edit Personal Data", 
            onPressed: () {
              // English Snackbar message: Navigate to personal data editor.
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Navigate to personal data editor.")));
            }, 
          ),
          
          // Change Password Row (English)
          SettingRow(
            iconData: Icons.vpn_key,
            title: "Change Password", 
            onPressed: () {
              // English Snackbar message: Navigate to change password page.
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Navigate to change password page.")));
            }, 
          ),

          const SizedBox(height: 40),
          
          // Logout Button (English)
          RoundButton(
            title: "Logout", 
            type: RoundButtonType.secondaryBG,
            onPressed: () => _handleLogout(context), 
          ),
        ],
      )
    );
  }
}

// -------------------------------------------------------------------------
// 2.3 Language Selection View 
// -------------------------------------------------------------------------

class LanguageSelectionView extends StatefulWidget {
  const LanguageSelectionView({super.key});

  @override
  State<LanguageSelectionView> createState() => _LanguageSelectionViewState();
}

class _LanguageSelectionViewState extends State<LanguageSelectionView> {
  // Use English UI strings for all language options
  String? _selectedLanguage = 'English';
  
  // All languages are now in English strings
  final List<String> availableLanguages = ['Arabic', 'English', 'Spanish', 'French'];

  @override
  Widget build(BuildContext context) {
    // Language & Region Screen Title (English)
    return PlaceholderPage(
      title: "Language & Region", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Choose application interface language: (English)
          const Text(
            "Choose application interface language:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),

          ...availableLanguages.map((language) {
            return SettingRow(
              iconData: Icons.check,
              title: language,
              onPressed: () {
                setState(() {
                  _selectedLanguage = language;
                });
                // English Snackbar message: Language set to $language.
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Language set to $language.")));
              },
              trailing: _selectedLanguage == language 
                  ? const Icon(Icons.radio_button_checked, size: 20, color: AppColors.accentColor)
                  : const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.darkGrayColor),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 2.4 Theme Settings View 
// -------------------------------------------------------------------------

class ThemeSettingsView extends StatefulWidget {
  const ThemeSettingsView({super.key});

  @override
  State<ThemeSettingsView> createState() => _ThemeSettingsViewState();
}

class _ThemeSettingsViewState extends State<ThemeSettingsView> {
  bool _isDarkModeEnabled = true; 
  
  @override
  Widget build(BuildContext context) {
    // Theme Screen Title (English)
    return PlaceholderPage(
      title: "Theme", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change application theme: (English)
          const Text(
            "Change application theme:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),

          // Dark Mode Toggle Row (English)
          SettingRow(
            iconData: Icons.dark_mode,
            title: "Dark Mode", 
            onPressed: () {
              setState(() {
                _isDarkModeEnabled = !_isDarkModeEnabled;
              });
            },
            trailing: Switch(
              value: _isDarkModeEnabled,
              onChanged: (val) {
                setState(() {
                  _isDarkModeEnabled = val;
                });
                 // English Snackbar message: Dark Mode: $val
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dark Mode: $val")));
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 2.5 Terms of Service View 
// -------------------------------------------------------------------------

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  static const String _termsUrl = 'https://www.egogym.com/terms';

  @override
  Widget build(BuildContext context) {
    // Terms of Service Screen Title (English)
    return PlaceholderPage(
      title: "Terms of Service", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Please read and agree to the terms: (English)
          const Text(
            "Please read and agree to the terms:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),
          
          // Your use of Ego Gym means accepting all terms. Click below to view the full terms. (English)
          const Text(
            "Your use of the Ego Gym app means accepting all terms and conditions. Click the button below to view the full terms in your browser.", 
            style: TextStyle(fontSize: 14, color: AppColors.darkGrayColor)
          ),
          const SizedBox(height: 30),

          // View Full Terms Button (English)
          RoundButton(
            title: "View Full Terms (Open Link)", 
            type: RoundButtonType.primaryBG,
            onPressed: () => showLinkAction(context, "Terms of Service", _termsUrl),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 2.6 Privacy Policy View 
// -------------------------------------------------------------------------

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const String _privacyUrl = 'https://www.egogym.com/privacy';

  @override
  Widget build(BuildContext context) {
    // Privacy Policy Screen Title (English)
    return PlaceholderPage(
      title: "Privacy Policy", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Protecting your data is our priority: (English)
          const Text(
            "Protecting your data is our priority:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),
          
          // The privacy policy explains how we collect and protect your data. (English)
          const Text(
            "The Privacy Policy explains how we collect, use, and protect your personal data. Please review the full policy via the link below.", 
            style: TextStyle(fontSize: 14, color: AppColors.darkGrayColor)
          ),
          const SizedBox(height: 30),

          // View Privacy Policy Button (English)
          RoundButton(
            title: "View Privacy Policy (Open Link)", 
            type: RoundButtonType.primaryBG,
            onPressed: () => showLinkAction(context, "Privacy Policy", _privacyUrl),
          ),
        ],
      ),
    );
  }
}


// -------------------------------------------------------------------------
// 2.7 Help Center View (Includes direct WhatsApp contact)
// -------------------------------------------------------------------------

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

  // IMPORTANT: Replace this with the actual customer service number (country code + number, without '+')
  static const String _whatsappNumber = '201001234567'; // Example: Egyptian number
  static const String _helpUrl = 'https://www.egogym.com/help';
  static const String _supportEmail = 'mailto:support@egogym.com';
  
  // Direct WhatsApp link including a pre-filled message (message content remains English)
  static final String _whatsappUrl = 'https://wa.me/$_whatsappNumber?text=Hello!%20I%20need%20assistance%20regarding%20the%20Ego%20Gym%20app.';

  @override
  Widget build(BuildContext context) {
    // Help Center Screen Title (English)
    return PlaceholderPage(
      title: "Help Center", 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find answers to your FAQs or contact us: (English)
          const Text(
            "Find answers to your FAQs or contact us:", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),
          
          // Direct WhatsApp Contact Row (English)
          SettingRow(
            iconData: Icons.chat,
            title: "Contact via WhatsApp", 
            onPressed: () => showLinkAction(context, "WhatsApp", _whatsappUrl),
            trailing: const Icon(Icons.send, size: 18, color: AppColors.accentColor),
          ),
          
          // FAQ Row (English)
          // 
          // Contact via Email Row (English)
          SettingRow(
            iconData: Icons.mail_outline,
            title: "Contact via Email", 
            onPressed: () => showLinkAction(context, "Support Email", _supportEmail),
          ),

          const SizedBox(height: 30),
          
          // Customer service is available to help you. (English)
          const Text(
            "Customer service is available to help you.", 
            style: TextStyle(fontSize: 12, color: AppColors.darkGrayColor)
          ),
        ],
      ),
    );
  }
}
