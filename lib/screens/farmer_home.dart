import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/news_service.dart';
import 'news_page.dart';

class FarmerHome extends StatefulWidget {
  @override
  _FarmerHomeState createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  String weatherDescription = "Loading...";
  String temperature = "0°C";
  String icon = "🌤️";
  List<dynamic> newsHeadlines = [];
  String cropSuggestion = "Fetching...";

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadNews();
    _fetchLocationAndSuggestCrop();
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

  Future<void> _fetchLocationAndSuggestCrop() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permissions permanently denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String suggestedCrop = _getCropBasedOnLocation(position.latitude, position.longitude);
    setState(() {
      cropSuggestion = suggestedCrop;
    });
  }

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
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: () async {
                await _loadWeather();
                await _loadNews();
                await _fetchLocationAndSuggestCrop();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top section with weather and crop suggestion
                        Row(
                          children: [
                            Expanded(child: _buildWeatherCard()),
                            SizedBox(width: 12),
                            Expanded(child: _buildQuickCropSuggestion()),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Middle section with stats and tasks
                        Row(
                          children: [
                            Expanded(child: _buildFarmerStats()),
                            SizedBox(width: 12),
                            Expanded(child: _buildTodaysTasks()),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Bottom section with announcements
                        _buildAnnouncements(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToAllAnnouncementsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("All Announcements"),
            backgroundColor: Colors.green,
          ),
          body: ListView.builder(
            itemCount: newsHeadlines.length,
            itemBuilder: (context, index) {
              final article = newsHeadlines[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(article['title']),
                  subtitle: Text(article['description'] ?? "No description available"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsPage(newsUrl: article['url']),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
              image: DecorationImage(
                image: NetworkImage("https://via.placeholder.com/400x200"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.green.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.person, size: 40, color: Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  "Farmer Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.grass, "Crop Recommendation"),
          _drawerItem(Icons.healing, "Disease Detection"),
          _drawerItem(Icons.store, "Marketplace"),
          _drawerItem(Icons.language, "Multi-Language Support"),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade800),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        // Add navigation logic here in the future
      },
    );
  }

  Widget _buildWeatherCard() {
    return _dashboardCard(
      icon: "☀️",
      title: "Today's Weather",
      subtitle: "$temperature, $weatherDescription",
      iconColor: Colors.blue.shade200,
      iconBgColor: Colors.blue.shade100,
    );
  }

  Widget _buildQuickCropSuggestion() {
    return _dashboardCard(
      icon: "🌱",
      title: "Crop Suggestion",
      subtitle: "Best crop: $cropSuggestion",
      iconColor: Colors.green.shade200,
      iconBgColor: Colors.green.shade100,
    );
  }

  Widget _buildFarmerStats() {
    return _dashboardCard(
      icon: "📊",
      title: "Farmer Stats",
      subtitle: "Crops Sold: 120 | Pending: 5",
      iconColor: Colors.orange.shade200,
      iconBgColor: Colors.orange.shade100,
    );
  }

  Widget _buildTodaysTasks() {
    return _dashboardCard(
      icon: "✅",
      title: "Today's Tasks",
      subtitle: "Water crops, check soil",
      iconColor: Colors.purple.shade200,
      iconBgColor: Colors.purple.shade100,
    );
  }

  Widget _buildAnnouncements() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Announcements",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Divider(),
            if (newsHeadlines.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    "No announcements available",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: newsHeadlines.length > 3 ? 3 : newsHeadlines.length,
                itemBuilder: (context, index) {
                  final article = newsHeadlines[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        article['title'],
                        style: TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsPage(newsUrl: article['url']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            if (newsHeadlines.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.more_horiz),
                    label: Text("View All"),
                    onPressed: _navigateToAllAnnouncementsPage,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(icon, style: TextStyle(fontSize: 24)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    // Removed maxLines and overflow to ensure full text is visible
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
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