import 'package:flutter/material.dart';
import 'package:neptun2/API/api_coms.dart';
import 'package:neptun2/language.dart';
import '../Misc/emojirich_text.dart';
import '../colors.dart';
import '../storage.dart';

class PaymentElementWidget extends StatelessWidget{
  final String ID;
  final int ammount;
  final int dueDateMs;
  final String name;
  final bool completed;

  const PaymentElementWidget({super.key, required this.ammount, required this.dueDateMs, required this.name, required this.ID, required this.completed});

  @override
  Widget build(BuildContext context) {
    double fontScale = DataCache.getFontScale();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateMs);
    final isNonTimed = dueDateMs <= 0;
    final isMissed = dueDateMs < nowMs && !isNonTimed && !completed;


    final cardColor = completed ? AppColors.getTheme().currentClassGreen :
    isMissed ? AppColors.getTheme().errorRed :
    Colors.amber.shade600;

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        border: Border.all(
            color: cardColor.withValues(alpha: 0.5),
            width: 1
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getTheme().textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15.0 * fontScale,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              EmojiRichText(
                text: completed ? '✅' : isMissed ? '🙉' : '💰',
                defaultStyle: TextStyle(
                  color: AppColors.getTheme().onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 20.0 * fontScale,
                ),
                emojiStyle: TextStyle(
                    color: AppColors.getTheme().onPrimaryContainer,
                    fontSize: (isMissed ? 26.0 : 20.0) * fontScale,
                    fontFamily: "Noto Color Emoji"
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Text(
                    AppStrings.getStringWithParams(AppStrings.getLanguagePack().paymentPage_MoneyDisplay, [ammount]),
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18.0 * fontScale,
                    ),
                    textAlign: TextAlign.center,
                  )
              ),
              !isNonTimed ? const Expanded(flex: 1, child: SizedBox()) : const SizedBox(),
              !isNonTimed ? Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      dueDate.year.toString(),
                      style: TextStyle(
                        color: AppColors.getTheme().textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0 * fontScale,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${Generic.monthToText(dueDate.month)} ${dueDate.day}',
                      style: TextStyle(
                        color: AppColors.getTheme().textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.0 * fontScale,
                      ),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ) : const SizedBox(),
            ],
          ),
          const SizedBox(height: 5),
          !isNonTimed && !completed ? Text(
            isMissed ? AppStrings.getStringWithParams(AppStrings.getLanguagePack().paymentPage_PaymentMissedTime, [-(Duration(milliseconds: dueDateMs - nowMs).inDays + 1)]) : AppStrings.getStringWithParams(AppStrings.getLanguagePack().paymentPage_PaymentDeadlineTime, [Duration(milliseconds: dueDateMs - nowMs).inDays + 1]),
            style: TextStyle(
              color: isMissed ? AppColors.getTheme().errorRed.withValues(alpha: 0.8) : AppColors.getTheme().textColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 12.0 * fontScale,
            ),
            textAlign: TextAlign.center,
          ) : const SizedBox(),
        ],
      ),
    );
  }
}