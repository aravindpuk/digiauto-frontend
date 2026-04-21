import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng selectedLocation = LatLng(8.5241, 76.9366);

  Future searchPlace(String query) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1",
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "digiauto-app"},
    );

    final data = json.decode(response.body);

    if (data.isNotEmpty) {
      final lat = double.parse(data[0]["lat"]);
      final lng = double.parse(data[0]["lon"]);

      selectedLocation = LatLng(lat, lng);

      mapController.move(selectedLocation, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),

      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,

              onPositionChanged: (position, hasGesture) {
                selectedLocation = position.center!;
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
              ),
            ],
          ),

          // Search box
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search place",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
                onSubmitted: (value) {
                  searchPlace(value);
                },
              ),
            ),
          ),

          // Center marker
          const Center(
            child: Icon(Icons.location_pin, size: 40, color: Colors.red),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        height: 80,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              "lat": selectedLocation.latitude,
              "lng": selectedLocation.longitude,
            });
          },
          child: const Text("Confirm Location"),
        ),
      ),
    );
  }
}
