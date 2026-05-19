import 'package:flutter/material.dart';
import '../Pages/main_page.dart';
import '../colors.dart';
import '../haptics.dart';
import '../Misc/emojirich_text.dart';

class TopNavigatorWidget extends StatelessWidget{
  final HomePageState homePage;
  final String displayString;
  final String smallHintText;

  final String loggedInUsername;
  final String loggedInURL;
  const TopNavigatorWidget({super.key, required this.homePage, required this.displayString, required this.smallHintText, required this.loggedInUsername, required this.loggedInURL});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.getTheme().rootBackground,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
      child: GestureDetector(
        onHorizontalDragStart: (_){
          homePage.bottomNavCanNavigate = true;
          homePage.bottomNavSwitchValue = 0.0;
        },
        onHorizontalDragEnd: (_){
          homePage.bottomNavCanNavigate = false;
          homePage.bottomNavSwitchValue = 0.0;
        },
        onHorizontalDragUpdate: (e){
          if(!homePage.bottomNavCanNavigate){
            return;
          }
          if(homePage.bottomNavSwitchValue < -50){
            homePage.bottomNavCanNavigate = false;
            final val = homePage.currentView + 1 > HomePageState.maxBottomNavWidgets - 1 ? 0 : homePage.currentView + 1;
            homePage.switchView(val);
            AppHaptics.lightImpact();
            return;
          }
          else if(homePage.bottomNavSwitchValue > 50){
            homePage.bottomNavCanNavigate = false;
            final val = homePage.currentView - 1 < 0 ? HomePageState.maxBottomNavWidgets - 1 : homePage.currentView - 1;
            homePage.switchView(val);
            AppHaptics.lightImpact();
            return;
          }
          homePage.bottomNavSwitchValue -= e.delta.dx;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast
          ),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 18, 6),
                  child: IconButton(
                    onPressed: (){
                      AppHaptics.lightImpact();
                      // EZ  MEG AZ ÚJ side menu!
                      Scaffold.of(context).openDrawer();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(AppColors.getTheme().textColor.withValues(alpha: .1)),
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    ),
                    icon: Icon(
                      Icons.menu_rounded,
                      color: AppColors.getTheme().onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 1),
                        child: Text(
                            displayString,
                            style: TextStyle(
                              color: AppColors.getTheme().onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 22.0
                            ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                        child: EmojiRichText(
                          text: smallHintText,
                          defaultStyle: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.getTheme().textColor,
                          ),
                          emojiStyle: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.getTheme().textColor,
                            fontFamily: "Noto Color Emoji"
                          )
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}