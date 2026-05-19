import 'dart:io';
import 'package:flutter/material.dart';
import 'package:neptun2/Pages/main_page.dart';
import '../API/api_coms.dart';
import '../colors.dart';
import '../haptics.dart';
import '../language.dart';
import '../storage.dart';
import '../Misc/emojirich_text.dart';
import '../Pages/startup_page.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _languageCurrSelect;
  late String _themesCurrSelect;
  late double _currentFontScale;

  @override
  void initState() {
    super.initState();

    // loading defaults
    _currentFontScale = DataCache.getFontScale();
    _themesCurrSelect = AppColors.getTheme().paletteName;

    final lIdx = DataCache.getUserSelectedLanguage()!;
    if (lIdx <= -1) {
      final langCodeIdx = AppStrings.getAllLangCodes().indexOf(Platform.localeName.split('_')[0].toLowerCase());
      _languageCurrSelect = AppStrings.getLanguageNamesWithFlag()[langCodeIdx];
    } else {
      _languageCurrSelect = AppStrings.getLanguageNamesWithFlag()[lIdx];
    }
  }

  // header helpers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.getTheme().secondary, size: 20),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
                color: AppColors.getTheme().secondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.2
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getTheme().rootBackground,
      appBar: AppBar(
        backgroundColor: AppColors.getTheme().rootBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.getTheme().textColor),
          onPressed: () {
            AppHaptics.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: EmojiRichText(
          text: AppStrings.getLanguagePack().topmenu_buttons_Settings,
          defaultStyle: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold, fontSize: 20),
          emojiStyle: TextStyle(color: AppColors.getTheme().textColor, fontSize: 20, fontFamily: "Noto Color Emoji"),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // --- 1. appearance and language ---
          _buildSectionHeader("Megjelenés és Nyelv", Icons.palette_rounded),

          ListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption9_ThemeSwap, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            trailing: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: AppColors.getTheme().textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _themesCurrSelect,
                  dropdownColor: AppColors.getTheme().rootBackground,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.getTheme().textColor),
                  isExpanded: true,
                  style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600),
                  items: AppColors.getThemesOnline().map((String value) {
                    return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: AppColors.getThemePopupAccentByName(value), size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
                          ],
                        )
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    AppHaptics.lightImpact();
                    DataCache.setPreferredAppTheme(value);
                    if(!AppColors.hasThemeDownloaded(value)){
                      // download logic from old popup
                      Future.delayed(Duration.zero, ()async{
                        final pack = await Coloring.getAllThemes();
                        await Coloring.getThemePackById(pack, value).then((val)async{
                          if(val != null){
                            AppColors.saveDownloadedPaletteData();
                            AppColors.setUserThemeByName(val.paletteName, context);
                            AppColors.refreshThemeIndexing();
                            setState(() { _themesCurrSelect = value; });
                          }
                        });
                      });
                    } else {
                      setState(() {
                        _themesCurrSelect = value;
                        AppColors.setUserTheme(context);
                        AppColors.refreshThemeIndexing();
                      });
                    }
                  },
                ),
              ),
            ),
          ),

          ListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption8_LangaugeSelection, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            trailing: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: AppColors.getTheme().textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _languageCurrSelect,
                  dropdownColor: AppColors.getTheme().rootBackground,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.getTheme().textColor),
                  isExpanded: true,
                  items: AppStrings.getLanguageNamesWithFlag().map((String value) {
                    return DropdownMenuItem<String>(
                        value: value,
                        child: EmojiRichText(
                          text: value,
                          defaultStyle: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600, fontSize: 14),
                          emojiStyle: TextStyle(color: AppColors.getTheme().textColor, fontSize: 18, fontFamily: "Noto Color Emoji"),
                        )
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    AppHaptics.lightImpact();
                    // language logic from old popup
                    final flagWeLookFor = value.split(' ')[0];
                    final languageIdx = AppStrings.getAllLangFlags().indexOf(flagWeLookFor);
                    DataCache.setUserSelectedLanguage(languageIdx <= -1 ? AppStrings.getAllLangFlags().length : languageIdx);

                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Splitter()));
                  },
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("App Betűméret skálázás", style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                Slider(
                  value: _currentFontScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label: "${(_currentFontScale * 100).toInt()}%",
                  activeColor: AppColors.getTheme().secondary,
                  inactiveColor: AppColors.getTheme().textColor.withValues(alpha: 0.1),
                  onChanged: (val) {
                    setState(() { _currentFontScale = val; });
                  },
                  onChangeEnd: (val) {
                    AppHaptics.lightImpact();
                    DataCache.setFontScale(val);
                    // ui update!
                    setState((){});
                  },
                ),
              ],
            ),
          ),

          // --- 2. notifications ---
          _buildSectionHeader("Értesítések", Icons.notifications_active_rounded),

          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption2_ExamNotifications, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedExamNotifications()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedExamNotifications(b ? 1 : 0);
              b ? HomePageState.setupExamNotifications() : HomePageState.cancelExamNotifications();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption3_ClassNotifications, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedClassNotifications()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedClassNotifications(b ? 1 : 0);
              b ? HomePageState.setupClassesNotifications() : HomePageState.cancelClassesNotifications();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption4_PaymentNotifications, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedPaymentsNotifications()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedPaymentsNotifications(b ? 1 : 0);
              b ? HomePageState.setupPaymentsNotifications() : HomePageState.cancelPaymentsNotifications();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption5_PeriodsNotifications, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedPeriodsNotifications()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedPeriodsNotifications(b ? 1 : 0);
              b ? HomePageState.setupPeriodsNotifications() : HomePageState.cancelPeriodsNotifications();
              setState(() {});
            },
          ),

          // --- 3. operation and others ---
          _buildSectionHeader("Működés és Egyéb", Icons.build_circle_rounded),

          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption1_FamilyFriendlyLoadingText, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedFamilyFriendlyComments()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedFamilyFriendlyComments(b ? 1 : 0);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption6_AppHaptics, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            activeThumbColor: AppColors.getTheme().secondary,
            value: DataCache.getNeedsHaptics()!,
            onChanged: (b) {
              AppHaptics.lightImpact();
              DataCache.setNeedsHaptics(b ? 1 : 0);
              setState(() {});
            },
          ),

          ListTile(
            title: Text(AppStrings.getLanguagePack().popup_case1_settingOption7_WeekOffset, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.w600)),
            trailing: Container(
              width: 120,
              decoration: BoxDecoration(color: AppColors.getTheme().textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: AppColors.getTheme().textColor, size: 18),
                    onPressed: () { AppHaptics.lightImpact(); HomePageState.settingsUserWeekOffsetAdd(-1); setState((){}); },
                  ),
                  Expanded(
                    child: Text(HomePageState.getUserWeekOffsetTextController().text.isEmpty ? "Auto" : HomePageState.getUserWeekOffsetTextController().text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.getTheme().textColor, size: 18),
                    onPressed: () { AppHaptics.lightImpact(); HomePageState.settingsUserWeekOffsetAdd(1); setState((){}); },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}