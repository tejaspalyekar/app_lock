import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lock/features/current_weather/model/weather_model.dart';
import 'package:app_lock/features/current_weather/service/get_weather_Service.dart';
import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherView extends StatefulWidget {
  const WeatherView({super.key});

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  static String key = '908ee85c110f2216ce21db52fcc7f214';
  WeatherModel? weather;
  final WeatherService? service = WeatherService(apikey: key);
  bool loading = true;
  String currentTime = '';
  String currentDate = '';
  static const String weatherCacheKey = 'cachedWeather';
  static const String timestampKey = 'weatherTimestamp';

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _updateTime();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        currentTime = DateFormat('hh:mm a').format(DateTime.now());
        currentDate = DateFormat('EEE d, MMM').format(DateTime.now());
      });
      Future.delayed(const Duration(minutes: 1), _updateTime);
    }
  }

  Future<void> fetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchedTime = prefs.getInt(timestampKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // If cached data is available and not older than 10 hours (36000000 ms)
    if (lastFetchedTime > 0 && (currentTime - lastFetchedTime) < 36000000) {
      final cachedWeather = prefs.getString(weatherCacheKey);
      if (cachedWeather != null) {
        setState(() {
          weather = WeatherModel.fromJson(jsonDecode(cachedWeather));
          loading = false;
        });
        return;
      }
    }

    // Fetch new data
    try {
      final city = await service?.currentCity();
      final fetchedWeather = await service?.getWeather(city!);
      if (fetchedWeather != null) {
        setState(() {
          weather = fetchedWeather;
          loading = false;
        });

        // Save to cache
        prefs.setString(weatherCacheKey, jsonEncode(fetchedWeather.toJson()));
        prefs.setInt(timestampKey, currentTime);
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  Widget _buildWeatherIcon() {
    double size = 20;
    Color iconColor = Colors.orange;
    IconData iconData;

    if (weather?.maincondition.toLowerCase().contains('clear') ?? false) {
      iconData = Icons.wb_sunny_rounded;
    } else if (weather?.maincondition.toLowerCase().contains('rain') ?? false) {
      iconData = Icons.grain_rounded;
    } else {
      iconData = Icons.cloud_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, size: size, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        // gradient: const LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     Color.fromARGB(96, 119, 119, 119),
        //     Color.fromARGB(113, 119, 119, 119)
        //   ],
        // ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: loading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: CardLoading(
                cardLoadingTheme: const CardLoadingTheme(
                  colorOne: Color.fromARGB(103, 87, 87, 87),
                  colorTwo: Color.fromARGB(61, 87, 87, 87),
                ),
                height: MediaQuery.of(context).size.height * 0.23,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                margin: const EdgeInsets.only(bottom: 10),
              ),
            )
          : Container(
              width: 180,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time and Date Section
                  Text(
                    currentTime,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),

                  // Weather Info Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${weather?.temp.round()}°',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              _buildWeatherIcon(),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.orange.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
