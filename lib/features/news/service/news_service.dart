import 'dart:convert';

import 'package:app_lock/features/news/model/news_response_model.dart';
import 'package:http/http.dart' as http;

class NewsService {
  NewsService();
  String yek = 'fb9d4373ac4483595bbdece6589db320';
  String url = 'https://api.mediastack.com/v1/news?access_key=';
  String endPoints = '&keywords=general&countries=in';

  Future<dynamic> getNewsData() async {
    final uri = Uri.parse('$url$yek$endPoints');
    final response = await http.get(uri);
    try {
      if (response.statusCode == 200) {
        return NewsResponseModel.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
