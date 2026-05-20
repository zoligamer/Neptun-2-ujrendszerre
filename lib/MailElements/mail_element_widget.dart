import 'dart:core';
import 'package:flutter/material.dart';
import 'package:neptun2/API/api_coms.dart';
import 'package:neptun2/Misc/popup.dart';
// import 'package:neptun2/language.dart';

import '../Misc/emojirich_text.dart';
import '../colors.dart';
import '../storage.dart'; // ÚJ: Betűméret lekéréséhez

class MailPopupDisplayTexts{
  static String title = "";
  static List<InlineSpan> description = [];
  static String mailID = "";
}

class MailElementWidget extends StatelessWidget{
  final String subject;
  final String details;
  final String sender;
  final int sendTime;
  final bool isRead;
  final String mailID;
  final Function(MailElementWidget) callback;

  const MailElementWidget({super.key, required this.subject, required this.details, required this.sender, required this.sendTime, required this.isRead, required this.mailID, required this.callback});

  @override
  Widget build(BuildContext context) {
    double fontScale = DataCache.getFontScale(); // ÚJ: Betűméret szorzó

    final pattern = RegExp(r'<a[^>]*>(.*?)</a>');
    List<String> parts = details.split(pattern);

    // Kártya színe (Olvasatlan = Kiemelt / Olvasott = Halvány)
    final cardColor = !isRead ? AppColors.getTheme().secondary : AppColors.getTheme().textColor;

    return GestureDetector(
      onTap: (){
        MailPopupDisplayTexts.title = subject;
        MailPopupDisplayTexts.description = Generic.textToInlineSpan(details);
        MailPopupDisplayTexts.mailID = mailID;

        PopupWidgetHandler(mode: 3, callback: (_){}, onCloseCallback: (){
          callback(this);
        });
        PopupWidgetHandler.doPopup(context);
      },
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              color: cardColor.withValues(alpha: !isRead ? 0.1 : 0.03), // Olvasatlan sötétebb háttérrel
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(
                  color: cardColor.withValues(alpha: !isRead ? 0.5 : 0.2), // Olvasatlan erősebb kerettel
                  width: !isRead ? 1.5 : 1.0 // Olvasatlan vastagabb kerettel
              )
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              EmojiRichText(
                text: isRead ? '📭' : '📬',
                defaultStyle: TextStyle(
                  color: AppColors.getTheme().onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 24.0 * fontScale, // Skálázott
                ),
                emojiStyle: TextStyle(
                    color: AppColors.getTheme().onPrimaryContainer,
                    fontSize: 24.0 * fontScale, // Skálázott
                    fontFamily: "Noto Color Emoji"
                ),
              ),
              const SizedBox(width: 15), // Pici távolságtartás a logótól
              Expanded(
                flex: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        color: AppColors.getTheme().onPrimaryContainer,
                        fontWeight: !isRead ? FontWeight.w800 : FontWeight.w600,
                        fontSize: (isRead ? 15.0 : 16.0) * fontScale, // Skálázott
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: AppColors.getTheme().textColor.withValues(alpha: 0.8),
                          size: 16 * fontScale,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sender,
                            style: TextStyle(
                              color: AppColors.getTheme().textColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0 * fontScale, // Skálázott
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(parts.join().toString()).replaceAll('\n', ' ').replaceAll('\t', ' ')}...',
                      style: TextStyle(
                        color: AppColors.getTheme().textColor.withValues(alpha: 0.6), // Halványabb előnézet
                        fontWeight: FontWeight.w500,
                        fontSize: 12.0 * fontScale, // Skálázott
                      ),
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2, // Engedünk 2 sort az előnézetnek
                    ),
                  ],
                ),
              )
            ],
          )
      ),
    );
  }
}