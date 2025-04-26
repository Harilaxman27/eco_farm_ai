import 'package:eco_farm_ai/auth/login_screen.dart';
import 'package:eco_farm_ai/screens/broiler_tracking_page.dart';
import 'package:eco_farm_ai/screens/health_disease_page.dart';
import 'package:eco_farm_ai/screens/inventory_page.dart';
import 'package:eco_farm_ai/screens/marketplace_poultry.dart';
import 'package:flutter/material.dart';
import 'egg_production_page.dart';
import 'financials_poultry_page.dart';
import 'poultry_remainder_page.dart';
import 'package:eco_farm_ai/services/weather_service.dart';
import 'db_helper.dart';
import 'remainder_page.dart';
import 'reminder_db.dart'; // Add this import for ReminderDB


class PoultryFarmerHome extends StatefulWidget {
  const PoultryFarmerHome({Key? key}) : super(key: key);

  @override
  State<PoultryFarmerHome> createState() => _PoultryFarmerHomeState();
}

class _PoultryFarmerHomeState extends State<PoultryFarmerHome> {
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  int _totalEggs = 0;
  List<Reminder> _dynamicReminders = []; // Dynamic reminders list
  bool _isLoadingReminders = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadTotalEggs();
    _loadReminders(); // Load dynamic reminders from database
  }

  void _loadReminders() async {
    try {
      // Load reminders from the database
      final loadedReminders = await ReminderDB.instance.getAllReminders();
      setState(() {
        _dynamicReminders = loadedReminders;
        _isLoadingReminders = false;
      });
    } catch (e) {
      print('Error loading reminders: $e');
      setState(() {
        _isLoadingReminders = false;
      });
    }
  }

  void _loadTotalEggs() async {
    int total = await DBHelper.getTotalEggCount();
    setState(() {
      _totalEggs = total;
    });
  }

  void _loadWeather() async {
    final service = WeatherService();
    try {
      final data = await service.fetchWeather();
      setState(() {
        weatherData = data;
        isLoadingWeather = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoadingWeather = false;
      });
    }
  }

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      // Refresh reminders when returning from any page, particularly the reminders page
      _loadReminders();
      // Also refresh egg count when returning from egg production page
      if (page is EggProductionPage) {
        _loadTotalEggs();
      }
    });
  }

  void logout(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
  }

  // Keep the dummy reminders for fallback
  List<Map<String, String>> getDummyReminders() {
    return [
      {'title': 'Feed Chickens', 'time': '6:00 AM', 'description': 'Feed all chickens in the morning'},
      {'title': 'Egg Collection', 'time': '8:00 AM', 'description': 'Collect eggs from all coops'},
      {'title': 'Vaccinate Batch A', 'time': '2:00 PM', 'description': 'Scheduled vaccination for batch A'},
    ];
  }

  // Convert dynamic reminders to a format compatible with the UI
  List<Map<String, String>> getFormattedReminders() {
    if (_dynamicReminders.isEmpty) {
      return getDummyReminders(); // Use dummy data only if no dynamic reminders
    }

    return _dynamicReminders.map((reminder) {
      return {
        'title': reminder.title,
        'time': reminder.time.format(context),
        'description': reminder.description,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = getFormattedReminders(); // Get formatted reminders

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poultry Farm Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/farm_pattern.png'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Icon(Icons.person, size: 35, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Farmer\'s Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.green),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.egg_outlined, color: Colors.orange),
                title: const Text('Egg Production'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, const EggProductionPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined, color: Colors.blue),
                title: const Text('Broiler Tracking'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, BroilerTrackingPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined, color: Colors.red),
                title: const Text('Health & Disease'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, HealthAndDiseasePage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Colors.teal),
                title: const Text('Inventory'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, const InventoryPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm_outlined, color: Colors.indigo),
                title: const Text('Reminders'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, const RemindersPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.feed_outlined, color: Colors.brown),
                title: const Text('Financials'),
                onTap: () {
                  Navigator.pop(context);
                  navigateTo(context, const FinancialsPoultryPage());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text('Logout'),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Weather and Quick Stats Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather
                    isLoadingWeather
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : weatherData != null
                        ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            'http://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png',
                            width: 50,
                            height: 50,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${weatherData!['name']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${weatherData!['main']['temp']}°C • ${weatherData!['weather'][0]['description']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : const Text('Weather data unavailable'),

                    const Divider(height: 24),

                    // Quick Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          context,
                          Icons.egg,
                          _totalEggs.toString(),
                          'Today\'s Eggs',
                          Colors.orange,
                        ),
                        _buildQuickStat(
                          context,
                          Icons.monitor_weight,
                          '1.5 kg',
                          'Avg. Weight',
                          Colors.blue,
                        ),
                        _buildQuickStat(
                          context,
                          Icons.sick,
                          '2',
                          'Health Alerts',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Today's Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Tasks",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                  onPressed: () => navigateTo(context, const RemindersPage()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: _isLoadingReminders
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
                  : reminders.isNotEmpty
                  ? ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTaskColor(reminder['title'] ?? ''),
                      child: Icon(
                        _getTaskIcon(reminder['title'] ?? ''),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      reminder['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: reminder['description'] != null ? Text(
                      reminder['description']!,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ) : null,
                    trailing: Text(
                      reminder['time'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              )
                  : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No tasks for today."),
              ),
            ),

            const SizedBox(height: 20),

            // Main Features Grid
            Text(
              "Farm Management",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0, // Changed to 1.0 for perfect squares
              children: [
                _buildFeatureCard(
                  context,
                  Icons.egg_outlined,
                  "Egg Production",
                  Colors.orange,
                      () => navigateTo(context, const EggProductionPage()),
                ),
                _buildFeatureCard(
                  context,
                  Icons.monitor_weight_outlined,
                  "Broiler Tracking",
                  Colors.blue,
                      () => navigateTo(context, BroilerTrackingPage()),
                ),
                _buildFeatureCard(
                  context,
                  Icons.health_and_safety_outlined,
                  "Health Management",
                  Colors.red,
                      () => navigateTo(context, HealthAndDiseasePage()),
                ),
                _buildFeatureCard(
                  context,
                  Icons.inventory_2_outlined,
                  "Inventory",
                  Colors.teal,
                      () => navigateTo(context, const InventoryPage()),
                ),
                _buildFeatureCard(
                  context,
                  Icons.store_outlined,
                  "Marketplace",
                  Colors.purple,
                      () => navigateTo(context,  PoultryMarketplaceScreen()),
                ),
                _buildFeatureCard(
                  context,
                  Icons.feed_outlined,
                  "Financials",
                  Colors.brown,
                      () => navigateTo(context, const FinancialsPoultryPage()),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: () {
          navigateTo(context, const RemindersPage());
        },
        child: const Icon(Icons.add_alarm, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity, // Ensure full width
          height: double.infinity, // Ensure full height
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTaskColor(String title) {
    if (title.contains('Feed')) return Colors.orange;
    if (title.contains('Egg')) return Colors.amber;
    if (title.contains('Vaccinate')) return Colors.red;
    if (title.contains('Clean')) return Colors.blue;
    return Colors.green;
  }

  IconData _getTaskIcon(String title) {
    if (title.contains('Feed')) return Icons.restaurant;
    if (title.contains('Egg')) return Icons.egg;
    if (title.contains('Vaccinate')) return Icons.vaccines;
    if (title.contains('Clean')) return Icons.cleaning_services;
    return Icons.check_circle;
  }
}