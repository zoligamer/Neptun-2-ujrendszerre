import 'dart:async';
import 'dart:convert' as conv;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neptun2/API/ics_calendar.dart';
import 'package:neptun2/Misc/clickable_text_span.dart';
import 'package:neptun2/colors.dart';
import 'package:neptun2/language.dart';
import '../app_analitics.dart';
import '../storage.dart' as storage;
import 'dart:developer' as debug;

import '../storage.dart';
  
  class URLs{
    static const String INSTITUTIONS_URL = "https://mobilecloudservice.cloudapp.net/MobileServiceLib/MobileCloudService.svc/GetAllNeptunMobileUrls";
    static const String TRAININGS_URL = "/GetTrainings";
    static const String CALENDAR_URL = "/GetCalendarData";
    static const String PERIODTERMS_URL = "/GetPeriodTerms";
    static const String PERIODS_URL = "/GetPeriods";
    static const String GETCASHIN_URL = "/GetCashinData";
    static const String CURRICULUMS_URL = "/GetCurriculums";
    static const String MARKBOOK_URL = "/GetMarkbookData";
    static const String MESSAGES_URL = "/GetMessages";
    static const String MESSAGE_SET_READ = "/SetReadedMessage";
  }
  
  class _APIRequest{
    // POST-REQUEST for old API and modern login
    static Future<String> postRequest(Uri url, String requestBody,{String? bearerToken}) async{
      HttpOverrides.global = NeptunCerts.getCerts();
  
      final client = http.Client();
      final request = http.Request('POST', url);

      request.headers['Content-Type'] = 'application/json';
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $bearerToken';
      }
      request.body = requestBody;

      var response;
      try{
        response = await client.send(request).then((response) {
          // Read and return the response
          return response.stream.bytesToString();
        });

        if (response != null) {
          String responseString = response.toString().trim();
          if (responseString.startsWith('<!DOCTYPE html') || responseString.startsWith('<html')){
            AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => _APIRequest.postRequest() Erorr: HTML response recieved from $url');
            client.close();
            return '{"ErrorMessage": "Hibás URL vagy a Neptun szervere weboldalt küldött válaszként"}';
          }
        }
      }
      catch(error){
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => _APIRequest.postRequest() NeptunError: PostRequest Error: $error');
        client.close();
        return '{"ErrorMessage": "Hálózati hiba: $error"}';
      }

      // Close the client when done
      client.close();
  
      return response ?? '{}';
    }


    //new GET REQUEST for modern API
    static Future<String> getRequest(Uri url, {required String bearerToken}) async {
      HttpOverrides.global = NeptunCerts.getCerts();

      final client = http.Client();
      final request = http.Request('GET', url);

      // Új API-nál KÖTELEZŐ a token a GET kéréseknél is!
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $bearerToken';

      var response;
      try {
        response = await client.send(request).then((response) {
          return response.stream.bytesToString();
        });

        if (response != null) {
          String responseString = response.toString().trim();
          if (responseString.startsWith('<!DOCTYPE html') || responseString.startsWith('<html')) {
            AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => _APIRequest.getRequest() Error: HTML response received from $url');
            client.close();
            return '{"ErrorMessage": "Weboldal érkezett JSON helyett!"}';
          }
        }
      } catch (error) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => _APIRequest.getRequest() Error: $error');
        client.close();
        return '{"ErrorMessage": "Hálózati hiba: $error"}';
      }

      client.close();
      return response ?? '{}';
    }

    static String getGenericPostData(String username, String password){
      return
        '{'
          '"UserLogin":"$username",'
          '"Password":"$password"'
        '}';
    }
  
    static Future<List<Term>> _getTermIDs() async{
      if(storage.DataCache.getIsDemoAccount()!){
        return <Term>[Term(70876, 'DEMO Félév')];
      }
      return getTerms();
    }

    static Future<List<Term>> getTerms() async{
      if(storage.DataCache.getIsDemoAccount()!){
        return <Term>[Term(70876, 'DEMO Félév')];
      }
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.PERIODTERMS_URL);
      final request = await _APIRequest.postRequest(url, _APIRequest.getGenericPostData(username!, password!));

      final decoded = conv.json.decode(request);
      if (decoded['PeriodTermsList'] == null) return []; // Ha nincs lista, adunk egy üreset, és nem fagy ki!
      List<dynamic> termList = decoded['PeriodTermsList'];


      /*List<dynamic> termList = conv.json.decode(request)['PeriodTermsList'];  OLD CODE*/
      List<Term> terms = [];
      for (var term in termList){
        final map = term as Map<String, dynamic>;
        terms.add(Term(map['Id'], map['TermName']));
      }
      return terms;
    }
  }
  
  class InstitutesRequest{
    static Future<List<dynamic>?> fetchInstitudesJSON() async{
      //return _APIRequest.postRequest(Uri.parse(URLs.INSTITUTIONS_URL), '{}');
      var json;
      try{
        json = await getRawJsonWithNameUrlPairs();
      }
      catch(error){
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => InstitudesRequest.fetchInstitudesJSON() Error: $error');
      }
      return json;
    }

    static Future<List<dynamic>?> getRawJsonWithNameUrlPairs() async{
      final url = Uri.parse('https://raw.githubusercontent.com/zoligamer/Neptun-Mobile-fork/refs/heads/main/universityNameUrlPairs.json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => InstitudesRequest.getRawJsonWithNameUrlPairs() Error: Failed to fetch universityNameUrlPairs.json');
        return null;
      }

      Map<String, dynamic> jsonMap = conv.json.decode(response.body);
      return jsonMap["Institutes"];
    }
  
    static List<Institute> getDataFromInstitudesJSON(List<dynamic> jsonMap){
      var newList = <Institute>[].toList();
      for (var item in jsonMap){
        var item2 = item as Map<String, dynamic>;
        String name = item2['Name'];
        String url = item2['Url'] ?? "NULL";
        if(url != "NULL" && name != "DEMO") { //remove obsolete or non existent entries
          newList.add(Institute(name, url));
        }
      }
      return newList;
    }
    static Future<int> validateLoginCredentials(Institute institute, String username, String password) async{
      return validateLoginCredentialsUrl(institute.URL, username, password);
    }
    //
