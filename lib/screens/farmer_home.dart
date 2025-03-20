import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import '../services/weather_service.dart';
import '../services/news_service.dart';

class FarmerHome extends StatefulWidget {
  @override
  _FarmerHomeState createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  String weatherDescription = "Loading...";
  String temperature = "0°C";
  String icon = "🌤️";
  List<dynamic> newsHeadlines = [];
  String cropSuggestion = "Fetching..."; // Location-based crop suggestion

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadNews();
    _fetchLocationAndSuggestCrop(); // Added function
  }

  Future<void> _loadWeather() async {
    WeatherService weatherService = WeatherService();
    try {
      Map<String, dynamic> weatherData = await weatherService.fetchWeather();
      setState(() {
        weatherDescription = weatherData['weather'][0]['description'];
        temperature = "${weatherData['main']['temp']}°C";
        icon = _getWeatherIcon(weatherData['weather'][0]['main']);
      });
    } catch (e) {
      print("❌ Error fetching weather: $e");
    }
  }

  Future<void> _loadNews() async {
    NewsService newsService = NewsService();
    List<dynamic> articles = await newsService.fetchNews();
    setState(() {
      newsHeadlines = articles;
    });
  }

  // 🔹 NEW FUNCTION: Fetch Location and Suggest Crop
  Future<void> _fetchLocationAndSuggestCrop() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permissions are permanently denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    print("📍 Location: Lat: ${position.latitude}, Lng: ${position.longitude}");

    // Hardcoded crop suggestions based on region (for now)
    String suggestedCrop =
    _getCropBasedOnLocation(position.latitude, position.longitude);

    setState(() {
      cropSuggestion = suggestedCrop;
    });
  }

  // 🔹 NEW FUNCTION: Crop Suggestion Based on Latitude
  String _getCropBasedOnLocation(double lat, double lon) {
    if (lat > 20.0) {
      return "🌾 Wheat";
    } else if (lat > 10.0) {
      return "🌽 Corn";
    } else {
      return "🍚 Rice";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Farmer Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherCard(),
            SizedBox(height: 10),
            _buildQuickCropSuggestion(),
            SizedBox(height: 10),
            _buildFarmerStats(),
            SizedBox(height: 10),
            _buildAnnouncements(),
            SizedBox(height: 10),
            _buildTodaysTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCropSuggestion() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.agriculture, color: Colors.green),
        title: Text("Quick Crop Suggestion"),
        subtitle: Text("🌱 Best crop to plant now: $cropSuggestion"),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Text(icon, style: TextStyle(fontSize: 24)),
        title: Text("Today's Weather"),
        subtitle: Text("$temperature, $weatherDescription"),
      ),
    );
  }

  Widget _buildFarmerStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.bar_chart, color: Colors.blue),
        title: Text("Farmer Statistics"),
        subtitle: Text("🌾 Crops Sold: 120  | 📦 Pending Orders: 5"),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        children: newsHeadlines.isEmpty
            ? [ListTile(title: Text("No announcements available"))]
            : newsHeadlines.take(5).map((article) {
          return ListTile(
            leading: Icon(Icons.campaign, color: Colors.red),
            title: Text(article['title']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text("Today's Tasks"),
        subtitle: Text("📝 Water the crops, Check soil condition"),
      ),
    );
  }

  String _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️'; // Default to partly cloudy
    }
  }

}
