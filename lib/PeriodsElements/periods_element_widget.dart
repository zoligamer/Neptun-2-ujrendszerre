import 'package:flutter/material.dart';
import 'package:neptun2/Misc/emojirich_text.dart';
import 'package:neptun2/language.dart';
import '../API/api_coms.dart';
import '../colors.dart';
import '../storage.dart'; // ÚJ: Betűméret lekéréséhez

class PeriodsElementWidget extends StatelessWidget{
  final String displayName;
  final String formattedStartTime;
  final String formattedStartTimeYear;
  final String formattedEndTime;
  final String formattedEndTimeYear;
  final bool isActive;
  final PeriodType periodType;
  final int endTime;
  final int startTime;
  final bool expired;

  const PeriodsElementWidget({super.key, required this.displayName, required this.formattedStartTime, required this.formattedEndTime, required this.formattedEndTimeYear, required this.formattedStartTimeYear, required this.isActive, required this.periodType, required this.startTime, required this.endTime, required this.expired});

  EmojiRichText? getIconFromType(PeriodType periodType, double fontScale){
    String emoji = '❓';
    switch (periodType) {
      case PeriodType.timetableRegistration: emoji = '📄'; break;
      case PeriodType.gradingTime: emoji = '⭐'; break;
      case PeriodType.loginTime: emoji = '🪪'; break;
      case PeriodType.pregivenGradingAccepting: emoji = '📑'; break;
      case PeriodType.timetableFinalization: emoji = '📝'; break;
      case PeriodType.coursesRegistration: emoji = '📚'; break;
      case PeriodType.nerdTime: emoji = '🤓'; break;
      case PeriodType.examTime: emoji = '🎓'; break;
      case PeriodType.signinTime: emoji = '🖋️'; break;
      default: emoji = '❓'; break;
    }
    return EmojiRichText(
      text: emoji,
      defaultStyle: TextStyle(
        color: AppColors.getTheme().onPrimaryContainer,
        fontWeight: FontWeight.w900,
        fontSize: 22.0 * fontScale, // Skálázott
      ),
      emojiStyle: TextStyle(
          color: AppColors.getTheme().onPrimaryContainer,
          fontSize: 22.0 * fontScale, // Skálázott
          fontFamily: "Noto Color Emoji"
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontScale = DataCache.getFontScale(); // ÚJ: Betűméret szorzó

    final currVal = Duration(milliseconds: endTime - DateTime.now().millisecondsSinceEpoch).inDays + 0.0;
    final maxVal = Duration(milliseconds: endTime-startTime).inDays + 0.0;
    final now = DateTime.now().millisecondsSinceEpoch;

    final cardColor = expired ? AppColors.getTheme().errorRed :
    isActive ? AppColors.getTheme().currentClassGreen :
    AppColors.getTheme().textColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
            color: cardColor.withValues(alpha: 0.3),
            width: 1
        ),
        // Megtartottuk a menő folyamatjelződet, csak az új opacity rendszerrel!
        gradient: isActive ? LinearGradient(
            colors: [
              AppColors.getTheme().currentClassGreen.withValues(alpha: 0.15),
              cardColor.withValues(alpha: 0.02)
            ],
            stops: [1 - (currVal / maxVal), 1 - (currVal / maxVal)]
        ) : null,
        color: !isActive ? cardColor.withValues(alpha: 0.03) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            displayName,
            style: TextStyle(
              color: expired ? AppColors.getTheme().errorRed : AppColors.getTheme().textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15.0 * fontScale, // Skálázott
            ),
          ),
          const SizedBox(height: 10),
          isActive ? Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              getIconFromType(periodType, fontScale) ?? const SizedBox(),
              const SizedBox(width: 5),
              Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        formattedStartTimeYear,
                        style: TextStyle(
                          color: AppColors.getTheme().textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0 * fontScale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        formattedStartTime,
                        style: TextStyle(
                          color: AppColors.getTheme().onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0 * fontScale,
                        ),
                        textAlign: TextAlign.center,
                      )
                    ],
                  )
              ),
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      formattedEndTimeYear,
                      style: TextStyle(
                        color: AppColors.getTheme().textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0 * fontScale,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      formattedEndTime,
                      style: TextStyle(
                        color: AppColors.getTheme().onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.0 * fontScale,
                      ),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ],
          ) :
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              getIconFromType(periodType, fontScale) ?? const SizedBox(),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Text(
                        expired ? AppStrings.getLanguagePack().periodPage_Expired : AppStrings.getLanguagePack().periodPage_Starts,
                        style: TextStyle(
                          color: expired ? AppColors.getTheme().errorRed : AppColors.getTheme().textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0 * fontScale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        expired ? '$formattedEndTimeYear $formattedEndTime' : '$formattedStartTimeYear $formattedStartTime',
                        style: TextStyle(
                          color: expired ? AppColors.getTheme().errorRed : AppColors.getTheme().textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0 * fontScale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            expired ? AppStrings.getStringWithParams(AppStrings.getLanguagePack().periodPage_ExpiredDays, [-(Duration(milliseconds: endTime - now).inDays + 1) * (Duration(milliseconds: endTime - now).inDays == 0 ? -1 : 1)]) : !isActive ? AppStrings.getStringWithParams(AppStrings.getLanguagePack().periodPage_StartDays, [Duration(milliseconds: startTime - now).inDays + 1]) : AppStrings.getStringWithParams(AppStrings.getLanguagePack().periodPage_ActiveDays, [Duration(milliseconds: endTime - now).inDays + 1]),
            style: TextStyle(
              color: AppColors.getTheme().textColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 12.0 * fontScale,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}