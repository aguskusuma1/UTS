import 'package:dio/dio.dart';
import '../models/news_model.dart';

class NewsService {
  late Dio _dio;
  
  // Menggunakan NewsAPI.org - gratis untuk development
  // Anda bisa menggunakan API key sendiri atau menggunakan endpoint publik
  static const String baseUrl = 'https://newsapi.org/v2';
  static const String apiKey = 'YOUR_API_KEY'; // Ganti dengan API key Anda jika ada
  // Atau gunakan endpoint publik untuk testing
  static const String country = 'id'; // Indonesia
  static const String category = 'technology'; // Kategori teknologi/elektro

  NewsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          if (apiKey != 'YOUR_API_KEY') 'X-Api-Key': apiKey,
        },
      ),
    );
  }

  // Fetch news dari API
  Future<List<NewsModel>> fetchNews() async {
    try {
      // Menggunakan endpoint top headlines
      // Jika tidak ada API key, bisa menggunakan endpoint alternatif atau mock data
      final response = await _dio.get(
        '/top-headlines',
        queryParameters: {
          'country': country,
          'category': category,
          'pageSize': 20,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        final newsResponse = NewsResponse.fromJson(response.data);
        return newsResponse.articles
            .where((article) => article.title != null && article.title!.isNotEmpty)
            .toList();
      } else {
        // Jika API key tidak valid atau limit, gunakan mock data
        return _getMockNews();
      }
    } catch (e) {
      print('Error fetching news: $e');
      // Return mock data jika ada error
      return _getMockNews();
    }
  }

  // Mock data untuk testing jika API tidak tersedia
  List<NewsModel> _getMockNews() {
    return [
      NewsModel(
        title: 'PLN Targetkan Penambahan Kapasitas Listrik 5.000 MW Tahun Ini',
        description:
            'PLN berencana menambah kapasitas listrik sebesar 5.000 MW di tahun 2024 untuk memenuhi kebutuhan listrik nasional.',
        url: 'https://example.com/news/1',
        urlToImage: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800',
        publishedAt: DateTime.now().toIso8601String(),
        author: 'Kompas',
        content:
            'PT PLN (Persero) menargetkan penambahan kapasitas listrik sebesar 5.000 MW pada tahun 2024. Penambahan ini dilakukan untuk memenuhi kebutuhan listrik nasional yang terus meningkat.',
        source: Source(name: 'Kompas'),
      ),
      NewsModel(
        title: 'Teknologi Smart Grid untuk Efisiensi Distribusi Listrik',
        description:
            'Implementasi teknologi smart grid diharapkan dapat meningkatkan efisiensi distribusi listrik dan mengurangi rugi-rugi transmisi.',
        url: 'https://example.com/news/2',
        urlToImage: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=800',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        author: 'Kontan',
        content:
            'Teknologi smart grid menjadi solusi untuk meningkatkan efisiensi distribusi listrik. Dengan teknologi ini, sistem dapat mengoptimalkan distribusi daya secara otomatis.',
        source: Source(name: 'Kontan'),
      ),
      NewsModel(
        title: 'Kalkulasi Drop Tegangan pada Jaringan Tegangan Rendah',
        description:
            'Panduan lengkap mengenai perhitungan drop tegangan pada jaringan tegangan rendah untuk memastikan kualitas daya yang baik.',
        url: 'https://example.com/news/3',
        urlToImage: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        author: 'Tekno',
        content:
            'Drop tegangan adalah penurunan tegangan yang terjadi pada saluran transmisi atau distribusi listrik. Perhitungan yang tepat sangat penting untuk menjaga kualitas daya.',
        source: Source(name: 'Tekno'),
      ),
      NewsModel(
        title: 'Efisiensi Energi dengan Penggunaan Inverter Modern',
        description:
            'Inverter modern dapat meningkatkan efisiensi energi hingga 95% dibandingkan teknologi konvensional.',
        url: 'https://example.com/news/4',
        urlToImage: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        author: 'Bisnis',
        content:
            'Teknologi inverter modern menawarkan efisiensi energi yang lebih tinggi. Teknologi ini menggunakan switching frequency yang lebih tinggi untuk mengurangi rugi-rugi.',
        source: Source(name: 'Bisnis'),
      ),
      NewsModel(
        title: 'Pengembangan Jaringan Listrik di Daerah Terpencil',
        description:
            'Pemerintah fokus pada pengembangan jaringan listrik di daerah terpencil untuk meningkatkan rasio elektrifikasi nasional.',
        url: 'https://example.com/news/5',
        urlToImage: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        author: 'Investor',
        content:
            'Program pengembangan jaringan listrik di daerah terpencil terus dilakukan untuk mencapai target rasio elektrifikasi 100%.',
        source: Source(name: 'Investor'),
      ),
    ];
  }
}

