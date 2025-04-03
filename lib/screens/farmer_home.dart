import 'package:eco_farm_ai/screens/crop_recommendation.dart';
import 'package:eco_farm_ai/screens/marketplace.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/news_service.dart';
import 'disease_detection_screen.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Farmer Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.green.withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: "Notifications",
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () async {
                  await _loadWeather();
                  await _loadNews();
                  await _fetchLocationAndSuggestCrop();
                },
                color: Colors.green,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(),
                          SizedBox(height: 16),

                          // Quick actions
                          _buildQuickActions(),
                          SizedBox(height: 20),

                          // Weather and crop suggestion
                          _buildWeatherAndCropSection(),
                          SizedBox(height: 20),

                          // Farmer stats
                          _buildFarmerStatsSection(),
                          SizedBox(height: 20),

                          // Announcements section
                          _buildAnnouncementsSection(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final now = DateTime.now();
    String greeting = "Good morning";
    if (now.hour >= 12 && now.hour < 17) {
      greeting = "Good afternoon";
    } else if (now.hour >= 17) {
      greeting = "Good evening";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          Text(
            "Here's what's happening on your farm today",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.grass,
              label: "Crop\nRecommendation",
              color: Colors.green.shade600,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CropRecommendationScreen()));
              },
            ),
            _buildActionButton(
              icon: Icons.bug_report,
              label: "Disease\nDetection",
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CropDiseaseDetectionScreen()));
              },
            ),
            _buildActionButton(
              icon: Icons.store,
              label: "Market\nplace",
              color: Colors.blue.shade600,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen()));
              },
            ),
            _buildActionButton(
              icon: Icons.language,
              label: "Multi\nLauguage",
              color: Colors.purple.shade600,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAndCropSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: TextStyle(fontSize: 36),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temperature,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weatherDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.3), height: 24),
            Row(
              children: [
                Icon(Icons.eco, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Recommended Crop:",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  cropSuggestion.split(" ").last,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Farm Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildFarmerStats()),
            SizedBox(width: 12),
            Expanded(child: _buildTodaysTasks()),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Announcements",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (newsHeadlines.length > 3)
                TextButton(
                  onPressed: _navigateToAllAnnouncementsPage,
                  child: Text(
                    "View All",
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
            ],
          ),
        ),
        _buildAnnouncements(),
      ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(
                    article['title'],
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      article['description'] ?? "No description available",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade500, Colors.green.shade700],
              ),
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
                SizedBox(height: 12),
                Text(
                  "Farmer Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Manage your farm efficiently",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.grass,
            title: "AI Crop Recommendation",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CropRecommendationScreen()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.bug_report,
            title: "Crop Disease Detection",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CropDiseaseDetectionScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.store,
            title: "Market Place",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MarketplaceScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.language,
            title: "Multi-Language Support",
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: "Logout",
            textColor: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.green.shade800,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      dense: true,
    );
  }

  Widget _buildFarmerStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Harvest Stats",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  label: "Crops Sold",
                  value: "120",
                  color: Colors.green,
                ),
                _buildStatItem(
                  label: "Pending",
                  value: "5",
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysTasks() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.purple.shade700,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTaskItem("Water crops", true),
            _buildTaskItem("Check soil condition", false),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String task, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: completed ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 8),
          Expanded( // Add this Expanded widget
            child: Text(
              task,
              style: TextStyle(
                fontSize: 14,
                color: completed ? Colors.grey : Colors.black87,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis, // Add this to handle overflow
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newsHeadlines.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No announcements available",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
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
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article,
                          color: Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        article['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 14),
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