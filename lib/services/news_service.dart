import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String apiKey = "0f17bcd6d101426599e524f89c7426ea"; // 🔥 Replace with your NewsAPI key
  static const String apiUrl =
      "https://newsapi.org/v2/everything?q=farmer&language=en&apiKey=0f17bcd6d101426599e524f89c7426ea";

  Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['articles']; // Returns a list of news articles
      } else {
        throw Exception("Failed to load news");
      }
    } catch (e) {
      print("❌ Error fetching news: $e");
      return [];
    }
  }
}
