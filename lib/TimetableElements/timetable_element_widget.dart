import '../storage.dart' as storage;
import 'package:flutter/material.dart';
import 'package:neptun2/language.dart';
import '../API/api_coms.dart' as api;
import '../Misc/emojirich_text.dart';
import '../Misc/popup.dart';
import '../Pages/main_page.dart';
import '../colors.dart';

typedef Callback = Future<void> Function();

class TimetableCurrentlySelected{
  static api.CalendarEntry? entry;
}

class TimetableElementWidget extends StatelessWidget {

  late final String title;
  late final String location;
  late final String displayStartTime;
  late final String displayEndTime;
  late final bool isExam;
  final bool isCurrent;

  late final DateTime endDateNormalized;

  late final bool currentOverride;

  late final bool isTask;

  TimetableElementWidget(
      {super.key, required this.entry, required this.position, required this.isCurrent}) {
    isExam = entry.isExam;
    isTask = entry.isTask;
    title = entry.title;
    location = entry.location;

    // start date
    var startDate = DateTime.fromMillisecondsSinceEpoch(entry.startEpoch);
    var startHour = startDate.hour.toString().padLeft(2, '0');
    var startMinute = startDate.minute.toString().padLeft(2, '0');
    displayStartTime = "$startHour:$startMinute";

    // actual end date calc, not mathing
    var endDate = DateTime.fromMillisecondsSinceEpoch(entry.endEpoch);
    var endHour = endDate.hour.toString().padLeft(2, '0');
    var endMinute = endDate.minute.toString().padLeft(2, '0');
    displayEndTime = "$endHour:$endMinute";

    // --- 3. actual enddate
    endDateNormalized = endDate;

    // --- 4. active status ---
    if (endDateNormalized.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
      currentOverride = false;
    } else {
      currentOverride = isCurrent;
    }
  }

  final api.CalendarEntry entry;
  final int position;

