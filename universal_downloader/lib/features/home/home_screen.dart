import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../downloads/downloads_screen.dart';
import '../library/library_screen.dart';
import '../platform_page/platform_page.dart';
import 'widgets/quality_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _urlController = TextEditingController();
  final _apiService = ApiService();
  StreamSubscription? _shareSub;
  bool _loading = false;

  final List<_PlatformInfo> _platforms = [
    _PlatformInfo('يوتيوب', 'YouTube', AppTheme.youtubeColor, Icons.play_circle_fill),
    _PlatformInfo('إنستغرام', 'Instagram', AppTheme.instagramColor, Icons.camera_alt),
    _PlatformInfo('تيك توك', 'TikTok', AppTheme.tiktokColor, Icons.music_video),
    _PlatformInfo('فيسبوك', 'Facebook', AppTheme.facebookColor, Icons.facebook),
    _PlatformInfo('تويتر', 'Twitter', AppTheme.twitterColor, Icons.alternate_email),
    _PlatformInfo('بينتريست', 'Pinterest', AppTheme.pinterestColor, Icons.push_pin),
    _PlatformInfo('سناب شات', 'Snapchat', AppTheme.snapchatColor, Icons.circle),
    _PlatformInfo('تيليغرام', 'Telegram', AppTheme.telegramColor, Icons.send),
  ];

  @override
  void initState() {
    super.initState();
    _listenToShareIntent();
  }

  void _listenToShareIntent() {
    _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen((list) {
      final text = list.firstOrNull?.path;
      if (text != null && text.startsWith('http')) {
        _urlController.text = text;
        _processUrl(text);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((list) {
      final text = list.firstOrNull?.path;
      if (text != null && text.startsWith('http')) {
        _urlController.text = text;
        _processUrl(text);
      }
    });
  }

  Future<void> _processUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _loading = true);
    try {
      final info = await _apiService.extractMedia(url.trim());
      if (!mounted) return;
      await showQualityDialog(context, info);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'خطأ',
        e.toString().replaceAll('Exception:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(
        urlController: _urlController,
        loading: _loading,
        platforms: _platforms,
        onProcess: _processUrl,
      ),
      const DownloadsScreen(),
      const LibraryScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.download_rounded), label: 'التنزيلات'),
            BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'مكتبتي'),
          ],
        ),
      ),
    );
  }
}

// ────────────── Home Tab ──────────────

class _HomeTab extends StatelessWidget {
  final TextEditingController urlController;
  final bool loading;
  final List<_PlatformInfo> platforms;
  final void Function(String) onProcess;

  const _HomeTab({
    required this.urlController,
    required this.loading,
    required this.platforms,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                'JafarDown',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent])
                        .createShader(const Rect.fromLTWH(0, 0, 180, 36)),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A35), Color(0xFF0F0F1A)],
                  ),
                ),
              ),
            ),
          ),

          // URL input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الصق رابط للتنزيل',
                      style: GoogleFonts.tajawal(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          style: GoogleFonts.tajawal(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.link_rounded, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: loading ? null : () => onProcess(urlController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(52, 52),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.download_rounded,
                                color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.surfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('أو اختر منصة',
                        style: GoogleFonts.tajawal(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: AppTheme.surfaceVariant)),
                ],
              ),
            ),
          ),

          // Platform grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PlatformCard(info: platforms[i]),
                childCount: platforms.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ────────────── Platform Card ──────────────

class _PlatformCard extends StatelessWidget {
  final _PlatformInfo info;
  const _PlatformCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PlatformPage(platform: info)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              info.color.withValues(alpha: 0.3),
              info.color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
              color: info.color.withValues(alpha: 0.25), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.arabicName,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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

// ────────────── Platform Info ──────────────

class _PlatformInfo {
  final String arabicName;
  final String englishName;
  final Color color;
  final IconData icon;
  const _PlatformInfo(this.arabicName, this.englishName, this.color, this.icon);
}
