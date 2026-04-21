import 'dart:convert';
import 'package:http/http.dart' as http;

Future searchPlace(String query) async {
  final url = Uri.parse(
    "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1",
  );

  final response = await http.get(url, headers: {"User-Agent": "digiauto-app"});

  final data = json.decode(response.body);
  print(data);

  if (data.isNotEmpty) {
    return {
      "lat": double.parse(data[0]["lat"]),
      "lng": double.parse(data[0]["lon"]),
      "name": data[0]["display_name"],
    };
  }

  return null;
}
