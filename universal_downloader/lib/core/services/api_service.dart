import 'package:dio/dio.dart';
import '../models/media_info_model.dart';

/// API Service for communicating with the Railway backend.
/// The backend uses yt-dlp to extract direct media CDN links.
class ApiService {
  late final Dio _dio;

  // ⚠️ Replace this with your Railway deployment URL
  static const String _baseUrl = 'https://jafardown-scraper-backend.up.railway.app'; // تحديث بعد النشر

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2), // Long timeout for large video info
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Log requests in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false, // too verbose for large format lists
      error: true,
    ));
  }

  /// Extracts metadata and direct download URLs from a given social media URL.
  /// Throws an [Exception] on network or server error.
  Future<MediaInfoModel> extractMedia(String url) async {
    try {
      final response = await _dio.post('/api/extract', data: {'url': url});
      return MediaInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final error = e.response!.data?['error'] ?? 'خطأ غير معروف من السيرفر';
        throw Exception(error);
      }
      throw Exception('فشل الاتصال بالسيرفر. تحقق من الإنترنت.');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}
