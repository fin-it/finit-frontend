import 'dart:convert';
import 'package:capstone_project/models/foundItem.dart';
import 'package:capstone_project/models/found_model.dart';
import 'package:http/http.dart' as http;

class RemoteService {
  final Map<String, String> _locationCache = {};

  Future<List<Datum>?> getLostItems() async {
    var client = http.Client();

    var uri = Uri.parse('https://finit-api-ahawuso3sq-et.a.run.app/api/lost');
    var response = await client.get(uri);
    if (response.statusCode == 200) {
      var json = response.body;
      return foundFromJson(json).data;
    } else {
      // Handle error appropriately
      print('Failed to fetch data: ${response.statusCode}');
      return null;
    }
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    final cacheKey = '$latitude,$longitude';

    // Check if location is already in cache
    if (_locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    final apiKey = 'AIzaSyASFVu9SBYHG2TUxFRs3ArQrv8phoWMjDo';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      final results = decodedResponse['results'];
      if (results != null && results.isNotEmpty) {
        final locationName = results[0]['formatted_address'];
        // Store location in cache
        _locationCache[cacheKey] = locationName;
        return locationName;
      }
    }
    return 'Location address not found';
  }

  //Form Found Post method
  Future<void> saveItem(FoundModel foundItem) async {
    final url = Uri.https(
      'finit-api-ahawuso3sq-et.a.run.app',
      '/api/found',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJmaW4tSDh4ZHVTZ29oNiIsIm5hbWUiOiJmaW4iLCJpYXQiOjE3MDY1Mzk0MDYsImV4cCI6MTcwNjYyNTgwNn0.hN-2755rsnAYNwxn5Qll_MmT8irT6_oFwTTIdn6wwU4',
        'Content-Type': 'application/json',
      },
      body: json.encode(foundItem.toJson()),
    );
    print(response.body);
    print(response.statusCode);
  }
}
