import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String apiKey = "bc6b823f5dde66cca83bda2715ade562";

  Future<Map<String, dynamic>> fetchWeather() async {
    try {
      // Step 1: Try to get user's real-time location
      Position position = await _getCurrentLocation();
      return await _fetchWeatherFromAPI(position.latitude, position.longitude);
    } catch (e) {
      print("⚠️ Failed to fetch user location. Using default: Hyderabad, Telangana.");
      // Step 2: If location fetch fails, use Hyderabad as default
      return await _fetchWeatherFromAPI(17.3850, 78.4867);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("⚠️ Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("⚠️ Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("❌ Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, dynamic>> _fetchWeatherFromAPI(double lat, double lon) async {
    String url = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to load weather data");
    }
  }
}
