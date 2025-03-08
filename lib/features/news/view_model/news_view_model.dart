import 'dart:convert';
import 'package:app_lock/features/news/model/news_response_model.dart';
import 'package:app_lock/features/news/service/news_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsViewModel extends ChangeNotifier {
  List<NewsData>? newsData = [];
  bool isLoading = false;

  // Keys for SharedPreferences
  static const String _lastFetchTimeKey = 'last_news_fetch_time';
  static const String _cachedNewsDataKey = 'cached_news_data';

  // Duration in days before refreshing data
  static const int _refreshIntervalDays = 7;

  // Fetch news data with caching logic
  Future<void> fetchNewsData() async {
    isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();

    // Check if we need to fetch new data
    bool shouldFetchNewData = true;

    // Get the last fetch time
    final String? lastFetchTimeStr = prefs.getString(_lastFetchTimeKey);
    if (lastFetchTimeStr != null) {
      final DateTime lastFetchTime = DateTime.parse(lastFetchTimeStr);
      final Duration difference = now.difference(lastFetchTime);

      // If less than 7 days have passed, use cached data
      if (difference.inDays < _refreshIntervalDays) {
        shouldFetchNewData = false;

        // Try to load data from cache
        final String? cachedData = prefs.getString(_cachedNewsDataKey);
        if (cachedData != null) {
          try {
            final Map<String, dynamic> jsonData = jsonDecode(cachedData);
            final NewsResponseModel cachedResponse =
                NewsResponseModel.fromJson(jsonData);

            newsData!.clear();
            newsData = cachedResponse.data;

            isLoading = false;
            notifyListeners();
            return;
          } catch (e) {
            // If there's an error parsing cached data, fetch new data anyway
            shouldFetchNewData = true;
          }
        }
      }
    }

    // Fetch new data if needed
    if (shouldFetchNewData) {
      final dynamic response = await NewsService().getNewsData();
      if (response != null) {
        newsData!.clear();
        newsData = response.data;

        // Cache the new data
        try {
          await prefs.setString(_lastFetchTimeKey, now.toIso8601String());
          await prefs.setString(
              _cachedNewsDataKey, jsonEncode(response.toJson()));
        } catch (e) {
          // Handle caching errors
          print('Error caching news data: $e');
        }
      }
    }

    isLoading = false;
    notifyListeners();
  }

  // Method to force refresh data regardless of time interval
  Future<void> forceRefreshNewsData() async {
    isLoading = true;
    notifyListeners();

    final dynamic response = await NewsService().getNewsData();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (response != null) {
      newsData!.clear();
      newsData = response.data;

      // Update cache
      final DateTime now = DateTime.now();
      await prefs.setString(_lastFetchTimeKey, now.toIso8601String());
      await prefs.setString(_cachedNewsDataKey, jsonEncode(response.toJson()));
    }

    isLoading = false;
    notifyListeners();
  }
}