  @override
  Widget build(BuildContext context) {
  // --- font upscale ---
  //double fontScale = storage.DataCache.getFontScale()/* ?? 1.0*/;
  double fontScale = 1.15;

  return GestureDetector(
    onTap: () {
      if (isExam) {
        TimetableCurrentlySelected.entry = entry;
        PopupWidgetHandler(mode: 5, callback: (_) {});
        PopupWidgetHandler.doPopup(context);
        return;
      }
      if (isTask && entry.taskId != null && entry.taskId!.isNotEmpty) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: AppColors.getTheme().rootBackground,
                title: Text(title, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold)),
                content: FutureBuilder<String?>(
                  future: storage.getString('task_type_${entry.taskId}'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                    }

                    return FutureBuilder<String?>(
                        future: storage.getString('task_res_${entry.taskId}'),
                        builder: (context, resSnapshot) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📚 Tárgy: ${entry.location}", style: TextStyle(color: AppColors.getTheme().textColor, fontSize: 16)),
                              const SizedBox(height: 10),
                              Text("📝 Típus: ${snapshot.data ?? 'Ismeretlen'}", style: TextStyle(color: AppColors.getTheme().textColor, fontSize: 16)),
                              const SizedBox(height: 10),
                              Text("🎯 Eredmény: ${resSnapshot.data ?? 'Nincs még kiírva'}", style: TextStyle(color: AppColors.getTheme().currentClassGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          );
                        }
                    );
                  },
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Bezárás", style: TextStyle(color: AppColors.getTheme().textColor))
                  )
                ],
              );
            }
        );
        return;
      }
      // HA VAN CLASSINSTANCE ID (Modern API), Akkor a mi új ablakunk jön be!
      if (entry.classInstanceId != null && entry.classInstanceId!.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.getTheme().rootBackground,
              title: Text(title, style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold)),
              content: FutureBuilder<Map<String, String>>(
                future: api.CalendarRequest.getCourseDetails(entry.classInstanceId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator())
                    );
                  }
                  if (snapshot.hasData) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📍 Terem: ${snapshot.data!['room']}", style: TextStyle(color: AppColors.getTheme().textColor, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("👨‍🏫 Tanár: ${snapshot.data!['teacher']}", style: TextStyle(color: AppColors.getTheme().textColor, fontSize: 16)),
                      ],
                    );
                  }
                  return Text("Hiba a betöltésnél.", style: TextStyle(color: AppColors.getTheme().textColor));
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Bezárás", style: TextStyle(color: AppColors.getTheme().textColor))
                )
              ],
            );
          }
        );
      } else {

        TimetableCurrentlySelected.entry = entry;
        PopupWidgetHandler(mode: 4, callback: (_) {});
        PopupWidgetHandler.doPopup(context);
      }
    },
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: currentOverride ? 10 : 25),
      padding: isExam || currentOverride ? const EdgeInsets.symmetric(vertical: 20, horizontal: 15) : null,
      decoration: (isExam || isTask) || currentOverride ? BoxDecoration(
        border: Border.all(
          color: isExam ? AppColors.getTheme().errorRed.withValues(alpha: .5) :
                 isTask ? Colors.amber.shade600.withValues(alpha: .5) :
                 AppColors.getTheme().currentClassGreen.withValues(alpha: .5),
          width: .75
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        color: isExam ? AppColors.getTheme().errorRed.withValues(alpha: .05) :
               isTask ? Colors.amber.shade600.withValues(alpha: .05) :
               AppColors.getTheme().currentClassGreen.withValues(alpha: .05)
      ) : const BoxDecoration(
        color: Colors.transparent
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [

            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: (!isExam && !isTask) ? Text(
                "$position.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: currentOverride ? AppColors.getTheme().currentClassGreen : AppColors.getTheme().onPrimaryContainer,
                  fontWeight: FontWeight.w900,

                  fontSize: 26.0 * fontScale,
                ),
                maxLines: 1,
              ) : Icon(
                  Icons.warning_rounded,
                  color: isExam ? AppColors.getTheme().errorRed : Colors.amber.shade600,

                  size: 28.0 * fontScale,
              ),
            ),

            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.getTheme().textColor,
                      // Alap 15.0-ról 16.0-ra
                      fontSize: 16.0 * fontScale,
                      fontWeight: FontWeight.w700
                    )
                  ),
                  const SizedBox(height: 2),
                  Visibility(
                    visible: entry.location.trim().isNotEmpty,
                    child: Text(
                      entry.location == "Nincs megadva" || entry.location.isEmpty || entry.location == "NULL"
                          ? "⏳ Terem betöltése..."
                          : entry.location,
                      style: TextStyle(
                          color: isExam ? AppColors.getTheme().errorRed.withValues(alpha: .8) : AppColors.getTheme().textColor.withValues(alpha: 0.8),
                          fontSize: 13.0 * fontScale,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: currentOverride ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timelapse_rounded,
                    color: AppColors.getTheme().currentClassGreen,
                    size: 20 * fontScale,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${(Duration(milliseconds: endDateNormalized.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch)).inHours.remainder(60).toString().padLeft(2, '0')}:${((Duration(milliseconds: endDateNormalized.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch)).inMinutes.remainder(60)).toString().padLeft(2, '0')}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.getTheme().currentClassGreen,
                        fontWeight: FontWeight.w700,
                        // Alap 14.0-ról 15.0-ra
                        fontSize: 15.0 * fontScale,
                      ),
                    ),
                  ),
                ],
              ) : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayStartTime,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isExam ? AppColors.getTheme().errorRed : AppColors.getTheme().onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: (!isExam ? 15.0 : 17.0) * fontScale,
                    ),
                  ),
                  !isExam ?
                  Text(
                    displayEndTime,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.getTheme().onPrimary.withValues(alpha: .8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0 * fontScale,
                    ),
                  ) : const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      )
    ),
  );
}
}

