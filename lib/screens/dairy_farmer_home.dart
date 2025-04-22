import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_cow_screen.dart';
import 'alerts_reminders.dart';
import 'cow_milking_tracker.dart';
import 'milk_product_advisor.dart';
import 'health_breeding_management.dart';
import 'marketplace_screen.dart';
import '../services/weather_service.dart';
import '../auth/login_screen.dart';

class DairyFarmerHome extends StatefulWidget {
  const DairyFarmerHome({super.key});

  @override
  State<DairyFarmerHome> createState() => _DairyFarmerHomeState();
}


class _DairyFarmerHomeState extends State<DairyFarmerHome> {
  final String farmerName = "Pranay";
  final String todayDate = _getTodayDate(); // Using a custom function instead of intl
  final WeatherService _weatherService = WeatherService();

  // Weather data state
  bool _isLoadingWeather = true;
  String _temperature = "-- °C";
  String _weatherCondition = "";

  // Example data for mini chart
  final List<double> weeklyMilkData = [22.5, 24.0, 23.5, 25.0, 26.5, 27.0, 26.0];

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final weatherData = await _weatherService.fetchWeather();

      if (mounted) {
        setState(() {
          // Extract temperature and round to nearest integer
          final temp = weatherData['main']['temp'];
          _temperature = "${temp.round()}°C";

          // Extract weather condition
          _weatherCondition = weatherData['weather'][0]['main'];

          // Extract location name

          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _temperature = "-- °C";
          _weatherCondition = "Error";
          _isLoadingWeather = false;
        });
        print("Error fetching weather: $e");
      }
    }
  }

  // Custom function to get today's date as a string without using intl package
  static String _getTodayDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final dayName = days[now.weekday - 1]; // weekday ranges from 1-7
    final day = now.day;
    final month = months[now.month - 1]; // month ranges from 1-12

    return '$dayName, $day $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'KisanDairy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlertsReminders()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildDashboard(),
            _buildStatCards(),
            _buildQuickActions(),
            _buildTasks(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddCowScreen())
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Cow',
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.green.shade700),
            accountName: const Text(
              'Pranay Kumar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Pranay@gmail.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green.shade700, size: 40),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: "Home",
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.add_circle,
            title: "Add Cow",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddCowScreen())
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.opacity,
            title: "Milking Tracker",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CowMilkingTracker())
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.healing,
            title: "Health & Breeding",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HealthBreedingManagement())
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: "MilkProductAdvisor",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MilkProductAdvisor())
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.alarm,
            title: "Reminders",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlertsReminders())
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.storefront,
            title: "Marketplace",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MarketplaceScreen())
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: "Logout",
            textColor: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Function onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: () => onTap(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $farmerName 👨‍🌾',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade100,
                    ),
                  ),
                ],
              ),
              _buildWeatherWidget(),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_drink, color: Colors.orange.shade700, size: 24),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Total Milk",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '26.5 L',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.green.shade700, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '4%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  width: 100,
                  child: _buildMiniChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    // Choose weather icon based on condition
    IconData weatherIcon = Icons.wb_sunny;
    if (_weatherCondition.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud;
    } else if (_weatherCondition.toLowerCase().contains('rain')) {
      weatherIcon = Icons.beach_access; // Using umbrella icon for rain
    } else if (_weatherCondition.toLowerCase().contains('snow')) {
      weatherIcon = Icons.ac_unit;
    } else if (_weatherCondition.toLowerCase().contains('thunderstorm')) {
      weatherIcon = Icons.flash_on;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _isLoadingWeather
          ? const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Row(
        children: [
          Icon(weatherIcon,
              color: _weatherCondition.toLowerCase().contains('cloud')
                  ? Colors.white
                  : Colors.yellow.shade300,
              size: 16),
          const SizedBox(width: 4),
          Text(
            _temperature,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See More',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDashboardItem(
                icon: Icons.local_drink,
                label: 'Milk Today',
                value: '26.5L',
                color: Colors.blue,
              ),
              _buildDashboardItem(
                icon: Icons.attach_money,
                label: 'Income',
                value: '₹750',
                color: Colors.green,
              ),
              _buildDashboardItem(
                icon: Icons.grass,
                label: 'Feed Used',
                value: '45kg',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Cows: 6',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Milk Average: 4.4L',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    return CustomPaint(
      painter: _ChartPainter(weeklyMilkData),
      size: const Size(100, 40),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farm Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  bgColor: Colors.green.shade50,
                  title: "Today's Income",
                  value: "₹750",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pets,
                  iconColor: Colors.purple,
                  bgColor: Colors.purple.shade50,
                  title: "Total Cows",
                  value: "6",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.medical_services,
                  iconColor: Colors.red,
                  bgColor: Colors.red.shade50,
                  title: "Health Alerts",
                  value: "1",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pregnant_woman,
                  iconColor: Colors.blue,
                  bgColor: Colors.blue.shade50,
                  title: "Pregnant",
                  value: "2",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _quickTile(context, "Add\nCow", Icons.add_circle, AddCowScreen(), Colors.teal),
              _quickTile(context, "Milking\nTracker", Icons.opacity, CowMilkingTracker(), Colors.blue),
              _quickTile(context, "Health &\nBreeding", Icons.healing, HealthBreedingManagement(), Colors.red),
              _quickTile(context, "MilkProductAdvisor", Icons.bar_chart, MilkProductAdvisor(), Colors.green),
              _quickTile(context, "Reminders", Icons.alarm, AlertsReminders(), Colors.amber),
              _quickTile(context, "Marketplace", Icons.storefront, MarketplaceScreen(), Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasks() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTaskItem(
            title: 'Morning Milking',
            time: '6:00 AM',
            isDone: true,
          ),
          _buildTaskItem(
            title: 'Feed Distribution',
            time: '9:00 AM',
            isDone: true,
          ),
          _buildTaskItem(
            title: 'Medical Check - Cow #3',
            time: '2:00 PM',
            isDone: false,
          ),
          _buildTaskItem(
            title: 'Evening Milking',
            time: '5:00 PM',
            isDone: false,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlertsReminders()),
                );
              },
              icon: Icon(Icons.add, color: Colors.green.shade700, size: 18),
              label: Text(
                'Add New Task',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String time,
    required bool isDone,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green.shade100
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : Icons.access_time,
            color: isDone ? Colors.green.shade700 : Colors.grey.shade700,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isDone ? Icons.refresh : Icons.check_circle_outline,
            color: Colors.green.shade700,
          ),
          onPressed: () {
            // Toggle task status
          },
        ),
      ),
    );
  }

  Widget _quickTile(BuildContext context, String label, IconData icon, Widget page, Color color) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for mini chart
class _ChartPainter extends CustomPainter {
  final List<double> dataPoints;

  _ChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min and max values for scaling
    final double maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final double minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue;

    // Start path
    final double dx = size.width / (dataPoints.length - 1);
    path.moveTo(0, size.height - ((dataPoints[0] - minValue) / range * size.height));

    // Draw line segments
    for (int i = 1; i < dataPoints.length; i++) {
      final double x = dx * i;
      final double y = size.height - ((dataPoints[i] - minValue) / range * size.height);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw area under the chart
    final fillPaint = Paint()
      ..color = Colors.green.shade200.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}