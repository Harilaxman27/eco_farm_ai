import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropRecommendationScreen extends StatefulWidget {
  @override
  _CropRecommendationScreenState createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final TextEditingController landSizeController = TextEditingController();
  String selectedSoilType = "Sandy";
  double? temperature;
  String season = "Fetching...";
  bool isLoading = false;
  List<String> recommendedCrops = [];
  String errorMessage = "";

  final List<String> soilTypes = ["Sandy", "Clay", "Loamy", "Silt", "Peat"];

  // Map soil types to colors for visual representation
  final Map<String, Color> soilColors = {
    "Sandy": Color(0xFFE0C68C),
    "Clay": Color(0xFFB97A57),
    "Loamy": Color(0xFF8B5A2B),
    "Silt": Color(0xFFD4C19C),
    "Peat": Color(0xFF3D2817),
  };

  // Map seasons to images/icons
  final Map<String, IconData> seasonIcons = {
    "Spring": Icons.local_florist,
    "Summer": Icons.wb_sunny,
    "Autumn": Icons.eco,
    "Winter": Icons.ac_unit,
  };

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndSeason();
  }

  Future<void> _fetchWeatherAndSeason() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    try {
      Position position = await _determinePosition();
      double lat = position.latitude;
      double lon = position.longitude;

      double temp = await _fetchTemperature(lat, lon);
      setState(() {
        temperature = temp;
        season = _determineSeason();
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
      });
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw "Location services are disabled.";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw "Location permissions are permanently denied.";
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<double> _fetchTemperature(double lat, double lon) async {
    String apiKey = "d4d1286331ed1a9550630ad14674eba9";
    String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['main']['temp'].toDouble();
    } else {
      throw "Failed to load weather data: ${response.statusCode}";
    }
  }

  String _determineSeason() {
    int month = DateTime.now().month;
    if (month >= 3 && month <= 5) return "Spring";
    if (month >= 6 && month <= 8) return "Summer";
    if (month >= 9 && month <= 11) return "Autumn";
    return "Winter";
  }

  Future<void> _getCropRecommendations() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
      recommendedCrops = [];
    });

    try {
      String apiKey = "AIzaSyAQ2YmmqHCYG9rAP9ub5HWjNCQQ4WfQfUQ";
      String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

      if (temperature == null) {
        throw "Temperature data not available. Please wait for weather data to load.";
      }

      String prompt =
          "Suggest the best crops to grow based on the following conditions:\n"
          "- Soil Type: $selectedSoilType\n"
          "- Temperature: ${temperature?.toStringAsFixed(1)}°C\n"
          "- Season: $season\n"
          "Format your response as a numbered list with only crop names, one per line (no descriptions).";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> crops = _extractCropList(data);

        if (crops.isEmpty) {
          throw "Could not parse crop recommendations from the API response";
        }

        setState(() {
          recommendedCrops = crops;
        });
      } else {
        throw "Failed to fetch crop recommendations: ${response.statusCode}\nResponse: ${response.body}";
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      print("Error getting crop recommendations: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<String> _extractCropList(Map<String, dynamic> data) {
    try {
      String responseText = data['candidates'][0]['content']['parts'][0]['text'];
      print("Raw response text: $responseText");

      List<String> lines = responseText.split("\n");

      List<String> crops = [];
      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        RegExp numberedListRegex = RegExp(r'^\d+\.\s*');
        String cleaned = line.replaceFirst(numberedListRegex, '').trim();

        cleaned = cleaned.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim();

        if (cleaned.isNotEmpty) {
          crops.add(cleaned);
        }
      }

      print("Extracted ${crops.length} crops: $crops");
      return crops;
    } catch (e) {
      print("Error parsing crop list: $e");
      print("Data structure: ${json.encode(data)}");
      return [];
    }
  }

  // Get a color representing the temperature
  Color _getTemperatureColor() {
    if (temperature == null) return Colors.grey;
    if (temperature! < 5) return Colors.blue[700]!;
    if (temperature! < 15) return Colors.blue[400]!;
    if (temperature! < 25) return Colors.orange[300]!;
    if (temperature! < 35) return Colors.orange[600]!;
    return Colors.red[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crop Advisor", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[700]!, Colors.green[50]!],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with animated illustration
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.agriculture,
                      size: 60,
                      color: Colors.green[700],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // User input section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Soil Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Soil type selector with color indicators
                        Text(
                          "Select Soil Type:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedSoilType,
                              onChanged: (newValue) {
                                setState(() {
                                  selectedSoilType = newValue!;
                                });
                              },
                              items: soilTypes.map((soil) {
                                return DropdownMenuItem<String>(
                                  value: soil,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: soilColors[soil],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(soil),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        Text(
                          "Land Size (acres):",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: landSizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green[700]!),
                            ),
                            hintText: "Enter size",
                            prefixIcon: Icon(Icons.crop_square, color: Colors.green[600]),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Weather & Season information
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Conditions",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 16),

                        isLoading
                            ? Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.green[700]),
                              SizedBox(height: 8),
                              Text("Fetching local conditions..."),
                            ],
                          ),
                        )
                            : Column(
                          children: [
                            // Temperature card
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_getTemperatureColor().withOpacity(0.8), _getTemperatureColor().withOpacity(0.5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.thermostat,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Temperature",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        temperature != null
                                            ? "${temperature!.toStringAsFixed(1)}°C"
                                            : "Error fetching",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12),

                            // Season card
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[700],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      seasonIcons[season] ?? Icons.calendar_today,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Season",
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        season,
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Get recommendations button
                Center(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    transform: Matrix4.identity()..scale(isLoading ? 0.95 : 1.0),
                    child: ElevatedButton(
                      onPressed: (temperature != null && !isLoading)
                          ? _getCropRecommendations
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.green[200],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Get Crop Recommendations",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Error message
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[800]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Recommended crops list
                if (recommendedCrops.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.recommend, color: Colors.green[700]),
                            SizedBox(width: 8),
                            Text(
                              "Recommended Crops",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: recommendedCrops.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.green[50] : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green[100]!,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.eco,
                                    color: Colors.green[700],
                                  ),
                                ),
                                title: Text(
                                  recommendedCrops[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.green[300],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}