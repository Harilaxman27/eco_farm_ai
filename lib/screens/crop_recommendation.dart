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
  bool showingRoadmap = false;
  String selectedCrop = "";
  List<Map<String, dynamic>> cultivationRoadmap = [];
  bool loadingRoadmap = false;
  int selectedRoadmapPhase = 0; // To track which phase is selected in the roadmap

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

  // Map of roadmap phases to icons
  final Map<String, IconData> roadmapIcons = {
    "Crop Selection": Icons.eco,
    "Soil Preparation": Icons.landscape,
    "Seed Selection & Sowing": Icons.grain,
    "Irrigation Management": Icons.water_drop,
    "Nutrient & Fertilizer Management": Icons.compost,
    "Weed & Pest Control": Icons.pest_control,
    "Growth Monitoring & Disease Management": Icons.monitor_heart,
    "Harvesting & Post-Harvest Handling": Icons.agriculture,
    "Market & Selling Strategies": Icons.store,
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
      showingRoadmap = false;
      selectedCrop = "";
      cultivationRoadmap = [];
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

  // New method to get comprehensive cultivation roadmap for a specific crop
  Future<void> _getCultivationRoadmap(String crop) async {
    setState(() {
      loadingRoadmap = true;
      showingRoadmap = true;
      selectedCrop = crop;
      cultivationRoadmap = [];
      selectedRoadmapPhase = 0;
      errorMessage = "";
    });

    try {
      String apiKey = "AIzaSyAQ2YmmqHCYG9rAP9ub5HWjNCQQ4WfQfUQ";
      String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

      String prompt =
          "Provide a comprehensive cultivation guide for $crop with the following 9 phases: "
          "1. Crop Selection (climate suitability, best season, yield expectations), "
          "2. Soil Preparation (soil testing, land preparation, fertilization), "
          "3. Seed Selection & Sowing (seed varieties, treatment, spacing, methods), "
          "4. Irrigation Management (water requirements, irrigation methods, conservation), "
          "5. Nutrient & Fertilizer Management (fertilizer application, schedule, deficiency symptoms), "
          "6. Weed & Pest Control (common threats, control methods, crop rotation), "
          "7. Growth Monitoring & Disease Management (disease signs, treatments, detection), "
          "8. Harvesting & Post-Harvest Handling (timing, storage, processing), "
          "9. Market & Selling Strategies (markets, price trends, selling tips). "
          "For each phase, provide 3-4 bullet points with specific advice. "
          "Format each phase as a JSON object with 'title' and 'points' properties, where 'points' is an array of strings. "
          "Return the entire response as a valid JSON array of these objects.";

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

      print("Roadmap response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> roadmap = _extractRoadmapData(data);

        if (roadmap.isEmpty) {
          throw "Could not parse cultivation roadmap from the API response";
        }

        setState(() {
          cultivationRoadmap = roadmap;
        });
      } else {
        throw "Failed to fetch cultivation roadmap: ${response.statusCode}";
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error getting cultivation roadmap: $e";
      });
      print("Error getting cultivation roadmap: $e");
    } finally {
      setState(() => loadingRoadmap = false);
    }
  }

  List<Map<String, dynamic>> _extractRoadmapData(Map<String, dynamic> data) {
    try {
      String responseText = data['candidates'][0]['content']['parts'][0]['text'];
      print("Raw roadmap text: $responseText");

      // Extract JSON from the response text
      RegExp jsonRegExp = RegExp(r'\[[\s\S]*\]');
      Match? match = jsonRegExp.firstMatch(responseText);

      if (match == null) {
        print("No JSON found in response");
        // Fallback to predefined roadmap structure
        return _createFallbackRoadmap();
      }

      String jsonStr = match.group(0) ?? "";

      try {
        List<dynamic> parsedJson = json.decode(jsonStr);
        List<Map<String, dynamic>> roadmap = [];

        for (var item in parsedJson) {
          if (item is Map<String, dynamic> &&
              item.containsKey('title') &&
              item.containsKey('points') &&
              item['points'] is List) {
            roadmap.add({
              'title': item['title'],
              'points': List<String>.from(item['points']),
            });
          }
        }

        if (roadmap.isNotEmpty) {
          return roadmap;
        } else {
          print("Parsed JSON did not contain expected structure");
          return _createFallbackRoadmap();
        }
      } catch (e) {
        print("Error parsing JSON: $e");
        return _createFallbackRoadmap();
      }
    } catch (e) {
      print("Error extracting roadmap data: $e");
      return _createFallbackRoadmap();
    }
  }

  // Fallback roadmap in case API response parsing fails
  List<Map<String, dynamic>> _createFallbackRoadmap() {
    return [
      {
        'title': 'Crop Selection',
        'points': [
          'Climate and soil suitability',
          'Best season for cultivation',
          'Expected yield and market demand',
        ],
      },
      {
        'title': 'Soil Preparation',
        'points': [
          'Soil testing (pH, nutrients)',
          'Land preparation methods (plowing, leveling, mulching)',
          'Organic vs. chemical fertilization',
        ],
      },
      {
        'title': 'Seed Selection & Sowing',
        'points': [
          'Best seed varieties',
          'Seed treatment for disease prevention',
          'Optimal spacing and depth for sowing',
          'Sowing methods (broadcasting, transplanting, drilling)',
        ],
      },
      {
        'title': 'Irrigation Management',
        'points': [
          'Recommended water requirements',
          'Best irrigation methods (drip, sprinkler, flood)',
          'Water conservation techniques',
        ],
      },
      {
        'title': 'Nutrient & Fertilizer Management',
        'points': [
          'Organic and inorganic fertilizer application',
          'Stage-wise fertilizer schedule',
          'Nutrient deficiency symptoms and correction',
        ],
      },
      {
        'title': 'Weed & Pest Control',
        'points': [
          'Common weeds and pests for the crop',
          'Organic & chemical control methods',
          'Crop rotation and companion planting',
        ],
      },
      {
        'title': 'Growth Monitoring & Disease Management',
        'points': [
          'Signs of disease and early detection',
          'Treatment recommendations (biological, chemical)',
          'Use of AI-based disease detection (if integrated)',
        ],
      },
      {
        'title': 'Harvesting & Post-Harvest Handling',
        'points': [
          'Best harvesting time',
          'Storage recommendations',
          'Processing and packaging for market',
        ],
      },
      {
        'title': 'Market & Selling Strategies',
        'points': [
          'Best local and online markets',
          'Price trends and bargaining strategies',
          'Direct-to-consumer selling tips',
        ],
      },
    ];
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

  // Build the cultivation roadmap view
  Widget _buildCultivationRoadmap() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.route, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Cultivation Guide for $selectedCrop",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                onPressed: () {
                  setState(() {
                    showingRoadmap = false;
                    selectedCrop = "";
                    cultivationRoadmap = [];
                  });
                },
              ),
            ],
          ),
          Divider(height: 24),

          if (loadingRoadmap)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.green[700]),
                  SizedBox(height: 16),
                  Text("Loading cultivation guide..."),
                ],
              ),
            )
          else if (cultivationRoadmap.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase selector
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cultivationRoadmap.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedRoadmapPhase == index;
                      String title = cultivationRoadmap[index]['title'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoadmapPhase = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green[700] : Colors.green[50],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? Colors.green[700]! : Colors.green[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                roadmapIcons[title] ?? Icons.eco,
                                color: isSelected ? Colors.white : Colors.green[700],
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "${index + 1}. ${title.split(' ').first}",
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.green[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Selected phase content
                if (cultivationRoadmap.length > selectedRoadmapPhase)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phase title
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              roadmapIcons[cultivationRoadmap[selectedRoadmapPhase]['title']] ?? Icons.eco,
                              color: Colors.green[800],
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "${selectedRoadmapPhase + 1}. ${cultivationRoadmap[selectedRoadmapPhase]['title']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Phase bullet points
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: (cultivationRoadmap[selectedRoadmapPhase]['points'] as List).length,
                        itemBuilder: (context, index) {
                          String point = cultivationRoadmap[selectedRoadmapPhase]['points'][index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.green[50] : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[100]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: EdgeInsets.only(right: 12, top: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                SizedBox(height: 16),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: selectedRoadmapPhase > 0
                          ? () {
                        setState(() {
                          selectedRoadmapPhase--;
                        });
                      }
                          : null,
                      icon: Icon(Icons.arrow_back),
                      label: Text("Previous"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[800],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: selectedRoadmapPhase < cultivationRoadmap.length - 1
                          ? () {
                        setState(() {
                          selectedRoadmapPhase++;
                        });
                      }
                          : null,
                      icon: Text("Next"),
                      label: Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
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

          // Cultivation roadmap
          if (showingRoadmap) ...[
            SizedBox(height: 24),
            _buildCultivationRoadmap(),
          ],

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
                      return InkWell(
                        onTap: () {
                          _getCultivationRoadmap(recommendedCrops[index]);
                        },
                        child: Container(
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "View Cultivation Guide",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                              ],
                            ),
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