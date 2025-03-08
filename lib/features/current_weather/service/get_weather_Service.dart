import 'dart:convert';
import 'package:app_lock/features/current_weather/model/weather_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService();

  String url =
      ' https://newsapi.org/v2/everything?q=keyword&apiKey=6864b7b46ed94c8cbe5ccdda608b7a54';

  Future<WeatherModel> getWeather(String city) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unable to fetch data');
    }
  }

  Future<String> currentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemaker =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    return placemaker[0].postalCode!;
  }
}