// --- 2FA TÁMOGATÁSSAL ---
    static Future<int> validateLoginCredentialsUrl(String rawUrl, String username, String password) async {
      if(username == 'DEMO' && password == 'DEMO'){
        await storage.DataCache.setIsDemoAccount(1);
        return 1;
      }

      String url = rawUrl.trim();
      if (url.endsWith('/')) url = url.substring(0, url.length - 1);
      bool containsAspx = url.toLowerCase().contains('.aspx');

      String baseUrl = url.replaceAll(RegExp(r'/login(\.aspx)?$', caseSensitive: false), '');
      baseUrl = baseUrl.replaceAll(RegExp(r'/MobileService\.svc$', caseSensitive: false), '');

      if (baseUrl.toLowerCase().contains('uni-obuda.hu/hallgato')) {
        baseUrl = baseUrl.replaceAll(RegExp(r'/hallgato', caseSensitive: false), '/ujhallgato');
      }

      if (containsAspx) {
        // Réginél nincs 2FA, ott marad a bool -> int konverzió
        bool success = await _tryOldLogin(baseUrl, username, password);
        return success ? 1 : 0;
      } else {
        return await _tryModernLogin(baseUrl, username, password);
      }
    }

    static Future<int> _tryModernLogin(String baseUrl, String username, String password) async {
      try {
        final modernApiUrl = Uri.parse("$baseUrl/api/Account/Authenticate");
        final body = conv.jsonEncode({
          "userName": username, "password": password,
          "captcha": "", "captchaIdentifier": "", "token": "", "LCID": 1038
        });

        final responseRaw = await _APIRequest.postRequest(modernApiUrl, body);
        final response = conv.jsonDecode(responseRaw);

        // 2FA ELLENŐRZÉS (Mindkét névváltozatot nézzük a biztonság kedvéért)
        final is2fa = response["data"] != null && (response["data"]["isTwoFactorRequired"] == true || response["data"]["requiresTwoFactor"] == true);
        if (is2fa) {
          await storage.DataCache.setInstituteUrl(baseUrl);
          await storage.DataCache.setAccessToken(response["data"]["twoFactorLoginToken"]);
          return 2; // 2FA KELL
        }

        if (response["data"] != null && response["data"]["accessToken"] != null) {
          await storage.DataCache.setAccessToken(response["data"]["accessToken"]);
          await storage.DataCache.setIsModernApi(true);
          await storage.DataCache.setInstituteUrl(baseUrl);
          return 1; // SIKER
        }
      } catch (e) { }
      return 0; // HIBA
    }

    // ÚJ FÜGGVÉNY A 2FA KÓDHOZ
    static Future<bool> submitTwoFactorCode(String username, String password, String code) async {
      try {
        String baseUrl = storage.DataCache.getInstituteUrl() ?? '';
        //String? tempToken = await storage.DataCache.getAccessToken();

        final url = Uri.parse("$baseUrl/api/Account/Authenticate");
        final body = conv.jsonEncode({
          "userName": username,
          "password": password,
          "captcha":"",
          "captchaIdentifier":"",
          "token": code,
          "LCID":1038
        });

        final responseRaw = await _APIRequest.postRequest(url, body);
        final response = conv.jsonDecode(responseRaw);

        if (response["data"] != null && response["data"]["accessToken"] != null) {
          await storage.DataCache.setAccessToken(response["data"]["accessToken"]);
          await storage.DataCache.setIsModernApi(true);
          return true;
        }
      } catch (e) { }
      return false;
    }

    // NAPTÁR IDŐ FIX (+10 perc dupla óráknál)
    //
    /*
    final durationMinutes = (eventEndEpoch - eventStartEpoch) / 1000 / 60;
    if (durationMinutes > 60) {
        eventEndEpoch += 600000; // +10 perc
    }
  */
    // --- SEGÉDFÜGGVÉNY: RÉGI LOGIN ---
    static Future<bool> _tryOldLogin(String baseUrl, String username, String password) async {
      try {
        final oldApiUrl = Uri.parse("$baseUrl/MobileService.svc" + URLs.TRAININGS_URL);
        final request = await _APIRequest.postRequest(
            oldApiUrl,
            _APIRequest.getGenericPostData(username, password)
        );

        if (request.trim().startsWith('{')) {
          final decodedResponse = conv.json.decode(request);
          if (decodedResponse["ErrorMessage"] == null) {
            await storage.DataCache.setIsModernApi(false);
            await storage.DataCache.setInstituteUrl("$baseUrl/MobileService.svc");
            return true;
          }
        }
      } catch (e) { }
      return false;
    }

    static Future<int?> getFirstStudyweek() async{
      final periods = await PeriodsRequest.getPeriods();
      if(storage.DataCache.getIsDemoAccount()!){
        return DateTime(2024, 9, 1).millisecondsSinceEpoch;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      if(periods == null){
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => InstitudesRequest.getFirstStudyweek() Error: No period available');
        return null;
      }
  
      PeriodEntry? period;
      int neededExtraWeeks = 0;
      for (var item in periods){
        if(item.name.toLowerCase().contains('végleges tárgyjelentkezés')){
          if(item.startEpoch <= now || period != null && item.startEpoch <= now && item.startEpoch > period.startEpoch){
            period = item;
            neededExtraWeeks = 0;
          }
        }
      }
      if(period == null){
        for (var item in periods){
          if(item.name.toLowerCase().contains('bejelentkezési időszak')){
            if(item.startEpoch <= now || period != null && item.startEpoch <= now && item.startEpoch > period.startEpoch){
              period = item;
              neededExtraWeeks = 1;
            }
          }
        }
        if(period == null){
          AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => InstitudesRequest.getFirstStudyweek() Error: No "végleges tárgyjelenkezés" or "bejelentkezési időszak" period available, ${periods.toString()}');
          return null;
        }
      }
  
      //final startDate = DateTime.fromMillisecondsSinceEpoch(period.startEpoch);
      final date = DateTime.fromMillisecondsSinceEpoch(period.endEpoch);
      int difference = date.weekday - DateTime.monday;

      final roundedDate = date.subtract(Duration(days: difference)).add(Duration(days: 7 * neededExtraWeeks));

      return roundedDate.millisecondsSinceEpoch;
    }
  }
  
  class CalendarRequest{

    static String? _cachedTrainingId;

    static Future<String?> getStudentTrainingId({bool forceRefresh = false}) async {
      // ÚJ LOGIKA: Ha a forceRefresh igaz, letöröljük a memóriát, hogy újra letöltse!
      if (forceRefresh) {
        _cachedTrainingId = null;
      }

      if (_cachedTrainingId != null) return _cachedTrainingId;
      if (!(storage.DataCache.getIsModernApi() /*?? false*/)) return null;

      try {
        final token = await storage.DataCache.getAccessToken();
        String baseUrl = storage.DataCache.getInstituteUrl() ?? '';

        final url = Uri.parse("$baseUrl/api/Calendar/GetStudentTrainings");

        final responseRaw = await _APIRequest.getRequest(url, bearerToken: token!);
        final decoded = conv.json.decode(responseRaw);

        if (decoded['data'] != null && decoded['data'].isNotEmpty) {
          for (var training in decoded['data']) {
            if (training['actualStudentTraining'] == true) {
              _cachedTrainingId = training['studentTrainingId'];
              return _cachedTrainingId;
            }
          }
          _cachedTrainingId = decoded['data'][0]['studentTrainingId'];
          return _cachedTrainingId;
        }
      } catch (e) { }
      return null;
    }
    //

    /* stable build code
    static Future<String?> getStudentTrainingId() async {
      // Ha már egyszer lekérte, azonnal visszaadja a memóriából
      if (_cachedTrainingId != null) return _cachedTrainingId;

      // Ha régi Neptunt használ a diák (pl. BME), akkor ez az egész nem kell
      if (!storage.DataCache.getIsModernApi()) return null;

      try {
        final token = await storage.DataCache.getAccessToken();
        final url = Uri.parse(storage.DataCache.getInstituteUrl()! + "/api/Calendar/GetStudentTrainings");

        // Itt a tegnap megírt új GET metódusunkat használjuk!
        final responseRaw = await _APIRequest.getRequest(url, bearerToken: token!);
        final decoded = conv.json.decode(responseRaw);

        if (decoded['data'] != null && decoded['data'].isNotEmpty) {
          // Megkeressük az "Aktuális" félévhez tartozó képzést
          for (var training in decoded['data']) {
            if (training['actualStudentTraining'] == true) {
              _cachedTrainingId = training['studentTrainingId'];
              return _cachedTrainingId;
            }
          }
          // Ha valamiért nincs megjelölve, visszaadjuk az elsőt a listából
          _cachedTrainingId = decoded['data'][0]['studentTrainingId'];
          return _cachedTrainingId;
        }
      } catch (e) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => getStudentTrainingId() Error: $e');
      }
      return null;
    }*/

    static List<CalendarEntry> getCalendarEntriesFromJSON(String jsonString) {
      if (jsonString == '{}') return [];

      final decoded = conv.json.decode(jsonString);
      List<CalendarEntry> list = [];

      if (storage.DataCache.getIsModernApi() /*?? false*/) {
        if (decoded['calendarData'] != null) {
          for (var item in decoded['calendarData']) {
            list.add(CalendarEntry.fromModern(
              startEpoch: item['start_ms'],
              endEpoch: item['end_ms'],
              location: item['location'],
              title: item['title'],
              isExam: item['type'] == 1,
              subjectCode: item['subjectCode'],
              teacher: item['teacher'],
            ));
          }
        }
        return list;
      }

      if (decoded['calendarData'] != null) {
        for (var item in decoded['calendarData']) {
          list.add(CalendarEntry(
            item['start'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
            item['end'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
            item['location'],
            item['title'],
            item['type'] == 1,
          ));
        }
      }
      return list;
    }



    static Future<String> makeCalendarRequest(String calendarJson) async {
      if (storage.DataCache.getIsDemoAccount()! || storage.DataCache.getHasICSFile()!) {
        return '{}';
      }

      if (storage.DataCache.getIsModernApi() /*?? false*/) {
        try {
          final oldPayload = conv.json.decode(calendarJson);
          final startDateRaw = (oldPayload['startDate'] ?? oldPayload['StartDate']).toString();
          final endDateRaw = (oldPayload['endDate'] ?? oldPayload['EndDate']).toString();

          final numRegex = RegExp(r'\d+');
          final startEpoch = int.parse(numRegex.firstMatch(startDateRaw)!.group(0)!);
          final endEpoch = int.parse(numRegex.firstMatch(endDateRaw)!.group(0)!);

          final startIso = DateTime.fromMillisecondsSinceEpoch(startEpoch).toIso8601String();
          final endIso = DateTime.fromMillisecondsSinceEpoch(endEpoch).toIso8601String();

          String baseUrl = storage.DataCache.getInstituteUrl() ?? '';
          String responseRaw = "";
          bool needsReAuth = false;

          // ==========================================
          // 1. PRÓBA: Meglévő adatokkal (Szerverbarát)
          // ==========================================
          try {
            final trainingId = await getStudentTrainingId(forceRefresh: false);
            if (trainingId != null) {
              final token = await storage.DataCache.getAccessToken();
              final url = Uri.parse("$baseUrl/api/Calendar/GetCalendarEvents?startDate=$startIso&endDate=$endIso&studentTrainingIds[0]=$trainingId&displayClasses=true&displayExams=true&displayOnlineMeetings=true&displayOtherEvents=true&displayPeriods=true&displayTasks=true");

              responseRaw = await _APIRequest.getRequest(url, bearerToken: token!);

              // Megnézzük, hogy a válaszban nincs-e 401-es vagy 410-es hiba
              if (responseRaw.contains('"statusCode":410') || responseRaw.contains('Authorization has been denied') || responseRaw.contains('"statusCode": 401')) {
                needsReAuth = true;
              }
            } else {
              needsReAuth = true;
            }
          } catch (e) {
            // Ha a getRequest kivételt dobott a hiba miatt, akkor is újra kell próbálni
            needsReAuth = true;
          }

          // ==========================================
          // 2. PRÓBA: Csak ha kidobott minket a Neptun!
          // ==========================================
          if (needsReAuth) {
            debug.log("Naptár: Lejárt token/ID érzékelve. Újra-azonosítás indul...");

            final username = storage.DataCache.getUsername()!;
            final password = storage.DataCache.getPassword()!;
            await InstitutesRequest.validateLoginCredentialsUrl(baseUrl, username, password);

            // Itt már a forceRefresh: true-t használjuk!
            final newTrainingId = await getStudentTrainingId(forceRefresh: true);
            if (newTrainingId == null) return '{"calendarData": []}';

            final newToken = await storage.DataCache.getAccessToken();
            final retryUrl = Uri.parse("$baseUrl/api/Calendar/GetCalendarEvents?startDate=$startIso&endDate=$endIso&studentTrainingIds[0]=$newTrainingId&displayClasses=true&displayExams=true&displayOnlineMeetings=true&displayOtherEvents=true&displayPeriods=true&displayTasks=true");

            responseRaw = await _APIRequest.getRequest(retryUrl, bearerToken: newToken!);
          }

          // ==========================================
          // ADATOK FELDOLGOZÁSA
          // ==========================================
          final newApiData = conv.json.decode(responseRaw);
          List<Map<String, dynamic>> mappedList = [];

          if (newApiData['data'] != null) {
            for (var event in newApiData['data']) {
              final eventStartEpoch = DateTime.parse(event['startDate']).millisecondsSinceEpoch;
              final eventEndEpoch = DateTime.parse(event['endDate']).millisecondsSinceEpoch;

              mappedList.add({
                'start_ms': eventStartEpoch,
                'end_ms': eventEndEpoch,
                'location': event['rooms'] ?? 'Nincs terem',
                'title': event['name'] ?? 'Ismeretlen',
                'type': event['eventTypeId'] == 1 ? 1 : 0,
                'subjectCode': event['courseCode'] ?? '-',
                'teacher': event['courseTutor'] ?? 'Nincs megadva',
              });
            }
          }
          return conv.jsonEncode({"calendarData": mappedList});

        } catch (e) {
          debug.log("Naptár lekérési hiba: $e");
          return '{"calendarData": []}';
        }
      } else {
        final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.CALENDAR_URL);
        final request = await _APIRequest.postRequest(url, calendarJson);
        return request;
      }
    }


    static String getCalendarOneWeekJSON(String username, String password, int weekOffset){
      if(storage.DataCache.getIsDemoAccount()!){
        return '';
      }
      final DateTime now = DateTime.now();
      DateTime previousMonday = now.subtract(Duration(days: now.weekday));
      if (previousMonday.weekday == 7) {
        previousMonday = previousMonday.subtract(const Duration(days: 7));
      }
      previousMonday = DateTime(previousMonday.year, previousMonday.month, previousMonday.day, 0, 0);

      DateTime nextSunday = previousMonday.add(const Duration(days: 6, hours: 23, minutes: 59));
      if (nextSunday.weekday == 7) {
        nextSunday = nextSunday.subtract(const Duration(days: 7));
      }

      DateTime startOfTargetWeek = previousMonday.add(Duration(days: weekOffset * 7));
      DateTime endOfTargetWeek = nextSunday.add(Duration(days: weekOffset * 7));//.add(Duration(days: 7));

      final epochStart = startOfTargetWeek.millisecondsSinceEpoch;
      final epochEnd = endOfTargetWeek.millisecondsSinceEpoch;

      return
        '{'
          '"UserLogin":"$username",'
          '"Password":"$password",'
          '"Time":true,'
          '"Exam":true,'
          '"startDate":"/Date($epochStart)/",'
          '"endDate":"/Date($epochEnd)/",'
          '"TotalRowCount":-1'
        '}';
    }
  }

  class MarkbookRequest{
    static Future<String> _getMarkbookJSon() async{
      if(storage.DataCache.getIsDemoAccount()!){
        return '';
      }
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.MARKBOOK_URL);
      final json =
          '{'
            '"UserLogin":"$username",'
            '"Password":"$password",'
            '"CurrentPage":1,'
            '"filter":{"TermID": 0},'
            '"TotalRowCount":-1'
          '}';
      final request = await _APIRequest.postRequest(url, json);
      return request;
    }
  
    static Future<List<Subject>?> getMarkbookSubjects() async{
      if(storage.DataCache.getIsDemoAccount()!){
        return <Subject>[
          Subject(false, 1, 'DEMO tantárgy 1', 0, 4, 0),
          Subject(false, 1, 'DEMO tantárgy 12', 0, 0, 0),
          Subject(true, 2, 'DEMO tantárgy 2', 0, 4, 0),
          Subject(true, 4, 'DEMO tantárgy 3', 0, 2, 0),
          Subject(true, 1, 'DEMO tantárgy 4', 0, 1, 0),
          Subject(true, 2, 'DEMO tantárgy 5', 0, 2, 0),
          Subject(true, 3, 'DEMO tantárgy 6', 0, 3, 0),
          Subject(true, 4, 'DEMO tantárgy 7', 0, 4, 0),
          Subject(true, 5, 'DEMO tantárgy 8', 0, 5, 0),
          Subject(true, 0, 'DEMO tantárgy 9', 0, 1, 0),
          Subject(true, 0, 'DEMO tantárgy 10', 0, 0, 0),
          Subject(false, 0, 'DEMO tantárgy 11', 0, 1, 0),
          Subject(false, 10, 'DEMO szellemjegy 1', 1, 0, 0),
          Subject(true, 2, 'DEMO szellemjegy 2', 1, 0, 0),
        ];
      }
      else if(storage.DataCache.getHasICSFile() ?? false){
        return [];
      }
      /*List<Term> terms = await _APIRequest._getTermIDs();
      if(terms.isEmpty){
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => MarkbookRequest._getMarkbookJSon() Error: No Terms');
        return <Subject>[
          Subject(false, 0, 'Hiba a jegyzetfüzet betöltésekor!\nNincs term id', 0, 0, 1),
        ];
      }*/
  
      String responseJson = await _getMarkbookJSon();
      List<dynamic> markbooklistRaw = [];
      /*markbooklistRaw = conv.json.decode(responseJson)['MarkBookList']; OLD CODE*/
      final decoded = conv.json.decode(responseJson);
      if (decoded['MarkBookList'] == null) return null; // Ha nincs jegylista, biztonságosan kilép
      markbooklistRaw = decoded['MarkBookList'];
  
      if(responseJson.isEmpty || markbooklistRaw.isEmpty){    // if we went thru all possible markbooks, but non was valid
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => MarkbookRequest._getMarkbookJSon() Error: No reponsejson, and markbooklist is empty');
        return null;
      }
  
      List<Subject> subjects = [];
  
      for (var markbook in markbooklistRaw){
        final markbookMap = markbook as Map<String, dynamic>;
        subjects.add(Subject(markbookMap['Completed'], markbookMap['Credit'], markbookMap['SubjectName'], markbookMap['ID'], parseTextToGrade(markbookMap['Values']), parseTextToFailstate(markbookMap['Signer'])));
      }

      return subjects;
    }
  
    static int parseTextToFailstate(String failstate){
      RegExp regex = RegExp(r'(aláírva|megtagadva)');
      final matches = regex.allMatches(failstate.toLowerCase());
      if(matches.isEmpty){
        return 0;
      }

      int best = 99;
      for(var match in matches){
        final result = (match.group(1) ?? '').trim().toLowerCase();
        if(result.isEmpty){
          return 0;
        }
        switch (result){
          case "megtagadva":
            if(best > 1){
              best = 1;
            }
          default:
            if(best > 0){
              best = 0;
            }
        }
      }
      return best;
    }
  
    static bool isMark(String txt){
      switch(txt){
        case 'jeles':
        case 'jó':
        case 'közepes':
        case 'elégséges':
        case 'elégtelen':
          return true;
        default:
          return false;
      }
    }
  
    static int parseTextToGrade(String gradeTxt){
      RegExp regex = RegExp(r'(elégtelen|elégséges|közepes|jó|jeles)');
      final matches = regex.allMatches(gradeTxt.toLowerCase());
      if(matches.isEmpty){
        return 0;
      }

      int latest = 0; // we need the latest grade, as that is what counts (idk why)
      for(var match in matches){
        final result = (match.group(1) ?? '').trim().toLowerCase();
        if(result.isEmpty){
          break;
        }
        switch (result){
          case 'jeles':
            latest = 5;
            break;
          case 'jó':
            latest = 4;
            break;
          case 'közepes':
            latest = 3;
            break;
          case 'elégséges':
            latest = 2;
            break;
          case 'elégtelen':
            latest = 1;
            break;
        }
      }
      return latest;
    }
  }
  
  class CashinRequest{
    static Future<List<CashinEntry>?> getAllCashins() async{
      if(storage.DataCache.getIsDemoAccount()!){
        final now = DateTime.now();
        return <CashinEntry>[
          CashinEntry(10000, DateTime(now.year + 1, now.month).millisecondsSinceEpoch, 'DEMO befizetés 1', 1, 'aktív'),
          CashinEntry(70, DateTime(now.year + 1, now.month).millisecondsSinceEpoch, 'DEMO befizetés 2', 1, 'teljesített'),
          CashinEntry(-1, DateTime(now.year - 1, now.month).millisecondsSinceEpoch, 'DEMO befizetés 3', 0, 'aktív'),
          CashinEntry(-1, DateTime(now.year - 1, now.month).millisecondsSinceEpoch, 'DEMO befizetés 4', 0, 'teljesített'),
          CashinEntry(1000, 0, 'DEMO befizetés 5', 0, 'aktív'),
        ];
      }
      else if(storage.DataCache.getHasICSFile() ?? false){
        return [];
      }
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final json =
          '{'
          '"UserLogin":"$username",'
          '"Password":"$password",'
          '"TotalRowCount":-1'
          '}';
  
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.GETCASHIN_URL);
  
      List<CashinEntry> entries = CashinRequest._jsonToCashinEntry(await _APIRequest.postRequest(url, json));
      return entries;
    }
  
  
    static List<CashinEntry> _jsonToCashinEntry(String json){
      if(storage.DataCache.getIsDemoAccount()!){
        return <CashinEntry>[CashinEntry(87878, 999999999, 'DEMO befizetés', 0, 'teljesítve')];
      }
      List<CashinEntry> ls = [];
      try {
        final List<dynamic> cashins = conv.json.decode(json)['CashinDataRows'];
        for (var cashin in cashins) {
          ls.add(CashinEntry(
              cashin['amount'],
              int.parse(cashin['deadline'] == null ? '0' : cashin['deadline']
                  .toString().replaceAll('/Date(', '')
                  .replaceAll(')/', '')),
              cashin['appellation'],
              cashin['ID'],
              cashin['status_name']
          ));
        }
      }
      catch (_){
        return [];
      }
      return ls;
    }
  }
  
  class PeriodsRequest{
  
    static Future<List<PeriodEntry>?> getPeriods() async{
      if(storage.DataCache.getIsDemoAccount()!){
        final now = DateTime.now();
        return <PeriodEntry>[
         PeriodEntry('lejárt időszak', DateTime(now.year - 1, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year - 1, now.month, now.day + 1).millisecondsSinceEpoch, 1),
          PeriodEntry('előzetes tárgyjelentkezés', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch, 1),
          PeriodEntry('jegybeírási időszak', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month, now.day + 2).millisecondsSinceEpoch, 1),
          PeriodEntry('bejelentkezési időszak', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month, now.day +7).millisecondsSinceEpoch, 1),
          PeriodEntry('megajánlott jegy beírási időszak', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month, now.day + 14).millisecondsSinceEpoch, 1),
          PeriodEntry('végleges tárgyjelentkezés', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month + 1, now.day).millisecondsSinceEpoch, 1),
          PeriodEntry('kurzusjelentkezési időszak', DateTime(now.year, now.month, now.day - 2).millisecondsSinceEpoch, DateTime(now.year, now.month + 2, now.day).millisecondsSinceEpoch, 2),
          PeriodEntry('szorgalmi időszak', DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch, DateTime(now.year, now.month + 3, now.day).millisecondsSinceEpoch, 2),
          PeriodEntry('vizsgajelentkezési időszak', DateTime(now.year, now.month, now.day + 20).millisecondsSinceEpoch, DateTime(now.year + 1, now.month, now.day).millisecondsSinceEpoch, 3),
          PeriodEntry('none', DateTime(now.year, now.month + 1, now.day).millisecondsSinceEpoch, DateTime(now.year + 1, now.month, now.day).millisecondsSinceEpoch, 4),

          //PeriodEntry('bejelentkezési időszak', DateTime(2024, 01, 15, 00, 00).millisecondsSinceEpoch, DateTime(2024, 02, 09, 24, 59, 59).millisecondsSinceEpoch, 1),
        ];
      }
      else if(storage.DataCache.getHasICSFile() ?? false){
        return [
          PeriodEntry('végleges tárgyjelentkezés', await ICSCalendar.getFirstEventStartMs(), await ICSCalendar.getFirstEventStartMs() + Duration(days: 365).inMilliseconds, 1)
        ];
      }
      final terms = await _APIRequest._getTermIDs();
      if(terms.isEmpty){
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => PeriodsRequest.getPeriods() Error: No Terms');
        return <PeriodEntry>[
          PeriodEntry('Hiba lépett fel!\nNincs term id.', DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch, 1)
        ];
      }
      List<PeriodEntry> periods = <PeriodEntry>[];
      int cntperiod = terms.length;
      for(var term in terms){
        final jsonresult = await _getPeriodJSon(term.id);
        final result = conv.json.decode(jsonresult)['PeriodList'] as List<dynamic>;
        for(var period in result){
          final currPeriod = period as Map<String, dynamic>;
          periods.add(PeriodEntry(currPeriod['PeriodTypeName'], int.parse(currPeriod['FromDate'].toString().replaceAll('/Date(', '').replaceAll(')/', '')), int.parse(currPeriod['ToDate'].toString().replaceAll('/Date(', '').replaceAll(')/', '')), cntperiod));
        }
        cntperiod--;
      }
      return periods;
    }
  
    static Future<String> _getPeriodJSon(int termID) async{
      if(storage.DataCache.getIsDemoAccount()!){
        return '';
      }
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.PERIODS_URL);
      final json =
          '{'
          '"UserLogin":"$username",'
          '"Password":"$password",'
          '"PeriodTermID":$termID,'
          '"TotalRowCount":-1'
          '}';
      final request = await _APIRequest.postRequest(url, json);
      return request;
    }
  }

  class MailRequest{
    static Future<List<int>> getUnreadMessagesAndAllMessages()async{
      try{
        List<int> list = [];
        final json = await _getMailJson(0);
        var result = conv.json.decode(json)['NewMessagesNumber'];
        list.add(result);
        result = conv.json.decode(json)['TotalRowCount'];
        list.add(result);
        return list;
      }
      catch(_){
        return [0, 0, 0];
      }
    }
    static Future<List<MailEntry>?> getMails(int page) async{
      if(storage.DataCache.getIsDemoAccount()!){
        final now = DateTime.now();
        return <MailEntry>[
          MailEntry('Tárgy', 'Szöveg', 'DEMO feladó', now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch, false, 0),
          MailEntry('DEMO', 'Demo Demo Demo\n\n\nDEmo demo', 'DEMO feladó', now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch, false, 0),
          MailEntry('DEMO', 'Demo Demo Demo\n\n\nDEmo demo', 'DEMO feladó', now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch, true, 0),
          MailEntry('DEMO', 'Demo Demo Demo\n\n\nDEmo demo', 'DEMO feladó', now.subtract(const Duration(days: 10)).millisecondsSinceEpoch, true, 0),
          MailEntry('DEMO', 'Demo Demo Demo\n\n\nDEmo demo', 'DEMO feladó', now.subtract(const Duration(days: 100)).millisecondsSinceEpoch, false, 0),
          MailEntry('DEMO', 'Demo Demo Demo\n\n\nDEmo demo', 'DEMO feladó', now.subtract(const Duration(days: 370)).millisecondsSinceEpoch, true, 0),
        ];
      }
      else if(storage.DataCache.getHasICSFile() ?? false){
        return [];
      }

      final request = await _getMailJson(page);
      List<MailEntry> mails = getMailEntrysJson(request);
      return mails;
    }

    static Future<String> _getMailJson(int page)async{
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.MESSAGES_URL);
      //final json = _APIRequest.getGenericPostData(username!, password!);
      final json =
      '{'
      '"UserLogin":"$username",'
      '"Password":"$password",'
      '"CurrentPage":$page,'
      '"TotalRowCount":-1,'
      '"MessageID":0,'
      '"MessageSortEnum":0'
      '}';
      final request = await _APIRequest.postRequest(url, json);
      return request;
    }

    static List<MailEntry> getMailEntrysJson(String json){
      List<MailEntry> mails = [];

      final decoded = conv.json.decode(json);
      if (decoded['MessagesList'] == null) return []; // Ha nincs levéllista, üres listát adunk vissza
      final result = decoded['MessagesList'] as List<dynamic>;

      /*final result = conv.json.decode(json)['MessagesList'] as List<dynamic>; OLD CODE*/

      for(var item in result){
        mails.add(MailEntry(item['Subject'], removeBloatFromMail(item['Detail']), item['Name'], int.parse(item['SendDate'].toString().replaceAll('\/Date(', '').replaceAll(')\/', '')), !item['IsNew'], item['PersonMessageId']));
      }
      return mails;
    }

    static String removeBloatFromMail(String raw){
      var sanitised = raw.trim();
      sanitised = sanitised.replaceAll(RegExp(r'\.\w+\{[^}]*\}'), '');
      return sanitised.trim();
    }

    static Future<void> setMailRead(int id)async{
      if(storage.DataCache.getIsDemoAccount()!){
        return;
      }
      final username = storage.DataCache.getUsername();
      final password = storage.DataCache.getPassword();
      final url = Uri.parse(storage.DataCache.getInstituteUrl()! + URLs.MESSAGE_SET_READ);
      final json =
          '{'
          '"UserLogin":"$username",'
          '"Password":"$password",'
          '"PersonMessageId":$id,'
          '}';
      await _APIRequest.postRequest(url, json);
    }
  }
  
  class Term{
    int id;
    String termName;
  
    Term(this.id, this.termName);
  }
  
  class Subject{
    bool completed;
    int credit;
    int id;
    String name;
    int grade = 0;
    int failState = 0;
  
  
    Subject(this.completed, this.credit, this.name, this.id, this.grade, this.failState);
  
    @override
    String toString() {
      return '$completed\n$credit\n$id\n$name\n$grade\n$failState';
    }
  
    Subject fillWithExisting(String existing){
      var data = existing.split('\n');
      if(data.length < 6){
        completed = false;
        credit = 0;
        id = 0;
        name = 'ERROR';
        grade = 0;
        failState = 1;
        return this;
      }
      completed = bool.parse(data[0]);
      credit = int.parse(data[1]);
      id = int.parse(data[2]);
      name = data[3];
      grade = int.parse(data[4]);
      failState = int.parse(data[5]);
      return this;
    }
  }
  
  class Institute{
    late final String Name;
    late final String URL;
  
    Institute(String name, String url){
      Name = name;
      URL = url;
    }
  
    getUrl() => Uri.parse(URL);
  }
  
  //
