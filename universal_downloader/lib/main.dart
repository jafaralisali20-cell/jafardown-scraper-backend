import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/download_item.dart';
import 'core/services/download_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DownloadItemAdapter());

  Get.put(DownloadManager());

  runApp(const JafarDownApp());
}

class JafarDownApp extends StatelessWidget {
  const JafarDownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JafarDown',
      locale: const Locale('ar', 'IQ'),
      textDirection: TextDirection.rtl,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