class FreedayElementWidget extends StatelessWidget{
  const FreedayElementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Center(
            child: EmojiRichText(
              text: AppStrings.getLanguagePack().calendarPage_FreeDay,
              defaultStyle: TextStyle(
                color: AppColors.getTheme().onPrimaryContainer,
                fontWeight: FontWeight.w900,
                fontSize: 34.0,
              ),
              emojiStyle: TextStyle(
                  color: AppColors.getTheme().onPrimaryContainer,
                  fontSize: 34.0,
                  fontFamily: "Noto Color Emoji"
              ),
            ),
        ),
      )
    );
  }
}
class WeekoffseterElementWidget extends StatelessWidget{
  final HomePageState homePage;

  WeekoffseterElementWidget({super.key, required this.week, required this.from, required this.to, required this.onBackPressed, required this.onForwardPressed, required this.canDoPaging, required this.homePage, required this.isLoading}){
    final startMonth = from != null ? api.Generic.monthToText(from!.month) : "_";
    final startDay = from != null ? from!.day : "";

    final endMonth = api.Generic.monthToText(to.month);
    final endDay = to.day;

    displayString = AppStrings.getStringWithParams(AppStrings.getLanguagePack().calendarPage_weekNav_StudyWeek, [week]);

    if(isLoading){
      displayString2 = AppStrings.getLanguagePack().calendarPage_weekNav_ClassesThisWeekLoading;
      return;
    }

    if(startMonth == "_"){
      displayString2 = AppStrings.getLanguagePack().calendarPage_weekNav_ClassesThisWeekEmpty;
      return;
    }
    if("$startMonth $startDay" == "$endMonth $endDay"){
      displayString2 = AppStrings.getStringWithParams(AppStrings.getLanguagePack().calendarPage_weekNav_ClassesThisWeekOneDay, [endMonth, endDay, api.Generic.dayToText(to.weekday)]);
    }
    else{
      displayString2 = AppStrings.getStringWithParams(AppStrings.getLanguagePack().calendarPage_weekNav_ClassesThisWeekFull, [startMonth, startDay, endMonth, endDay]);
    }
  }

  final bool canDoPaging;
  final int week;
  final DateTime? from;
  final DateTime to;

  final Callback onBackPressed;
  final Callback onForwardPressed;

  late final String displayString;
  late final String displayString2;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_){
        homePage.calendarWeekCanNavigate = true;
        homePage.calendarWeekSwitchValue = 0.0;
      },
      onHorizontalDragEnd: (_){
        homePage.calendarWeekCanNavigate = false;
        homePage.calendarWeekSwitchValue = 0.0;
      },
      onHorizontalDragUpdate: (e){
        if(!homePage.calendarWeekCanNavigate || !canDoPaging){
          return;
        }
        if(homePage.calendarWeekSwitchValue < -20 && week < 52){
          if(homePage.weeksSinceStart + 1 > 52){
            homePage.calendarWeekCanNavigate = false;
            homePage.calendarWeekSwitchValue = 0.0;
            return;
          }
          homePage.calendarWeekSwitchValue = -5.0;
          onForwardPressed();
          return;
        }
        else if(homePage.calendarWeekSwitchValue > 20 && week > 1){
          if(homePage.weeksSinceStart - 1 < 1){
            homePage.calendarWeekCanNavigate = false;
            homePage.calendarWeekSwitchValue = 0.0;
            return;
          }
          homePage.calendarWeekSwitchValue = 5.0;
          onBackPressed();
          return;
        }
        homePage.calendarWeekSwitchValue += e.delta.dx;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 2),
        color: Colors.black.withValues(alpha: 0.01),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: AppColors.getTheme().textColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: week <= 1 || !canDoPaging ? null : onBackPressed,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        displayString,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTheme().textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: week >= 52 || !canDoPaging ? null : onForwardPressed,
                        icon: const Icon(Icons.arrow_forward_rounded)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: AppColors.getTheme().textColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
                child: EmojiRichText(
                  text: displayString2,
                  defaultStyle: TextStyle(
                    color: AppColors.getTheme().textColor.withValues(alpha: .6),
                    fontWeight: FontWeight.w300,
                    fontSize: 12.0,
                  ),
                  emojiStyle: TextStyle(
                      color: AppColors.getTheme().textColor,
                      fontSize: 12.0,
                      fontFamily: "Noto Color Emoji"
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}