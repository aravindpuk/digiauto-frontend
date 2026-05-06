import 'dart:async';
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
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  String? selectedPlaceName;

  LatLng selectedLocation = LatLng(8.5241, 76.9366);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Uri _searchUri(String query, {int limit = 5}) {
    return Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": query,
      "format": "json",
      "limit": limit.toString(),
    });
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    final response = await http.get(
      _searchUri(query),
      headers: {"User-Agent": "digiauto-app"},
    );

    final data = json.decode(response.body);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await _searchPlaces(query);
        if (!mounted || searchController.text.trim() != query) return;
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> searchPlace(String query) async {
    final results = await _searchPlaces(query);
    if (!mounted) return;
    if (results.isNotEmpty) _selectSuggestion(results.first);
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = double.tryParse(place["lat"]?.toString() ?? "");
    final lng = double.tryParse(place["lon"]?.toString() ?? "");
    if (lat == null || lng == null) return;

    final name = place["display_name"]?.toString() ?? "";

    setState(() {
      selectedLocation = LatLng(lat, lng);
      selectedPlaceName = name;
      searchController.text = name;
      _suggestions = [];
    });
    mapController.move(selectedLocation, 15);
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
                final center = position.center;
                if (center == null) return;
                selectedLocation = center;
                if (hasGesture) selectedPlaceName = null;
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
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  searchPlace(value);
                },
              ),
            ),
          ),

          if (_suggestions.isNotEmpty)
            Positioned(
              top: 72,
              left: 15,
              right: 15,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      final name = place["display_name"]?.toString() ?? "";
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(place),
                      );
                    },
                  ),
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
              "name": selectedPlaceName ?? searchController.text.trim(),
            });
          },
          child: const Text("Confirm Location"),
        ),
      ),
    );
  }
}
