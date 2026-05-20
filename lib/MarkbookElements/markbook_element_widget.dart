import 'package:flutter/material.dart';
import 'package:neptun2/Misc/popup.dart';
import '../Misc/emojirich_text.dart';
import '../colors.dart';
import '../storage.dart'; // ÚJ: Betűméret lekéréséhez

typedef Callback = void Function(int, int);

class MarkbookElementWidget extends StatelessWidget{
  final String name;
  final int credit;
  final bool completed;
  final int grade;
  final bool isFailed;
  final Callback onPopupResult;
  final int listIndex;
  final int ghostGrade;

  const MarkbookElementWidget({super.key, required this.name, required this.credit, required this.completed, required this.grade, required this.isFailed, required this.onPopupResult, required this.listIndex, required this.ghostGrade});

  Color getGradeColor(){
    if(ghostGrade != -1){
      return AppColors.getTheme().textColor.withValues(alpha: .4);
    }
    switch (grade){
      case 5: return AppColors.getTheme().grade5;
      case 4: return AppColors.getTheme().grade4;
      case 3: return AppColors.getTheme().grade3;
      case 2: return AppColors.getTheme().grade2;
      case 1: return AppColors.getTheme().grade1;
      default: return AppColors.getTheme().textColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontScale = DataCache.getFontScale(); // ÚJ: Betűméret szorzó

    // Határozzuk meg a kártya alapszínét
    Color cardColor = (completed || ghostGrade != -1) ? getGradeColor() :
    (!completed && isFailed || grade == 1) ? AppColors.getTheme().errorRed :
    AppColors.getTheme().textColor;

    return GestureDetector(
        onTap: grade >= 2 || credit == 0 ? null : () {
          PopupWidgetHandler(mode: 0, callback: (r){
            onPopupResult(r as int, listIndex);
          });
          PopupWidgetHandler.doPopup(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.05), // Halvány háttér a jegy színe alapján
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                  color: cardColor.withValues(alpha: 0.3),
                  width: 1
              )
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Bal oldali rész: Kreditérték
              EmojiRichText(
                text: "$credit🎖️",
                defaultStyle: TextStyle(
                  color: AppColors.getTheme().onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 26.0 * fontScale, // Skálázott
                ),
                emojiStyle: TextStyle(
                    color: AppColors.getTheme().onPrimaryContainer,
                    fontSize: 19.0 * fontScale, // Skálázott
                    fontFamily: "Noto Color Emoji"
                ),
              ),

              // Középső rész: Tantárgy neve
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                  child: Text.rich(
                    TextSpan(
                      text: name,
                      style: TextStyle(
                          fontSize: 14.0 * fontScale, // Skálázott
                          decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                          fontWeight: completed ? FontWeight.w400 : FontWeight.w600,
                          color: AppColors.getTheme().textColor,
                          decorationColor: AppColors.getTheme().textColor
                      ),
                    ),
                  ),
                ),
              ),

              // Jobb oldali rész: Érdemjegy vagy bukás ikon
              Visibility(
                  visible: (!completed && isFailed || grade == 1) && ghostGrade == -1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: AppColors.getTheme().errorRed,
                        size: 30.0 * fontScale,
                      )
                    ],
                  )
              ),
              Visibility(
                visible: completed || ghostGrade != -1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    grade < 2 && ghostGrade == -1 || credit == 0 ?
                    Icon(
                      Icons.check_rounded,
                      color: AppColors.getTheme().grade5,
                      size: 30.0 * fontScale,
                    ) : Text(
                      ghostGrade == -1 ? '$grade' : '$ghostGrade',
                      style: TextStyle(
                          color: getGradeColor(),
                          fontSize: 26.0 * fontScale, // Skálázott, kicsit nagyobb lett
                          fontWeight: FontWeight.bold,
                          fontFamily: "Noto Sans"
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}