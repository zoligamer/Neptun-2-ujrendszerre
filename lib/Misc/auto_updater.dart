import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage.dart'; // A getInt és saveInt miatt kell
import '../colors.dart';

class AppUpdater {
  static const String repoOwner = "zoligamer";
  static const String repoName = "Neptun-Mobile-fork";

  /// Fő belépési pont. Ezt hívd meg a main_page initState-jében!
  static Future<void> checkAndInstallUpdate(BuildContext context) async {
    // 1. Internet ellenőrzés
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      return;
    }

    // 2. 24 órás Cache ellenőrzés (csak naponta egyszer nézzük meg)
    final cacheTime = await getInt('ObsoleteAppVerUpdateCacheTime') ?? -1;
    if ((DateTime.now().millisecondsSinceEpoch - cacheTime) < const Duration(hours: 24).inMilliseconds) {
      return; // Még nem telt el 24 óra, nem csinálunk semmit
    }

    try {
      // 3. GitHub API hívás a 'latest' kiadásért
      final response = await http.get(Uri.parse("https://api.github.com/repos/$repoOwner/$repoName/releases/latest"));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final latestTag = data['tag_name'].toString(); // Pl: Release_v1.0.2
      final latestVersionClean = latestTag.replaceAll(RegExp(r'[^0-9.]'), ''); // Kiszűrjük a szöveget: 1.0.2

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Elmentjük a sikeres ellenőrzés idejét
      await saveInt('ObsoleteAppVerUpdateCacheTime', DateTime.now().millisecondsSinceEpoch);

      // 4. Verzió összehasonlítás
      if (latestVersionClean != currentVersion) {
        if (!context.mounted) return;

        bool shouldUpdate = await _showUpdateDialog(context, latestVersionClean);
        if (shouldUpdate) {
          await _downloadAndInstall(context, data['assets']);
        }
      }
    } catch (e) {
      debugPrint("Hiba az auto-update során: $e");
    }
  }

  /// Egyszerű Igen / Később ablak
  static Future<bool> _showUpdateDialog(BuildContext context, String version) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getTheme().rootBackground,
        title: Text("Frissítés elérhető!", style: TextStyle(color: AppColors.getTheme().textColor, fontWeight: FontWeight.bold)),
        content: Text("Az alkalmazás új verziója (v$version) letölthető. Szeretnéd most telepíteni?", style: TextStyle(color: AppColors.getTheme().textColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Később", style: TextStyle(color: AppColors.getTheme().textColor.withValues(alpha: 0.6)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getTheme().currentClassGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Igen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Letöltés sávval és automatikus megnyitás
  static Future<void> _downloadAndInstall(BuildContext context, List assets) async {
    // 1. Architektúra detektálása (ARM7 vs ARM8)
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    bool isArm64 = androidInfo.supported64BitAbis.isNotEmpty;
    String archKeyword = isArm64 ? "ARM8" : "ARM7";

    // 2. Megfelelő APK kiválasztása a GitHub assets listából
    var asset;
    try {
      asset = assets.firstWhere((a) => a['name'].toString().contains(archKeyword) && a['name'].toString().endsWith('.apk'));
    } catch (e) {
      debugPrint("Nem található megfelelő APK ehhez az architektúrához: $archKeyword");
      return;
    }

    final downloadUrl = asset['browser_download_url'];
    final tempDir = await getTemporaryDirectory();
    final savePath = "${tempDir.path}/Neptun_Update.apk";

    // Takarítás: töröljük a régi telepítőt
    if (File(savePath).existsSync()) {
      File(savePath).deleteSync();
    }

    if (!context.mounted) return;

    // 3. Letöltés folyamatjelzővel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DownloadProgressDialog(),
    );

    try {
      final dio = Dio();
      await dio.download(downloadUrl, savePath);

      if (!context.mounted) return;
      Navigator.pop(context); // Töltés ablak bezárása

      // 4. Telepítés indítása
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        debugPrint("Hiba az APK megnyitásakor: ${result.message}");
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      debugPrint("Hálózati hiba a letöltés során: $e");
    }
  }
}

/// Belső Widget a letöltési folyamatjelzőhöz
class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.getTheme().rootBackground,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.getTheme().currentClassGreen),
          const SizedBox(height: 20),
          Text("Frissítés letöltése folyamatban...", style: TextStyle(color: AppColors.getTheme().textColor)),
          const SizedBox(height: 10),
          Text("Kérlek, ne zárd be az alkalmazást.", style: TextStyle(color: AppColors.getTheme().textColor.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
}