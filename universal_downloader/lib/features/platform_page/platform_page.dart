import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/widgets/quality_dialog.dart';

/// A dedicated page for one platform, with URL input and a brief description of supported content.
class PlatformPage extends StatefulWidget {
  final dynamic platform; // _PlatformInfo from home_screen
  const PlatformPage({super.key, required this.platform});

  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  final _controller = TextEditingController();
  final _api = ApiService();
  bool _loading = false;

  Future<void> _process() async {
    if (_controller.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final info = await _api.extractMedia(_controller.text.trim());
      if (!mounted) return;
      await showQualityDialog(context, info);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception:', '').trim(),
            style: GoogleFonts.tajawal()),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, List<String>> get _supportedContent {
    switch (widget.platform.englishName as String) {
      case 'YouTube': return {'يوتيوب': ['فيديوهات', 'قصيرات (Shorts)', 'بث مباشر', 'صوت فقط (MP3)']};
      case 'Instagram': return {'إنستغرام': ['ريلز', 'منشورات', 'قصص عامة', 'صور الملف الشخصي']};
      case 'TikTok': return {'تيك توك': ['فيديوهات بدون علامة مائية', 'صوت فقط']};
      case 'Facebook': return {'فيسبوك': ['فيديوهات', 'ريلز', 'صفحات عامة']};
      case 'Twitter': return {'تويتر': ['فيديوهات', 'GIF المتحركة']};
      case 'Pinterest': return {'بينتريست': ['فيديوهات', 'صور']};
      case 'Snapchat': return {'سناب شات': ['محتوى عام فقط']};
      case 'Telegram': return {'تيليغرام': ['وسائط من روابط عامة']};
      default: return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.platform;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.arabicName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          leading: const BackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform hero header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [(p.color as Color).withOpacity(0.3), (p.color as Color).withOpacity(0.05)],
                  ),
                  border: Border.all(color: (p.color as Color).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (p.color as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(p.icon, color: p.color, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.arabicName,
                      style: GoogleFonts.tajawal(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // URL input
              Text('الصق رابط ${p.arabicName}', style: GoogleFonts.tajawal(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.tajawal(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link_rounded, color: p.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading ? null : _process,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.color,
                      minimumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download_rounded, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Supported content list
              Text(
                'المحتوى المدعوم',
                style: GoogleFonts.tajawal(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...(_supportedContent.values.firstOrNull ?? []).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: p.color, size: 18),
                      const SizedBox(width: 10),
                      Text(item, style: GoogleFonts.tajawal(fontSize: 15, color: AppTheme.textPrimary)),
                    ],
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
