import 'dart:convert';
import 'package:app_lock/features/current_weather/model/weather_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService({this.apikey});

  String? apikey;
  String url = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherModel> getWeather(String city) async {
    final uri = Uri.parse('$url?q=$city&appid=$apikey');
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
