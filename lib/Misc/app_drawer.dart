import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Pages/main_page.dart';
import '../colors.dart';
import '../haptics.dart';
import '../storage.dart' as storage;
import '../Pages/startup_page.dart' as root_page;
import '../Misc/emojirich_text.dart';
import '../language.dart';
import '../notifications.dart';
import '../Pages/settings_page.dart';

class AppDrawer extends StatelessWidget {
  final String loggedInUsername;
  final String loggedInURL;

  const AppDrawer({super.key, required this.loggedInUsername, required this.loggedInURL});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.getTheme().rootBackground,
      child: SafeArea( // this solves navbar overlap!
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- header (welcome) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.getTheme().textColor.withValues(alpha: 0.05),
                  border: Border(bottom: BorderSide(color: AppColors.getTheme().textColor.withValues(alpha: 0.1), width: 1))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.getTheme().currentClassGreen,
                    radius: 30,
                    child: Text(
                      loggedInUsername.isNotEmpty ? loggedInUsername[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.getTheme().rootBackground, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  EmojiRichText(
                    text: AppStrings.getStringWithParams(AppStrings.getLanguagePack().topmenu_Greet, [loggedInUsername]),
                    defaultStyle: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    emojiStyle: TextStyle(color: AppColors.getTheme().textColor, fontSize: 20, fontFamily: "Noto Color Emoji"),
                  ),
                  const SizedBox(height: 5),
                  EmojiRichText(
                    text: AppStrings.getStringWithParams(AppStrings.getLanguagePack().topmenu_LoginPlace, [loggedInURL]),
                    defaultStyle: TextStyle(color: AppColors.getTheme().textColor.withValues(alpha: 0.7), fontSize: 13),
                    emojiStyle: TextStyle(color: AppColors.getTheme().textColor.withValues(alpha: 0.7), fontSize: 13, fontFamily: "Noto Color Emoji"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- menus ---
            ListTile(
              leading: Icon(Icons.settings_rounded, color: AppColors.getTheme().textColor),
              title: Text(AppStrings.getLanguagePack().topmenu_buttons_Settings, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.pop(context); // closes drawer

                // open new page >> old popup dart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ).then((_) {
                  // check if calendar needs to refresh if closing menu
                  HomePageState.settingsUserWeekOffsetChangeDetect();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
              title: Text(AppStrings.getLanguagePack().topmenu_buttons_SupportDev, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.pop(context);
                if(Platform.isAndroid){
                  launchUrl(Uri.parse('https://buymeacoffee.com/zoligamer')).whenComplete(() {
                    Fluttertoast.showToast(msg: '❤️', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.SNACKBAR, backgroundColor: AppColors.getTheme().rootBackground, textColor: AppColors.getTheme().textColor);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report_rounded, color: AppColors.getTheme().textColor),
              title: Text(AppStrings.getLanguagePack().topmenu_buttons_Bugreport, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.pop(context);
                if(Platform.isAndroid){
                  launchUrl(Uri.parse('https://github.com/zoligamer/Neptun-Mobile-fork/issues/new/choose'));
                }
              },
            ),

            // --- bottom (logout) ---
            const Spacer(), // push logout to the screen bottom
            Divider(color: AppColors.getTheme().textColor.withValues(alpha: 0.1)),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.getTheme().errorRed),
              title: Text(AppStrings.getLanguagePack().topmenu_buttons_Logout, style: TextStyle(color: AppColors.getTheme().errorRed, fontWeight: FontWeight.w700)),
              onTap: () {
                AppHaptics.lightImpact();
                Future.delayed(Duration.zero, ()async{
                  await storage.DataCache.dataWipe();
                  await AppNotifications.cancelScheduledNotifs();
                }).whenComplete((){
                  Navigator.popUntil(context, (route) => route.willHandlePopInternally);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const root_page.Splitter()));
                });
                if(Platform.isAndroid){
                  Fluttertoast.showToast(msg: AppStrings.getLanguagePack().topmenu_buttons_LogoutSuccessToast, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.SNACKBAR, backgroundColor: AppColors.getTheme().rootBackground, textColor: AppColors.getTheme().textColor);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}