class WeatherModel {
  final double temp;
  final String cityName;
  final String maincondition;
  final String countryname;
  final windspeed;
  final winddegree;
  final int pressure;
  final int humidity;
  final double maxtemp;
  final double mintemp;
  final int visibility;

  WeatherModel(
      {required this.temp,
      required this.cityName,
      required this.countryname,
      required this.maincondition,
      required this.pressure,
      required this.humidity,
      required this.maxtemp,
      required this.mintemp,
      required this.winddegree,
      required this.visibility,
      required this.windspeed});

  static fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json["name"],
      maincondition: json["weather"][0]["main"],
      countryname: json["sys"]["country"],
      temp: json["main"]["temp"] - 273.15,
      humidity: json["main"]["humidity"],
      maxtemp: json["main"]["temp_max"] - 273.15,
      mintemp: json["main"]["temp_min"] - 273.15,
      pressure: json["main"]["pressure"],
      winddegree: json["wind"]["deg"],
      windspeed: json["wind"]["speed"],
      visibility: json["visibility"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": cityName,
      "weather": [
        {"main": maincondition}
      ],
      "sys": {"country": countryname},
      "main": {
        "temp": temp + 273.15, // Convert back to Kelvin
        "humidity": humidity,
        "temp_max": maxtemp + 273.15,
        "temp_min": mintemp + 273.15,
        "pressure": pressure,
      },
      "wind": {
        "deg": winddegree,
        "speed": windspeed,
      },
      "visibility": visibility,
    };
  }
}