class CalendarEntry {
  late int startEpoch;
  late int endEpoch;
  late String location;
  late String title;
  late bool isExam;
  late String subjectCode;
  late String teacher;

  // RÉGI API KONSTRUKTOR
  CalendarEntry(String start, String end, String loc, String rawTitle, this.isExam) {
    startEpoch = int.parse(start);
    // JAVÍTVA: Töröltem az 'api.' előtagot a Generic elől
    startEpoch = DateTime.fromMillisecondsSinceEpoch(startEpoch)
        .subtract(Duration(hours: (Generic.isDaylightSavings(DateTime.fromMillisecondsSinceEpoch(startEpoch)) ? 2 : 1)))
        .millisecondsSinceEpoch;

    endEpoch = int.parse(end);
    endEpoch = DateTime.fromMillisecondsSinceEpoch(endEpoch)
        .subtract(Duration(hours: (Generic.isDaylightSavings(DateTime.fromMillisecondsSinceEpoch(endEpoch)) ? 2 : 1)))
        .millisecondsSinceEpoch;

    location = loc;

    final regex = RegExp(r'\]([^(]+)\(');
    final match = regex.firstMatch(rawTitle);
    if (match != null) {
      title = match.group(1)!.replaceAll(']', '').replaceAll('(', '').replaceAll('\u0009', '').trim();
    } else {
      title = rawTitle;
    }

    final regex2 = RegExp(r'\(.*?\)');
    final match2 = regex2.firstMatch(rawTitle);
    subjectCode = match2 != null ? match2.group(0)!.replaceAll('(', '').replaceAll(')', '') : "-";

    var regex3 = RegExp(r'\(.*?\)(?=\s*\(.*?\)*$)');
    var match3 = regex3.firstMatch(rawTitle);
    if (match3 != null) {
      teacher = match3.group(0)!.trim().replaceAll('(', '').replaceAll(')', '');
    } else {
      teacher = "-";
    }
  }

  // ÚJ: MODERN API KONSTRUKTOR
  CalendarEntry.fromModern({
    required this.startEpoch,
    required this.endEpoch,
    required this.location,
    required this.title,
    required this.isExam,
    required this.subjectCode,
    required this.teacher,
  });

  @override
  String toString() {
    return '$startEpoch\n$endEpoch\n$location\n$title\n$isExam\n$teacher\n$subjectCode';
  }

  CalendarEntry fillWithExisting(String existing) {
    var data = existing.split('\n');
    if (data.isEmpty || data.length < 7) return this;
    startEpoch = int.parse(data[0]);
    endEpoch = int.parse(data[1]);
    location = data[2];
    title = data[3];
    isExam = bool.parse(data[4]);
    teacher = data[5];
    subjectCode = data[6];
    return this;
  }
}
//


  
  class CashinEntry{
    late int ID;
    late int ammount;
    late int dueDateMs;
    late String comment;
    late bool completed = false;
  
    CashinEntry(this.ammount, this.dueDateMs, this.comment, this.ID, String completed){
      if(completed.toLowerCase() == 'teljesített' || completed.toLowerCase() == 'törölt'){
        this.completed = true;
      }
    }
  
    @override
    String toString() {
      return '$ammount\n$dueDateMs\n$comment\n$completed\n$ID';
    }
  
    CashinEntry fillWithExisting(String existing){
      var data = existing.split('\n');
      if(data.isEmpty || data.length < 5){
        return this;
      }
      ammount = int.parse(data[0]);
      dueDateMs = int.parse(data[1]);
      comment = data[2];
      completed = bool.parse(data[3]);
      ID = int.parse(data[4]);
      return this;
    }
  }
  
  enum PeriodType{
    timetableRegistration,
    gradingTime,
    loginTime,
    pregivenGradingAccepting,
    timetableFinalization,
    coursesRegistration,
    nerdTime,
    examTime,
    signinTime,
    none
  }
  
  class PeriodEntry{
    late String name;
    late int startEpoch;
    late int endEpoch;
    late bool isActive;
    late int partofSemester;
    late PeriodType type;
  
    PeriodEntry(this.name, int startEpoch, int endEpoch, this.partofSemester){
      final startEp = DateTime.fromMillisecondsSinceEpoch(startEpoch);
      final correctedStartEpoch = DateTime(startEp.year, startEp.month, startEp.day);
      this.startEpoch = correctedStartEpoch.millisecondsSinceEpoch;
  
      final endEp = DateTime.fromMillisecondsSinceEpoch(endEpoch).add(const Duration(days: 1)); // last day counts too
      var correctedEndEpoch = DateTime(endEp.year, endEp.month, endEp.day);
      final isOverflowedByOneDay = endEp.add(Duration(minutes: 1)).hour == 1;
      if(isOverflowedByOneDay){
        correctedEndEpoch = correctedEndEpoch.subtract(Duration(days: 1));
      }
      this.endEpoch = correctedEndEpoch.millisecondsSinceEpoch;
  
  
      fillIsActiveStatus();
    }
  
    @override
    String toString() {
      return '$name\n$startEpoch\n$endEpoch\n$partofSemester';
    }
  
    String getValue(){
      return '$startEpoch-$endEpoch';
    }
  
    PeriodEntry fillWithExisting(String existing){
      var data = existing.split('\n');
      if(data.isEmpty || data.length < 4){
        return this;
      }
      name = data[0];
      startEpoch = int.parse(data[1]);
      endEpoch = int.parse(data[2]);
      partofSemester = int.parse(data[3]);
      fillIsActiveStatus();
      return this;
    }
  
    void fillIsActiveStatus() {
      final now = DateTime.now().millisecondsSinceEpoch;
      isActive = (startEpoch < now && now < endEpoch);
  
      switch (name.toLowerCase().trim()){
        case 'előzetes tárgyjelentkezés':
          type = PeriodType.timetableRegistration;
          break;
        case 'jegybeírási időszak':
          type = PeriodType.gradingTime;
          break;
        case 'bejelentkezési időszak':
          type = PeriodType.loginTime;
          break;
        case 'megajánlott jegy beírási időszak':
          type = PeriodType.pregivenGradingAccepting;
          break;
        case 'végleges tárgyjelentkezés':
          type = PeriodType.timetableFinalization;
          break;
        case 'kurzusjelentkezési időszak':
          type = PeriodType.coursesRegistration;
          break;
        case 'szorgalmi időszak':
          type = PeriodType.nerdTime;
          break;
        case 'vizsgajelentkezési időszak':
          type = PeriodType.examTime;
          break;
        case 'beiratkozási időszak':
          type = PeriodType.signinTime;
          break;
        default:
          type = PeriodType.none;
          break;
      }
    }
  }

  class MailEntry{
    String subject;
    String detail;
    String senderName;
    int sendDateMs;
    bool isRead;
    int ID;
    MailEntry(this.subject, this.detail, this.senderName, this.sendDateMs, this.isRead, this.ID);

    @override
    String toString() {
      return '$subject\u0000$detail\u0000$senderName\u0000$sendDateMs\u0000$isRead\u0000$ID';
    }

    MailEntry fillWithExisting(String existing){
      var data = existing.split('\u0000');
      if(data.isEmpty || data.length < 6){
        return this;
      }
      subject = data[0];
      detail = data[1];
      senderName = data[2];
      sendDateMs = int.parse(data[3]);
      isRead = bool.parse(data[4]);
      ID = int.parse(data[5]);
      return this;
    }
  }
  
  class Generic {
    static String reactionForAvg(double avg) {
      if (avg >= 5.0) {
        return "💀";
      }
      else if (avg >= 4.25) {
        return "🤓";
      }
      else if (avg >= 3.75) {
        return "😌";
      }
      else if (avg >= 2.75) {
        return "😐";
      }
      else if (avg >= 2) {
        return "😬";
      }
      else if (avg > 0) {
        return "🤡";
      }
      else {
        return '🤗';
      }
    }

    static String monthToText(int month) {
      switch (month) {
        case 1:
          return AppStrings.getLanguagePack().api_monthJan_Universal;
        case 2:
          return AppStrings.getLanguagePack().api_monthFeb_Universal;
        case 3:
          return AppStrings.getLanguagePack().api_monthMar_Universal;
        case 4:
          return AppStrings.getLanguagePack().api_monthApr_Universal;
        case 5:
          return AppStrings.getLanguagePack().api_monthMay_Universal;
        case 6:
          return AppStrings.getLanguagePack().api_monthJun_Universal;
        case 7:
          return AppStrings.getLanguagePack().api_monthJul_Universal;
        case 8:
          return AppStrings.getLanguagePack().api_monthAug_Universal;
        case 9:
          return AppStrings.getLanguagePack().api_monthSep_Universal;
        case 10:
          return AppStrings.getLanguagePack().api_monthOkt_Universal;
        case 11:
          return AppStrings.getLanguagePack().api_monthNov_Universal;
        case 12:
          return AppStrings.getLanguagePack().api_monthDec_Universal;
      }
      return "NULL";
    }

    static String dayToText(int day){
      switch(day){
        case 1:
          return AppStrings.getLanguagePack().api_dayMon_Universal;
        case 2:
          return AppStrings.getLanguagePack().api_dayTue_Universal;
        case 3:
          return AppStrings.getLanguagePack().api_dayWed_Universal;
        case 4:
          return AppStrings.getLanguagePack().api_dayThu_Universal;
        case 5:
          return AppStrings.getLanguagePack().api_dayFri_Universal;
        case 6:
          return AppStrings.getLanguagePack().api_daySat_Universal;
        case 7:
          return AppStrings.getLanguagePack().api_daySun_Universal;
        default:
          return '';
      }
    }

    static String capitalizePeriodText(String periodName) {
      final chars = periodName
          .toLowerCase()
          .trim()
          .characters
          .toList();
      String str = '';
      int idx = 0;
      bool setNexttoCapitalize = false;
      for (var item in chars) {
        if (idx == 0 || setNexttoCapitalize) {
          str += item.toUpperCase();
          idx++;
          setNexttoCapitalize = false;
          continue;
        }
        if (item == ' ') {
          setNexttoCapitalize = true;
        }
        str += item;
        idx++;
      }
      return str;
    }

    static String randomLoadingComment(bool familyFriendlyMode) {
      if (!familyFriendlyMode) {
        final gen = Random().nextInt(100) % 7;
        switch (gen) {
          case 0:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly1_Universal;
          case 1:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly2_Universal;
          case 2:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly3_Universal;
          case 3:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly4_Universal;
          case 4:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly5_Universal;
          case 5:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly6_Universal;
          case 6:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendly7_Universal;
          default:
            return 'Neptun 2';
        }
      }
      final gen = Random().nextInt(100) % 7;
      switch (gen) {
        case 0:
          return AppStrings.getLanguagePack().api_loadingScreenHint1_Universal;
        case 1:
          return AppStrings.getLanguagePack().api_loadingScreenHint2_Universal;
        case 2:
          return AppStrings.getLanguagePack().api_loadingScreenHint3_Universal;
        case 3:
          return AppStrings.getLanguagePack().api_loadingScreenHint4_Universal;
        case 4:
          return AppStrings.getLanguagePack().api_loadingScreenHint5_Universal;
        case 5:
          return AppStrings.getLanguagePack().api_loadingScreenHint6_Universal;
        case 6:
          return AppStrings.getLanguagePack().api_loadingScreenHint7_Universal;
        /*case 7:
          return '(ChatGPT)\nHa az SDA Informatika supportja egy GPS lenne, egyenesen egy tóba vezetne – irányvesztés a specialitásuk, és az problémákban való fuldoklás az erősségük...';
        case 8:
          return '(ChatGPT)\nAz SDA Informatika csapata olyan, mintha egy viziló lenne a pilóta egy tüzijátékkal, amivel próbálja elérni a Holdat – nem csak nevetséges, de az egészet rossz nézni...';
        case 9:
          return '(ChatGPT)\nAz SDA Informatika supportja olyan, mint az UFO-k – az emberek állítják, hogy létezik, de bizonyíték nincs...';
        case 10:
          return '(ChatGPT)\nAz SDA Informatika technológiai fejlesztései olyanok, mintha egy bohóc próbálna csúcstechnológiát kitalálni – a végeredmény kaotikus, és nem éppen az innováció csúcsa...';
        case 11:
          return '(ChatGPT)\nAz SDA Informatika munkakultúrája olyan, mintha egy bohóciskolában lenne az ember – kacagás és zűrzavar mindenütt, de az értékes eredmények hiányoznak...';*/
        default:
          return 'Neptun 2';
      }
    }
    static String randomLoadingCommentMini(bool familyFriendlyMode) {
      if (!familyFriendlyMode) {
        final gen = Random().nextInt(100) % 4;
        switch (gen) {
          case 0:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendlyMini1_Universal;
          case 1:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendlyMini2_Universal;
          case 2:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendlyMini3_Universal;
          case 3:
            return AppStrings.getLanguagePack().api_loadingScreenHintFriendlyMini4_Universal;
          default:
            return 'Neptun 2';
        }
      }
      final gen = Random().nextInt(100) % 3;
      switch (gen) {
        case 0:
          return AppStrings.getLanguagePack().api_loadingScreenHintMini1_Universal;
        case 1:
          return AppStrings.getLanguagePack().api_loadingScreenHintMini2_Universal;
        case 2:
          return AppStrings.getLanguagePack().api_loadingScreenHintMini3_Universal;
        default:
          return 'Neptun 2';
      }
    }

    static List<InlineSpan> textToInlineSpan(String text) {
      List<InlineSpan> spans = [];

      final htmlLink = RegExp(r'<a[^>]*>(.*?)</a>|https?://\S+|mailto:\S+');

      // Split the text at anchor tags using the regex pattern
      List<String> matches = htmlLink.allMatches(text)
          .map((m) => m.group(0)!)
          .toList();
      List<String> parts = text.split(htmlLink);

      for (int i = 0; i < parts.length; i++) {
        spans.add(TextSpan(text: parts[i]));
        if (i < matches.length) {
          if (matches[i].startsWith('<a')) {
            final htmlLink2 = RegExp(r'>(.*?)</a>');
            final match = htmlLink2.firstMatch(matches[i]);
            if (match == null) {
              continue;
            }
            String newText = match.group(1)!;

            if(!newText.contains('@') || !newText.contains('https://') || !newText.contains('http://')){
              final htmlLink3 = RegExp(r'href="(.*?)"');
              final match = htmlLink3.firstMatch(matches[i]);
              if (match == null) {
                break;
              }
              final url = match.group(1)!;
              spans.add(ClickableTextSpan.getNewClickableSpan(
                  ClickableTextSpan.getNewOpenLinkCallback(url), newText,
                  ClickableTextSpan.getStockStyle()));
            }
            else{
              final isMailTo = newText.contains('@') &&
                  !(newText.contains('https://') || newText.contains('http://'));

              spans.add(ClickableTextSpan.getNewClickableSpan(
                  ClickableTextSpan.getNewOpenLinkCallback(
                      isMailTo ? 'mailto:$newText' : newText.contains('www.') && !newText.contains('http:') ? 'https://$newText' : newText), newText,
                  ClickableTextSpan.getStockStyle()));
            }
          }
          else {
            // Handle URLs
            String url = matches[i];
            spans.add(ClickableTextSpan.getNewClickableSpan(
                ClickableTextSpan.getNewOpenLinkCallback(url), url,
                ClickableTextSpan.getStockStyle()));
          }
        }
      }

      return spans;
    }

    static void setupDaylightSavingsTime(){
      final now = DateTime.now();
      var probableSunday = DateTime(now.year, 3, 31, 0, 0, 0);
      if(probableSunday.weekday == 7){
        daylightSavingsTimeFrom = probableSunday;
      }
      else{
        daylightSavingsTimeFrom = probableSunday.subtract(Duration(days: probableSunday.weekday));
        if(daylightSavingsTimeFrom.hour != 0){
          daylightSavingsTimeFrom = DateTime(daylightSavingsTimeFrom.year, daylightSavingsTimeFrom.month, daylightSavingsTimeFrom.day + 1);
        }
      }

      probableSunday = DateTime(now.year, 10, 31, 0, 0, 0);
      if(probableSunday.weekday == 7){
        daylightSavingsTimeTo = probableSunday;
      }
      else{
        daylightSavingsTimeTo = probableSunday.subtract(Duration(days: probableSunday.weekday));
      }
    }

    static DateTime daylightSavingsTimeFrom = DateTime(DateTime.now().year, 3, 31, 0, 0, 0);
    static DateTime daylightSavingsTimeTo = DateTime(DateTime.now().year, 10, 27, 0, 0, 0);

    static bool isDaylightSavings(DateTime time){
      return (daylightSavingsTimeFrom.microsecondsSinceEpoch < time.microsecondsSinceEpoch && time.microsecondsSinceEpoch < daylightSavingsTimeTo.microsecondsSinceEpoch);
    }
    static Future<AppUpdateHelper?> getAppUpdateHelper() async{
      final url = Uri.parse('https://raw.githubusercontent.com/domedav/Neptun-2/main/appMinimumAllowedVersion.json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => Generic.getAppUpdateHelper() Error: Failed to fetch appMinimumAllowedVersion.json');
        return null;
      }

      Map<String, dynamic> jsonMap = conv.json.decode(response.body);
      return AppUpdateHelper(minAppVer: jsonMap["latestMinimumAllowedVerBuildNum"], minDisableVer: jsonMap["disableAppMinimumVersion"], updateUrl: jsonMap["updatePageJumper"]);
    }
  }

  class AppUpdateHelper{
    final int? minAppVer;
    final int? minDisableVer;
    final String? updateUrl;
    const AppUpdateHelper({required this.minAppVer, required this.minDisableVer, required this.updateUrl});
  }

  class Language{
    static Future<bool> checkSupportedUserLanguage()async{
      final deviceLang = Platform.localeName.split('_')[0].toLowerCase();
      // check language
      final allLang = await Language.getAllLanguages();
      return Language.getHasLanguageById(allLang, deviceLang);
    }

    static bool getHasLanguageById(List<LangPackMap>? languages, String neededId){
      if(languages == null){
        return false;
      }
      for(var item in languages){
        if(item.langId == neededId){
          return true;
        }
      }
      return false;
    }

    static Future<LanguagePack?> getLanguagePackById(List<LangPackMap>? languages, String neededID)async{
      if(languages == null){
        return null;
      }
      String? langUrl;
      for(var item in languages){
        if(item.langId == neededID){
          langUrl = item.langURL;
          break;
        }
      }
      if(langUrl == null){
        return null;
      }

      final url = Uri.parse(langUrl);
      final response = await http.get(url);
      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => Generic.getLanguagePackById() Error: Failed to fetch $langUrl $neededID');
        return null;
      }
      return LanguagePack.fromJson(neededID, response.body, (){}); // auto registers itself, as its downloaded, no need for the callback, def not invalid as it has just been downloaded
    }

    static List<LangPackMap>? _langMapCache;
    static List<LangPackMap> getAllLanguagesWithNative(){
      final nativeList = <LangPackMap>[
        LangPackMap(langName: 'Magyar', langId: 'hu', langURL: '', langFlag: '🇭🇺'),
        LangPackMap(langName: 'English', langId: 'en', langURL: '', langFlag: '🇺🇸/🇬🇧')];

      if(!DataCache.getHasNetwork()){
        return nativeList;
      }
      return nativeList + (_langMapCache == null ? <LangPackMap>[].toList() : _langMapCache!);
    }

    static Future<List<LangPackMap>?> getAllLanguages()async{
      if(_langMapCache != null){
        return _langMapCache;
      }
      final url = Uri.parse('https://raw.githubusercontent.com/domedav/Neptun-2/main/Languages/supportedLanguages.json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => Language.getUserLanguageFromServer() Error: Failed to fetch supportedLanguages.json');
        return null;
      }

      Map<String, dynamic> jsonMap = conv.json.decode(response.body);
      final allLangItems = jsonMap['languagesMap'] as List<dynamic>;
      final List<LangPackMap> langPacksRoot = [];
      for (var item in allLangItems){
        langPacksRoot.add(LangPackMap.fromMap(item));
      }
      _langMapCache = langPacksRoot;
      return langPacksRoot;
    }
  }

  class LangPackMap{
    final String langName;
    final String langFlag;
    final String langId;
    final String langURL;

    const LangPackMap({required this.langName, required this.langId, required this.langURL, required this.langFlag});

    static LangPackMap fromMap(Map<String, dynamic> json){
      return LangPackMap(langName: json['langName'], langId: json['langId'], langURL: json['langURL'], langFlag: json['langFlag']);
    }
  }

  class Coloring{
    static List<ThemePackMap>? _themeMapCache;

    static List<ThemePackMap>? getAllThemesCache(){
      return _themeMapCache;
    }

    static Future<List<ThemePackMap>?> getAllThemes()async{
      if(_themeMapCache != null){
        return _themeMapCache;
      }
      final url = Uri.parse('https://raw.githubusercontent.com/domedav/Neptun-2/main/Themes/supportedThemes.json');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => Coloring.getAllThemes() Error: Failed to fetch supportedThemes.json');
        return null;
      }

      Map<String, dynamic> jsonMap = conv.json.decode(response.body);
      final allThemeItems = jsonMap['themesMap'] as List<dynamic>;
      final List<ThemePackMap> themePacksRoot = [];
      for (var item in allThemeItems){
        themePacksRoot.add(ThemePackMap.fromMap(item));
      }
      _themeMapCache = themePacksRoot;
      return themePacksRoot;
    }

    static Future<AppPalette?> getThemePackById(List<ThemePackMap>? themes, String neededID)async{
      if(themes == null){
        return null;
      }
      String? themeUrl;
      for(var item in themes){
        if(item.themeName == neededID){
          themeUrl = item.themeUrl;
          break;
        }
      }
      if(themeUrl == null){
        return null;
      }

      final url = Uri.parse(themeUrl);
      final response = await http.get(url);
      if (response.statusCode != 200) {
        AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => Coloring.getThemePackById() Error: Failed to fetch $themeUrl $neededID');
        return null;
      }
      return AppPalette.fromJson(response.body, (){}); // auto registers itself, as its downloaded, no need for the callback, def not invalid as it has just been downloaded
    }
  }

  class ThemePackMap{
    final String themeName;
    final String themeUrl;
    final Color themepackAccent;

    const ThemePackMap({required this.themeName, required this.themeUrl, required this.themepackAccent});

    static ThemePackMap fromMap(Map<String, dynamic> json){
      return ThemePackMap(themeName: json['themeName'], themeUrl: json['themeURL'], themepackAccent: Color(json['themeAccent']));
    }
  }
  
  class NeptunCerts extends HttpOverrides {
    static NeptunCerts? _instance;
    static bool hasValidCertificate = true;
  
    static NeptunCerts getCerts(){
      if(_instance != null){
        return _instance!;
      }
      return NeptunCerts();
    }
  
    NeptunCerts(){
      _instance = this;
    }
    @override
    HttpClient createHttpClient(SecurityContext? context) {
      return super.createHttpClient(context)
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Ignoráljuk a tanúsítvány hibákat (Minden magyar egyetemet beengedünk)
          return true;
        };
    }
    // @override
    // HttpClient createHttpClient(SecurityContext? context) {
    //   return super.createHttpClient(context)
    //     ..badCertificateCallback = (X509Certificate cert, String host, int port) {
    //       final validCertSha1 = [165, 169, 244, 23, 233, 182, 23, 197, 14, 55, 39, 250, 69, 216, 89, 8, 179, 251, 103, 19];
    //       //debug.log(cert.sha1.toString());
    //       //debug.log(validCertSha1.toString());
    //       hasValidCertificate = cert.sha1.toString() == validCertSha1.toString(); // list comparison doesnt always work for some reason...
    //       if(!hasValidCertificate){
    //         AppAnalitics.sendAnaliticsData(AppAnalitics.ERROR, 'api_coms.dart => NeptunCerts.createHttpClient() Error: app found an invalid cert');
    //         AppAnalitics.sendAnaliticsData(AppAnalitics.INFO, 'api_coms.dart => NeptunCerts.createHttpClient() CERT: "' + cert.sha1.toString() + '" Needed: "' + validCertSha1.toString() + '"');
    //       }
    //       return hasValidCertificate;
    //     };
    // }
  }