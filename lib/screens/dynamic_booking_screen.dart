// Location: lib/screens/dynamic_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pricing_engine.dart';
import '../services/booking_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';


// --- BOOKING UNIT ENUM ---
enum BookingDurationUnit { hours, days }

class MapRoute {
  final String summary;
  final double distanceKm;
  final String durationText;
  final List<LatLng> points;
  final String label;
  final double durationMinutes;
  final double trafficDelayMinutes;

  MapRoute({
    required this.summary,
    required this.distanceKm,
    required this.durationText,
    required this.points,
    required this.label,
    required this.durationMinutes,
    required this.trafficDelayMinutes,
  });
}

class DriverMatchingConfig {
  final double pickupDistanceKm;
  final double driverDistanceKm;
  final String estimatedArrival;
  final double routeScore;
  final double trafficScore;

  DriverMatchingConfig({
    required this.pickupDistanceKm,
    required this.driverDistanceKm,
    required this.estimatedArrival,
    required this.routeScore,
    required this.trafficScore,
  });
}

class DynamicBookingScreen extends StatefulWidget {
  final String? initialServiceType;

  const DynamicBookingScreen({super.key, this.initialServiceType});

  @override
  State<DynamicBookingScreen> createState() => _DynamicBookingScreenState();
}

class _DynamicBookingScreenState extends State<DynamicBookingScreen> {
  // --- STATE VARIABLES ---
  ServiceCategory _selectedService = ServiceCategory.wedding;
  final Map<VehicleCapacity, int> _fleet = {};
  List<MapRoute> _routes = [];
  int _selectedRouteIndex = 0;

  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  double _totalPrice = 0.0;
  bool _isLoading = false;
  bool _isCalculatingDistance = false;
  String? _errorMessage;

  // --- BOOKING TIMER ---
  int _bookingDuration = 1;
  BookingDurationUnit _bookingUnit = BookingDurationUnit.hours;

  // --- MAP & LOCATION ---
  final String _googleApiKey = "AIzaSyDg_iklQdlv-pMqy7R3zAPgai2hBeyElrU";
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<dynamic> _placePredictions = [];
  bool _isSearchingPickup = false;
  Timer? _debounce;
  String _estimatedDuration = "";
  String? _pickupWalkTip;
  String? _destinationWalkTip;
  DriverMatchingConfig? _driverMatchingConfig;
  List<Map<String, dynamic>> _searchHistory = [];

  static final Map<String, String> _geocodingCache = {};
  static final Map<String, List<MapRoute>> _routingCache = {};

  static final List<Map<String, dynamic>> _predefinedPopularPlaces = [
    {
      'name': 'Mikocheni, Dar es Salaam',
      'lat': -6.7725,
      'lon': 39.2520,
      'popularity': 9,
      'type': 'Landmark',
    },
    {
      'name': 'Mikocheni B, Dar es Salaam',
      'lat': -6.7645,
      'lon': 39.2452,
      'popularity': 8,
      'type': 'Subdivision',
    },
    {
      'name': 'Mikocheni Light Industrial Area, Dar es Salaam',
      'lat': -6.7812,
      'lon': 39.2464,
      'popularity': 7,
      'type': 'Industrial',
    },
    {
      'name': 'Mikocheni Kituo cha Daladala, Dar es Salaam',
      'lat': -6.7772,
      'lon': 39.2490,
      'popularity': 6,
      'type': 'Transit',
    },
    {
      'name': 'Mlimani City Shopping Mall, Dar es Salaam',
      'lat': -6.7701,
      'lon': 39.2238,
      'popularity': 10,
      'type': 'Mall',
    },
    {
      'name': 'Julius Nyerere International Airport, Dar es Salaam',
      'lat': -6.8778,
      'lon': 39.2026,
      'popularity': 10,
      'type': 'Airport',
    },
    {
      'name': 'Makongo, Dar es Salaam',
      'lat': -6.7584,
      'lon': 39.2065,
      'popularity': 8,
      'type': 'Neighborhood',
    },
    {
      'name': 'Posta, Dar es Salaam',
      'lat': -6.8160,
      'lon': 39.2890,
      'popularity': 9,
      'type': 'Business District',
    },
    {
      'name': 'Kariakoo Market, Dar es Salaam',
      'lat': -6.8222,
      'lon': 39.2778,
      'popularity': 9,
      'type': 'Market',
    },
    {
      'name': 'Masaki, Dar es Salaam',
      'lat': -6.7526,
      'lon': 39.2750,
      'popularity': 9,
      'type': 'Residential',
    },
    {
      'name': 'Oysterbay, Dar es Salaam',
      'lat': -6.7788,
      'lon': 39.2820,
      'popularity': 8,
      'type': 'Neighborhood',
    },
  ];

  // --- SAVED LOCATIONS ---
  String? _savedHome;
  String? _savedOffice;
  String? _savedSchool;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSavedLocations();

    if (widget.initialServiceType != null) {
      _selectedService = ServiceCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == widget.initialServiceType!.toLowerCase(),
        orElse: () => ServiceCategory.wedding,
      );
    }

    _distanceController.addListener(_recalculatePrice);
    _weightController.addListener(_recalculatePrice);

    _determineCurrentPosition();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ==========================================================
  // NOTIFICATIONS & API HELPERS
  // ==========================================================
  Future<void> _sendSmsNotification(String phoneNumber, double price) async {
    debugPrint("Triggering SMS to $phoneNumber for amount: $price");
  }

  Future<void> _sendEmailNotification(String email, double price) async {
    try {
      await FirebaseFirestore.instance.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'TRANSOVA Booking Confirmation',
          'html':
              '<h1>Booking Received!</h1><p>Your booking for ${PricingEngine.formatCurrency(price)} is being processed.</p>',
        },
      });
    } catch (e) {
      debugPrint("Email error: $e");
    }
  }

  Uri _buildGoogleApiUri(String googleUrl) {
    if (kIsWeb) {
      return Uri.parse(
        "https://corsproxy.io/?${Uri.encodeComponent(googleUrl)}",
      );
    }
    return Uri.parse(googleUrl);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isError ? Colors.redAccent : Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ==========================================================
  // 1. LOCATION & GPS
  // ==========================================================
  Future<void> _determineCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
          "Location services disabled. Please turn on GPS.",
          isError: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permissions denied.", isError: true);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _pickupLatLng = LatLng(position.latitude, position.longitude);

      _updateMapCamera(_pickupLatLng!);
      _setMarker(_pickupLatLng!, "pickup", "Current Location", false);
      await _getAddressFromLatLng(_pickupLatLng!, isPickup: true);
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  // UPDATED: Automatically falls back to GPS Coordinates if Google Geocoding is blocked
  Future<void> _getAddressFromLatLng(
    LatLng position, {
    required bool isPickup,
  }) async {
    final String cacheKey =
        "${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)}";
    if (_geocodingCache.containsKey(cacheKey)) {
      final cachedAddress = _geocodingCache[cacheKey]!;
      setState(() {
        if (isPickup) {
          _pickupController.text = cachedAddress;
        } else {
          _destinationController.text = cachedAddress;
        }
      });
      return;
    }

    final String urlString =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_googleApiKey";

    try {
      final response = await http
          .get(_buildGoogleApiUri(urlString))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final String originalAddress =
              data['results'][0]['formatted_address'];
          final String cleaned = _cleanAddress(originalAddress);
          _geocodingCache[cacheKey] = cleaned;
          setState(() {
            if (isPickup) {
              _pickupController.text = cleaned;
            } else {
              _destinationController.text = cleaned;
            }
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Google Geocoding Exception: $e");
    }

    // Fallback to free OpenStreetMap Nominatim API if Google Geocoding fails/is blocked
    // Directly request without CORS Proxy wrapper since Nominatim supports CORS natively
    try {
      final String osmUrl =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1";
      final response = await http
          .get(
            Uri.parse(osmUrl),
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent': 'TransovaApp/1.0 (contact@transova.com)',
                    'Accept-Language': 'en',
                  },
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = _getCleanOSMName(data);
        final String cleaned = _cleanAddress(displayName);
        _geocodingCache[cacheKey] = cleaned;
        setState(() {
          if (isPickup) {
            _pickupController.text = cleaned;
          } else {
            _destinationController.text = cleaned;
          }
        });
        return;
      }
    } catch (e) {
      debugPrint("OSM Nominatim Geocoding Exception: $e");
    }

    // Ultimate fallback to GPS coordinates if both APIs fail
    _applyFallbackAddress(position, isPickup);
  }

  String _getCleanOSMName(Map<String, dynamic> data) {
    final address = data['address'];
    if (address != null) {
      final nameParts = <String>[];

      // Specific place names
      final amenity =
          address['amenity'] ??
          address['shop'] ??
          address['tourism'] ??
          address['historic'] ??
          address['industrial'] ??
          address['office'] ??
          address['house_name'] ??
          address['building'];
      if (amenity != null) nameParts.add(amenity.toString());

      // Street/road
      final road =
          address['road'] ??
          address['pedestrian'] ??
          address['path'] ??
          address['footway'] ??
          address['street'];
      if (road != null) nameParts.add(road.toString());

      // Suburb/neighbourhood
      final neighbourhood =
          address['neighbourhood'] ??
          address['suburb'] ??
          address['quarter'] ??
          address['hamlet'] ??
          address['village'];
      if (neighbourhood != null) nameParts.add(neighbourhood.toString());

      // City/town
      final city =
          address['city'] ?? address['town'] ?? address['municipality'];
      if (city != null) nameParts.add(city.toString());

      if (nameParts.isNotEmpty) {
        return nameParts.take(3).join(', ');
      }
    }

    // Fallback to display_name and shorten if necessary
    final displayName = data['display_name'];
    if (displayName != null) {
      final parts = displayName.split(', ');
      if (parts.length > 3) {
        return parts.take(3).join(', ');
      }
      return displayName;
    }
    return "Unknown Location";
  }

  String _cleanAddress(String address) {
    if (address.isEmpty) return "";

    // Hardcoded known mapping cleanups for popular Dar es Salaam areas:
    String addressLower = address.toLowerCase();
    if (addressLower.contains("mlimani city")) {
      return "Mlimani City Mall";
    }
    if (addressLower.contains("nyerere international airport") ||
        addressLower.contains("julius nyerere")) {
      return "JNIA Airport";
    }
    if (addressLower.contains("mikocheni")) {
      if (addressLower.contains("industrial"))
        return "Mikocheni Light Industrial Area";
      if (addressLower.contains("kituo")) return "Mikocheni Kituo cha Daladala";
      if (addressLower.contains(" b")) return "Mikocheni B, Dar es Salaam";
      return "Mikocheni, Dar es Salaam";
    }

    // General cleanup rules:
    // Remove postal codes
    String clean = address.replaceAll(RegExp(r'\b\d{5}\b'), '').trim();
    // Remove country name "Tanzania"
    clean = clean
        .replaceAll(RegExp(r'\bTanzania\b', caseSensitive: false), '')
        .trim();

    // Split into components
    List<String> parts = clean
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> resultParts = [];
    for (String part in parts) {
      String partLower = part.toLowerCase();
      // Skip administrative fluff
      if (partLower.contains("municipal") ||
          partLower.contains("coastal zone") ||
          partLower.contains("region") ||
          partLower.contains("district") ||
          partLower.contains("ward") ||
          partLower.contains("division")) {
        continue;
      }
      resultParts.add(part);
    }

    if (resultParts.isEmpty) {
      resultParts = parts;
    }

    if (resultParts.length > 2) {
      if (resultParts.length > 3) {
        return "${resultParts[0]}, ${resultParts[1]}, ${resultParts[resultParts.length - 1]}";
      }
      return resultParts.join(", ");
    }
    return resultParts.join(", ");
  }

  void _applyFallbackAddress(LatLng pos, bool isPickup) {
    String fallback =
        "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
    setState(() {
      if (isPickup) {
        _pickupController.text = fallback;
      } else {
        _destinationController.text = fallback;
      }
    });
  }

  // ==========================================================
  // 2. LIVE AUTOCOMPLETE & PLACES API
  // ==========================================================
  void _onSearchChanged(String query, bool isPickup) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearchingPickup = isPickup;
      });

      List<dynamic> apiResults = [];

      if (query.isNotEmpty) {
        // Hyper-local Google Search: restrict to TZ, favor user location
        final lat = _pickupLatLng?.latitude ?? -6.816064;
        final lng = _pickupLatLng?.longitude ?? 39.280335;
        final String urlString =
            "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey&components=country:tz&location=$lat,$lng&radius=50000";
        try {
          // Add timeout to prevent freezing on cors proxy or bad network
          final response = await http
              .get(_buildGoogleApiUri(urlString))
              .timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'OK') {
              apiResults = data['predictions'];
            }
          }
        } catch (e) {
          debugPrint("Autocomplete Error: $e");
        }

        // Always query OSM for rich hyper-local business & street data
        final osmResults = await _osmSearchChanged(query);
        apiResults.addAll(osmResults);

        // Deduplicate results based on primary description to avoid identical entries
        final seen = <String>{};
        apiResults = apiResults.where((r) {
          final desc = r['description'].toString().toLowerCase().trim();
          if (seen.contains(desc)) return false;
          seen.add(desc);
          return true;
        }).toList();
      }

      // Rank combined predictions (History + Predefined + Google + OSM)
      final ranked = _rankPredictions(query, apiResults);

      setState(() {
        _placePredictions = ranked;
        _isSearchingPickup = isPickup;
      });
    });
  }

  Future<List<dynamic>> _osmSearchChanged(String query) async {
    // HYPER-LOCAL: Restrict to Tanzania and increase limit to capture granular details
    final String osmSearchUrl =
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=15&addressdetails=1&accept-language=en&countrycodes=tz";

    try {
      // Add timeout and remove User-Agent on Web to prevent CORS/Preflight exceptions
      final response = await http
          .get(
            Uri.parse(osmSearchUrl),
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent': 'TransovaApp/1.0 (contact@transova.com)',
                  },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final displayName = item['display_name'] as String;
          final parts = displayName.split(',');
          final mainText = parts.isNotEmpty ? parts[0].trim() : displayName;
          final secondaryText = parts.length > 1
              ? parts.skip(1).take(2).join(',').trim()
              : "";

          return {
            'isOSM': true,
            'place_id': item['place_id'].toString(),
            'description': displayName,
            'lat': double.tryParse(item['lat']?.toString() ?? ''),
            'lon': double.tryParse(item['lon']?.toString() ?? ''),
            'structured_formatting': {
              'main_text': mainText,
              'secondary_text': secondaryText,
            },
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("OSM Search Error: $e");
    }
    return [];
  }

  List<dynamic> _rankPredictions(String query, List<dynamic> apiPredictions) {
    if (query.isEmpty) {
      final List<dynamic> results = [];
      // Add all history
      for (final hist in _searchHistory) {
        final desc = hist['description'].toString();
        results.add({
          'place_id': hist['place_id'],
          'description': desc,
          'lat': hist['lat'],
          'lon': hist['lon'],
          'isHistory': true,
          'structured_formatting': {
            'main_text': desc.split(',')[0],
            'secondary_text': desc.contains(',')
                ? desc.substring(desc.indexOf(',') + 1).trim()
                : 'Search History',
          },
        });
      }
      // Add predefined popular places
      for (final place in _predefinedPopularPlaces) {
        final name = place['name'].toString();
        results.add({
          'place_id': 'predefined_${name.hashCode}',
          'description': name,
          'lat': place['lat'],
          'lon': place['lon'],
          'isPopular': true,
          'structured_formatting': {
            'main_text': name.split(',')[0],
            'secondary_text': name.contains(',')
                ? name.substring(name.indexOf(',') + 1).trim()
                : 'Popular Place',
          },
        });
      }
      return results;
    }

    final List<Map<String, dynamic>> scored = [];
    final String q = query.toLowerCase().trim();
    final LatLng userPos = _pickupLatLng ?? const LatLng(-6.816064, 39.280335);

    // 1. Check Search History
    for (final hist in _searchHistory) {
      final desc = hist['description'].toString();
      if (desc.toLowerCase().contains(q)) {
        double score = 1500.0;
        if (desc.toLowerCase().startsWith(q)) score += 300;
        scored.add({
          'prediction': {
            'place_id': hist['place_id'],
            'description': desc,
            'lat': hist['lat'],
            'lon': hist['lon'],
            'isHistory': true,
            'structured_formatting': {
              'main_text': desc.split(',')[0],
              'secondary_text': desc.contains(',')
                  ? desc.substring(desc.indexOf(',') + 1).trim()
                  : 'Search History',
            },
          },
          'score': score,
        });
      }
    }

    // 2. Check Predefined Popular Places
    for (final place in _predefinedPopularPlaces) {
      final name = place['name'].toString();
      if (name.toLowerCase().contains(q)) {
        double score = 1000.0;
        if (name.toLowerCase().startsWith(q)) score += 200;
        score += (place['popularity'] as int) * 15.0;

        final double dist =
            Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              place['lat'] as double,
              place['lon'] as double,
            ) /
            1000.0;
        score -= dist * 5.0; // penalty for distance

        scored.add({
          'prediction': {
            'place_id': 'predefined_${name.hashCode}',
            'description': name,
            'lat': place['lat'],
            'lon': place['lon'],
            'isPopular': true,
            'structured_formatting': {
              'main_text': name.split(',')[0],
              'secondary_text': name.contains(',')
                  ? name.substring(name.indexOf(',') + 1).trim()
                  : 'Popular Place',
            },
          },
          'score': score,
        });
      }
    }

    // 3. Process API predictions (Google or OSM)
    for (final pred in apiPredictions) {
      final String desc =
          pred['description'] ?? pred['formatted_address'] ?? '';
      if (desc.isEmpty) continue;

      // Avoid duplicate entries
      if (scored.any(
        (element) =>
            element['prediction']['description'].toString().toLowerCase() ==
            desc.toLowerCase(),
      )) {
        continue;
      }

      double score = 500.0;
      final descLower = desc.toLowerCase();
      if (descLower == q) {
        score += 2000;
      } else if (descLower.startsWith(q)) {
        score += 800;
      } else if (descLower.contains(q)) {
        score += 300;
      }

      // Business & Landmark boost
      if (descLower.contains('mall') || 
          descLower.contains('bank') || 
          descLower.contains('hospital') || 
          descLower.contains('school') || 
          descLower.contains('pizza') || 
          descLower.contains('pharmacy') ||
          descLower.contains('clinic') ||
          descLower.contains('market') ||
          descLower.contains('bus stop')) {
         score += 200;
      }

      if (pred['lat'] != null && pred['lon'] != null) {
        final double dist =
            Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              pred['lat'] as double,
              pred['lon'] as double,
            ) /
            1000.0;
        score -= dist * 5.0;
      }

      scored.add({'prediction': pred, 'score': score});
    }

    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return scored.map((item) => item['prediction']).toList();
  }

  void _addToSearchHistory(
    String placeId,
    String description,
    double lat,
    double lon,
  ) {
    final entry = {
      'place_id': placeId,
      'description': description,
      'lat': lat,
      'lon': lon,
      'isHistory': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _searchHistory.removeWhere((e) => e['description'] == description);
    _searchHistory.insert(0, entry);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.take(5).toList();
    }
    _saveSearchHistory();
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedHome = prefs.getString('saved_home');
      _savedOffice = prefs.getString('saved_office');
      _savedSchool = prefs.getString('saved_school');
    });
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('search_history');
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(decoded);
        });
      }
    } catch (e) {
      debugPrint("Error loading search history: $e");
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(_searchHistory);
      await prefs.setString('search_history', historyJson);
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }

  Future<LatLng> _snapToNearestRoad(LatLng position, bool isPickup) async {
    final String url =
        "https://router.project-osrm.org/nearest/v1/driving/${position.longitude},${position.latitude}?number=1";
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent': 'TransovaApp/1.0 (contact@transova.com)',
                  },
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['waypoints'] != null &&
            data['waypoints'].isNotEmpty) {
          final waypoint = data['waypoints'][0];
          final double snappedLng = waypoint['location'][0];
          final double snappedLat = waypoint['location'][1];
          final String roadName = waypoint['name'] ?? "";
          final LatLng snappedLatLng = LatLng(snappedLat, snappedLng);

          double walkDistance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            snappedLat,
            snappedLng,
          );

          if (walkDistance > 15.0) {
            final displayRoad = roadName.isNotEmpty
                ? "on $roadName"
                : "to the main road";
            setState(() {
              if (isPickup) {
                _pickupWalkTip =
                    "Walk ${walkDistance.toStringAsFixed(0)}m $displayRoad (Inaccessible pickup)";
              } else {
                _destinationWalkTip =
                    "Walk ${walkDistance.toStringAsFixed(0)}m $displayRoad (Inaccessible dropoff)";
              }
            });
          } else {
            setState(() {
              if (isPickup) {
                _pickupWalkTip = null;
              } else {
                _destinationWalkTip = null;
              }
            });
          }
          return snappedLatLng;
        }
      }
    } catch (e) {
      debugPrint("OSM snapping error: $e");
    }
    setState(() {
      if (isPickup) {
        _pickupWalkTip = null;
      } else {
        _destinationWalkTip = null;
      }
    });
    return position;
  }

  Future<void> _getPlaceDetails(
    String placeId,
    String description,
    bool isPickup, {
    double? fallbackLat,
    double? fallbackLng,
  }) async {
    FocusScope.of(context).unfocus();
    final String cleanName = _cleanAddress(description);

    setState(() {
      _placePredictions = [];
      _isSearchingPickup = false;
      if (isPickup) {
        _pickupController.text = cleanName;
      } else {
        _destinationController.text = cleanName;
      }
    });

    LatLng latLng;

    if (placeId.startsWith("predefined_")) {
      final matched = _predefinedPopularPlaces.firstWhere(
        (p) => 'predefined_${p['name'].hashCode}' == placeId,
        orElse: () => _predefinedPopularPlaces[0],
      );
      latLng = LatLng(matched['lat'] as double, matched['lon'] as double);
    } else if (fallbackLat != null && fallbackLng != null) {
      latLng = LatLng(fallbackLat, fallbackLng);
    } else {
      final String urlString =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
      try {
        final response = await http
            .get(_buildGoogleApiUri(urlString))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final lat = data['result']['geometry']['location']['lat'];
            final lng = data['result']['geometry']['location']['lng'];
            latLng = LatLng(lat, lng);
          } else {
            return;
          }
        } else {
          return;
        }
      } catch (e) {
        debugPrint("Place Details Error: $e");
        return;
      }
    }

    _addToSearchHistory(placeId, cleanName, latLng.latitude, latLng.longitude);

    if (isPickup) {
      final LatLng snapped = await _snapToNearestRoad(latLng, true);
      _pickupLatLng = snapped;
      _setMarker(snapped, "pickup", "Pickup", false);
    } else {
      final LatLng snapped = await _snapToNearestRoad(latLng, false);
      _destinationLatLng = snapped;
      _setMarker(snapped, "destination", "Destination", true);
    }

    if (_pickupLatLng != null && _destinationLatLng != null) {
      _drawRouteAndCalculate();
    } else {
      _updateMapCamera(latLng);
    }
  }

  // ==========================================================
  // MAP PICKER & ROUTING
  // ==========================================================
  Future<void> _pickLocationOnMap(TextEditingController controller) async {
    FocusScope.of(context).unfocus();

    LatLng startingLocation = const LatLng(-6.816064, 39.280335);
    if (controller == _pickupController && _pickupLatLng != null) {
      startingLocation = _pickupLatLng!;
    } else if (controller == _destinationController &&
        _destinationLatLng != null) {
      startingLocation = _destinationLatLng!;
    }

    final MapPickerResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialPosition: startingLocation),
      ),
    );

    if (result != null) {
      bool isPickup = controller == _pickupController;
      LatLng finalLocation = await _snapToNearestRoad(result.location, isPickup);

      setState(() {
        if (isPickup) {
          _pickupLatLng = finalLocation;
          _pickupController.text = result.address;
          _setMarker(finalLocation, "pickup", "Pickup", false);
        } else {
          _destinationLatLng = finalLocation;
          _destinationController.text = result.address;
          _setMarker(finalLocation, "destination", "Destination", true);
        }
      });

      final String cacheKey =
          "${finalLocation.latitude.toStringAsFixed(5)},${finalLocation.longitude.toStringAsFixed(5)}";
      _geocodingCache[cacheKey] = result.address;

      if (_pickupLatLng != null && _destinationLatLng != null) {
        _drawRouteAndCalculate();
      } else {
        _updateMapCamera(finalLocation);
      }
    }
  }

  Future<void> _calculateDistance() async {
    FocusScope.of(context).unfocus();

    if (_pickupLatLng == null) {
      _showSnackBar(
        "Please tap a suggestion from the dropdown for Pickup.",
        isError: true,
      );
      return;
    }
    if (_destinationLatLng == null) {
      _showSnackBar(
        "Please tap a suggestion from the dropdown for Destination.",
        isError: true,
      );
      return;
    }

    setState(() => _isCalculatingDistance = true);
    await _drawRouteAndCalculate();
    setState(() => _isCalculatingDistance = false);
  }

  void _setMarker(LatLng point, String id, String title, bool isDestination) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: point,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isDestination ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });
  }

  double calculateAdvancedEta({
    required double distanceKm,
    required List<LatLng> points,
  }) {
    double averageSpeedKmh = 35.0;
    double baseTimeMinutes = (distanceKm / averageSpeedKmh) * 60.0;

    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    double trafficMultiplier = 1.0;
    if (!isWeekend) {
      if ((hour >= 7 && hour < 10) || (hour >= 16 && hour < 20)) {
        trafficMultiplier = 1.65;
      } else if (hour >= 10 && hour < 16) {
        trafficMultiplier = 1.25;
      } else if (hour >= 20 && hour < 23) {
        trafficMultiplier = 1.10;
      } else {
        trafficMultiplier = 0.85;
      }
    } else {
      if (hour >= 11 && hour < 19) {
        trafficMultiplier = 1.20;
      } else {
        trafficMultiplier = 0.90;
      }
    }

    double estimatedJunctions = distanceKm * 2.5;
    double junctionDelayMinutes = estimatedJunctions * 0.4;

    double turnsPerKm = points.length / (distanceKm > 0 ? distanceKm : 1.0);
    double roadClassMultiplier = 1.0;
    if (turnsPerKm > 15) {
      roadClassMultiplier = 1.25;
    } else if (turnsPerKm < 5) {
      roadClassMultiplier = 0.90;
    }

    return (baseTimeMinutes * trafficMultiplier * roadClassMultiplier) +
        junctionDelayMinutes;
  }

  double _evaluateRouteScore(MapRoute route) {
    double cost = route.distanceKm * 1.2;
    cost += route.durationMinutes * 0.8;
    cost += route.trafficDelayMinutes * 2.0;

    double turnsPerKm =
        route.points.length / (route.distanceKm > 0 ? route.distanceKm : 1.0);
    if (turnsPerKm > 15) {
      cost += 5.0;
    }
    return cost;
  }

  void _enrichRouteAlternatives() {
    // We disable artificial alternatives to ensure all routes accurately follow roads.
    // The routing provider (Google Directions / OSRM) will return actual alternatives if available.
  }

  Future<void> _drawRouteAndCalculate() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    setState(() {
      _isCalculatingDistance = true;
      _errorMessage = null;
    });

    final routeCacheKey =
        "${_pickupLatLng!.latitude.toStringAsFixed(4)},${_pickupLatLng!.longitude.toStringAsFixed(4)}->${_destinationLatLng!.latitude.toStringAsFixed(4)},${_destinationLatLng!.longitude.toStringAsFixed(4)}";
    if (_routingCache.containsKey(routeCacheKey)) {
      setState(() {
        _routes = _routingCache[routeCacheKey]!;
        _selectedRouteIndex = 0;
        _isCalculatingDistance = false;
      });
      _updateRouteUI();
      return;
    }

    final String urlString =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}&alternatives=true&key=$_googleApiKey";

    try {
      final response = await http
          .get(_buildGoogleApiUri(urlString))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null) {
          final List<dynamic> googleRoutes = data['routes'];
          _routes = googleRoutes.asMap().entries.map((entry) {
            final int index = entry.key;
            final dynamic routeData = entry.value;

            final distanceMeters = routeData['legs'][0]['distance']['value'];
            final summary = routeData['summary'] ?? "";
            final encodedPolyline = routeData['overview_polyline']['points'];
            final points = _decodePolyline(encodedPolyline);

            final double distanceKm = distanceMeters / 1000.0;
            final double advancedDuration = calculateAdvancedEta(
              distanceKm: distanceKm,
              points: points,
            );
            final double trafficDelay =
                advancedDuration - (distanceKm / 45.0 * 60.0);

            String label = "FASTEST ROUTE";
            if (index == 1) label = "SHORTEST ROUTE";
            if (index >= 2) label = "LOW TRAFFIC ROUTE";

            return MapRoute(
              summary: summary.toString().isNotEmpty
                  ? summary.toString()
                  : "Main Route",
              distanceKm: distanceKm,
              durationText: "${advancedDuration.toStringAsFixed(0)} mins",
              points: points,
              label: label,
              durationMinutes: advancedDuration,
              trafficDelayMinutes: trafficDelay > 0 ? trafficDelay : 0.0,
            );
          }).toList();

          _enrichRouteAlternatives();

          _routingCache[routeCacheKey] = _routes;
          _selectedRouteIndex = 0;
          _updateRouteUI();
          setState(() => _isCalculatingDistance = false);
          return;
        }
      }
    } catch (e) {
      debugPrint("Google Directions API error: $e");
    }

    await _fetchOsmRoute();
    setState(() => _isCalculatingDistance = false);
  }

  Future<void> _fetchOsmRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    final routeCacheKey =
        "${_pickupLatLng!.latitude.toStringAsFixed(4)},${_pickupLatLng!.longitude.toStringAsFixed(4)}->${_destinationLatLng!.latitude.toStringAsFixed(4)},${_destinationLatLng!.longitude.toStringAsFixed(4)}";
    if (_routingCache.containsKey(routeCacheKey)) {
      setState(() {
        _routes = _routingCache[routeCacheKey]!;
        _selectedRouteIndex = 0;
      });
      _updateRouteUI();
      return;
    }

    final String osmRouteUrl =
        "https://router.project-osrm.org/route/v1/driving/${_pickupLatLng!.longitude},${_pickupLatLng!.latitude};${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}?overview=full&geometries=polyline&alternatives=true";

    try {
      final response = await http
          .get(
            Uri.parse(osmRouteUrl),
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent': 'TransovaApp/1.0 (contact@transova.com)',
                  },
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null) {
          final List<dynamic> osrmRoutes = data['routes'];

          _routes = osrmRoutes.asMap().entries.map((entry) {
            final int index = entry.key;
            final dynamic routeData = entry.value;

            final distanceMeters = routeData['distance'];
            final points = _decodePolyline(routeData['geometry'] ?? "");

            final double distanceKm =
                (distanceMeters is num ? distanceMeters.toDouble() : 0.0) /
                1000.0;
            final double advancedDuration = calculateAdvancedEta(
              distanceKm: distanceKm,
              points: points,
            );
            final double trafficDelay =
                advancedDuration - (distanceKm / 45.0 * 60.0);

            String summary = "";
            if (routeData['legs'] != null && routeData['legs'].isNotEmpty) {
              summary = routeData['legs'][0]['summary'] ?? "";
            }
            if (summary.isEmpty) {
              summary = index == 0 ? "Main Route" : "Alternative Route $index";
            }

            String label = "FASTEST ROUTE";
            if (index == 1) label = "SHORTEST ROUTE";
            if (index >= 2) label = "LOW TRAFFIC ROUTE";

            return MapRoute(
              summary: summary,
              distanceKm: distanceKm,
              durationText: "${advancedDuration.toStringAsFixed(0)} mins",
              points: points,
              label: label,
              durationMinutes: advancedDuration,
              trafficDelayMinutes: trafficDelay > 0 ? trafficDelay : 0.0,
            );
          }).toList();

          _enrichRouteAlternatives();

          _routingCache[routeCacheKey] = _routes;
          _selectedRouteIndex = 0;
          _updateRouteUI();
          return;
        }
      }
    } catch (e) {
      debugPrint("OSRM routing error: $e");
    }

    _calculateFallbackDistance();
  }

  void _updateRouteUI() {
    if (_routes.isEmpty) return;

    setState(() {
      _polylines.clear();

      for (int i = 0; i < _routes.length; i++) {
        if (i != _selectedRouteIndex) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId("route_$i"),
              color: const Color(0xFF0055FF).withOpacity(0.4), // Alternative light blue
              width: 5, // 5-6px
              points: _routes[i].points,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              zIndex: 1,
              consumeTapEvents: true,
              onTap: () {
                setState(() {
                  _selectedRouteIndex = i;
                  _updateRouteUI();
                });
              },
            ),
          );
        }
      }

      final selectedRoute = _routes[_selectedRouteIndex];
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route_selected"),
          color: const Color(0xFF0055FF), // Bolt-style strong Blue
          width: 9, // 8-10px
          points: selectedRoute.points,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: 10,
        ),
      );

      if (selectedRoute.points.length > 8) {
        int len = selectedRoute.points.length;
        int redStart = (len * 0.40).toInt();
        int redEnd = (len * 0.55).toInt();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route_traffic_heavy"),
            color: const Color(0xFFE53935),
            width: 7,
            points: selectedRoute.points.sublist(redStart, redEnd),
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 11,
          ),
        );

        int orangeStart = (len * 0.70).toInt();
        int orangeEnd = (len * 0.82).toInt();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route_traffic_moderate"),
            color: const Color(0xFFFFB300),
            width: 7,
            points: selectedRoute.points.sublist(orangeStart, orangeEnd),
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 11,
          ),
        );
      }

      _distanceController.text = selectedRoute.distanceKm.toStringAsFixed(1);
      _estimatedDuration = selectedRoute.durationText;

      final double routeScore = _evaluateRouteScore(selectedRoute);
      final double driverDistanceKm = 1.0 + (selectedRoute.distanceKm * 0.08);
      final double totalArrivalMinutes =
          selectedRoute.durationMinutes + (driverDistanceKm / 30.0 * 60.0);
      final arrivalTimeStr = DateTime.now()
          .add(Duration(minutes: totalArrivalMinutes.toInt()))
          .toLocal()
          .toString()
          .substring(11, 16);

      _driverMatchingConfig = DriverMatchingConfig(
        pickupDistanceKm: selectedRoute.distanceKm,
        driverDistanceKm: driverDistanceKm,
        estimatedArrival: arrivalTimeStr,
        routeScore: routeScore,
        trafficScore: selectedRoute.trafficDelayMinutes,
      );
    });

    _recalculatePrice();
    _animateCameraToRoute();
  }

  void _calculateFallbackDistance() {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude,
      );
      double estimatedKm = (distanceInMeters / 1000) * 1.25;

      final points = [_pickupLatLng!, _destinationLatLng!];
      final double advancedDuration = calculateAdvancedEta(
        distanceKm: estimatedKm,
        points: points,
      );

      final fallbackRoute = MapRoute(
        summary: "Direct GPS Estimate",
        distanceKm: estimatedKm,
        durationText: "${advancedDuration.toStringAsFixed(0)} mins",
        points: points,
        label: "FASTEST ROUTE",
        durationMinutes: advancedDuration,
        trafficDelayMinutes: 0.0,
      );

      setState(() {
        _routes = [fallbackRoute];
        _enrichRouteAlternatives();
        _selectedRouteIndex = 0;
        _errorMessage = "Google Directions failed. Estimating route via GPS.";
      });

      _updateRouteUI();
    } catch (e) {
      debugPrint("Fallback distance calculation error: $e");
    }
  }

  Future<void> _animateCameraToRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    final GoogleMapController controller = await _mapController.future;

    double minLat = math.min(_pickupLatLng!.latitude, _destinationLatLng!.latitude);
    double maxLat = math.max(_pickupLatLng!.latitude, _destinationLatLng!.latitude);
    double minLng = math.min(_pickupLatLng!.longitude, _destinationLatLng!.longitude);
    double maxLng = math.max(_pickupLatLng!.longitude, _destinationLatLng!.longitude);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
  }

  Future<void> _updateMapCamera(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16),
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  // ==========================================================
  // BUSINESS LOGIC & PRICING
  // ==========================================================
  void _recalculatePrice() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        _totalPrice = 0.0;
      });

      final double distance = double.tryParse(_distanceController.text) ?? 0;
      final double weight = double.tryParse(_weightController.text) ?? 0;
      if (distance <= 0) return;

      try {
        double basePrice = 0.0;
        if (_selectedService == ServiceCategory.cargo ||
            _selectedService == ServiceCategory.sanitation) {
          basePrice = PricingEngine.calculateFare(
            distanceKm: distance,
            serviceType: _selectedService,
            vehicleCapacity: VehicleCapacity.cargoVehicle,
            weightKg: weight,
          ).totalPrice;
        } else {
          _fleet.forEach((capacity, quantity) {
            basePrice +=
                (PricingEngine.calculateFare(
                  distanceKm: distance,
                  serviceType: _selectedService,
                  vehicleCapacity: capacity,
                  weightKg: weight,
                ).totalPrice *
                quantity);
          });
        }

        double timeMultiplier = _bookingUnit == BookingDurationUnit.days
            ? (_bookingDuration * 24.0)
            : _bookingDuration.toDouble();
        setState(() => _totalPrice = basePrice * timeMultiplier);
      } catch (e) {
        setState(
          () => _errorMessage = e.toString().replaceAll(
            'Invalid argument(s): ',
            '',
          ),
        );
      }
    });
  }

  Future<void> _submitBooking() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _phoneController.text.length != 10) {
      setState(() {
        _errorMessage = "Please enter your name and a valid 10-digit phone number.";
      });
      return;
    }
    if (_totalPrice <= 0 ||
        _pickupLatLng == null ||
        _destinationLatLng == null) {
      _showSnackBar(
        'Please complete all form fields and ensure a valid route.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, int> fleetData = {};
      _fleet.forEach((key, value) {
        if (value > 0) fleetData[key.name] = value;
      });
      
      String vehicleTypeDesc = fleetData.entries.map((e) => '${e.value}x ${e.key}').join(', ');
      if (vehicleTypeDesc.isEmpty) vehicleTypeDesc = _selectedService.name;

      final double parsedDistance = double.tryParse(_distanceController.text) ?? 0;
      final double parsedDuration = double.tryParse(_estimatedDuration.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      await BookingService().createBooking(
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        pickupAddress: _pickupController.text,
        pickupLatitude: _pickupLatLng!.latitude,
        pickupLongitude: _pickupLatLng!.longitude,
        destinationAddress: _destinationController.text,
        destinationLatitude: _destinationLatLng!.latitude,
        destinationLongitude: _destinationLatLng!.longitude,
        distanceKm: parsedDistance,
        durationMinutes: parsedDuration,
        estimatedFare: _totalPrice,
        vehicleType: vehicleTypeDesc,
        paymentMethod: "Cash/Card", // Placeholder as payment is handled elsewhere
      );

      await _sendSmsNotification(_phoneController.text, _totalPrice);
      if (user?.email != null) {
        await _sendEmailNotification(user!.email!, _totalPrice);
      }

      if (mounted) {
        _showSnackBar('Booking requested successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      _showSnackBar('Booking failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // PRO UI BUILDER
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    bool showWeightInput =
        _selectedService == ServiceCategory.cargo ||
        _selectedService == ServiceCategory.sanitation;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 1. MAP BACKGROUND
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.816064, 39.280335),
                zoom: 13,
              ),
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              padding: const EdgeInsets.only(top: 200, bottom: 400),
            ),
          ),

          // 2. GLASSMORPHISM TOP SEARCH PANEL
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: PointerInterceptor(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _pickLocationOnMap(_pickupController),
                                ),
                                Container(
                                  width: 2,
                                  height: 24,
                                  color: Colors.grey[300],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _pickLocationOnMap(
                                    _destinationController,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchField(
                                    _pickupController,
                                    "Pickup Location",
                                    true,
                                  ),
                                  const Divider(height: 16, thickness: 1),
                                  _buildSearchField(
                                    _destinationController,
                                    "Where to?",
                                    false,
                                  ),
                                  if (_savedHome != null || _savedOffice != null || _savedSchool != null) ...[
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (_savedHome != null && _savedHome!.isNotEmpty) _buildLocationChip(Icons.home, "Home", _savedHome!),
                                          if (_savedOffice != null && _savedOffice!.isNotEmpty) _buildLocationChip(Icons.work, "Office", _savedOffice!),
                                          if (_savedSchool != null && _savedSchool!.isNotEmpty) _buildLocationChip(Icons.school, "School", _savedSchool!),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_pickupWalkTip != null || _destinationWalkTip != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_pickupWalkTip != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_walk,
                                                  color: Colors.green.shade700,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _pickupWalkTip!,
                                                    style: TextStyle(
                                                      color: Colors.green.shade800,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (_pickupWalkTip != null && _destinationWalkTip != null)
                                            const SizedBox(height: 4),
                                          if (_destinationWalkTip != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_walk,
                                                  color: Colors.green.shade700,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _destinationWalkTip!,
                                                    style: TextStyle(
                                                      color: Colors.green.shade800,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. ANIMATED AUTOCOMPLETE SUGGESTIONS
          Positioned(
            top: 245,
            left: 16,
            right: 16,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _placePredictions.isNotEmpty
                  ? PointerInterceptor(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _placePredictions.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 56),
                          itemBuilder: (context, index) {
                            final place = _placePredictions[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: place['isHistory'] == true
                                      ? Colors.purple.shade50
                                      : place['isPopular'] == true
                                      ? Colors.amber.shade50
                                      : Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  place['isHistory'] == true
                                      ? Icons.history
                                      : place['isPopular'] == true
                                      ? Icons.star
                                      : Icons.location_on,
                                  color: place['isHistory'] == true
                                      ? Colors.purple.shade700
                                      : place['isPopular'] == true
                                      ? Colors.amber.shade800
                                      : Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                place['structured_formatting']?['main_text'] ??
                                    place['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle:
                                  place['structured_formatting']?['secondary_text'] !=
                                      null
                                  ? Text(
                                      place['structured_formatting']['secondary_text'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () => _getPlaceDetails(
                                place['place_id'],
                                place['description'],
                                _isSearchingPickup,
                                fallbackLat: place['lat'] as double?,
                                fallbackLng: place['lon'] as double?,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // 4. BOTTOM FORM SHEET
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return PointerInterceptor(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).unfocus(),
                    onScaleStart: (_) {},
                    onScaleUpdate: (_) {}, // Prevents map zoom bleed
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 30,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 48,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // DURATION TOGGLE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      DropdownButton<BookingDurationUnit>(
                                        value: _bookingUnit,
                                        underline: const SizedBox(),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.black54,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        onChanged: (BookingDurationUnit? val) {
                                          if (val != null) {
                                            setState(() {
                                              _bookingUnit = val;
                                              _recalculatePrice();
                                            });
                                          }
                                        },
                                        items: const [
                                          DropdownMenuItem(
                                            value: BookingDurationUnit.hours,
                                            child: Text("Hours"),
                                          ),
                                          DropdownMenuItem(
                                            value: BookingDurationUnit.days,
                                            child: Text("Days"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() {
                                            if (_bookingDuration > 1) {
                                              _bookingDuration--;
                                            }
                                            _recalculatePrice();
                                          }),
                                        ),
                                        Text(
                                          "$_bookingDuration",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 20),
                                          onPressed: () => setState(() {
                                            _bookingDuration++;
                                            _recalculatePrice();
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            DropdownButtonFormField<ServiceCategory>(
                              decoration: _inputDecoration(
                                "Service Type",
                                Icons.local_taxi,
                              ),
                              initialValue: _selectedService,
                              icon: const Icon(
                                Icons.arrow_drop_down_circle_outlined,
                              ),
                              items: ServiceCategory.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedService = val;
                                    _recalculatePrice();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            if (!showWeightInput) ...[
                              const Text(
                                "Select Fleet Requirements",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...VehicleCapacity.values
                                  .where(
                                    (v) => v != VehicleCapacity.cargoVehicle,
                                  )
                                  .map(
                                    (capacity) => _buildFleetSelector(capacity),
                                  ),
                              const SizedBox(height: 16),
                            ],

                            TextField(
                              controller: _distanceController,
                              readOnly: true,
                              decoration:
                                  _inputDecoration(
                                    "Calculated Distance (KM)",
                                    Icons.route,
                                  ).copyWith(
                                    fillColor: Colors.grey.shade200,
                                    suffixIcon: _isCalculatingDistance
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                  ),
                            ),
                            const SizedBox(height: 16),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: showWeightInput
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: TextField(
                                        controller: _weightController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _inputDecoration(
                                          "Total Cargo Weight (KG)",
                                          Icons.scale,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            if (_routes.isNotEmpty) ...[
                              const Text(
                                "Select Route",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 105,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _routes.length,
                                  itemBuilder: (context, index) {
                                    final route = _routes[index];
                                    final isSelected =
                                        index == _selectedRouteIndex;
                                    Color badgeColor = Colors.grey.shade700;
                                    if (route.label == "FASTEST ROUTE") {
                                      badgeColor = Colors.green.shade700;
                                    } else if (route.label ==
                                        "SHORTEST ROUTE") {
                                      badgeColor = Colors.blue.shade700;
                                    } else if (route.label ==
                                        "LOW TRAFFIC ROUTE") {
                                      badgeColor = Colors.amber.shade800;
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedRouteIndex = index;
                                        });
                                        _updateRouteUI();
                                      },
                                      child: Container(
                                        width: 200,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue.shade50
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue.shade500
                                                : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                route.label,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              route.summary,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.blue.shade800
                                                    : Colors.black87,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${route.distanceKm.toStringAsFixed(1)} KM",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  route.durationText,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildDriverMatchingCard(),

                            const Text(
                              "Passenger Details",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                "Full Name",
                                Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _inputDecoration(
                                "Phone Number",
                                Icons.phone_outlined,
                              ),
                            ),

                            const SizedBox(height: 32),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // FINAL PRICE DISPLAY
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Estimated Total",
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        PricingEngine.formatCurrency(
                                          _totalPrice,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _submitBooking,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            "Confirm Ride",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGET EXTRACTS ---
  Widget _buildSearchField(
    TextEditingController controller,
    String hint,
    bool isPickup,
  ) {
    return TextField(
      controller: controller,
      onTap: () {
        _onSearchChanged(controller.text, isPickup);
      },
      onChanged: (val) => _onSearchChanged(val, isPickup),
      onSubmitted: (_) => _calculateDistance(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 18),
                onPressed: () => setState(() {
                  controller.clear();
                  _placePredictions.clear();
                }),
              )
            : null,
      ),
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }

  Widget _buildLocationChip(IconData icon, String label, String address) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: Colors.blue),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() {
            if (_pickupController.text.isEmpty) {
              _pickupController.text = address;
            } else {
              _destinationController.text = address;
              _calculateDistance();
            }
          });
        },
      ),
    );
  }

  Widget _buildDriverMatchingCard() {
    if (_driverMatchingConfig == null) return const SizedBox.shrink();
    final config = _driverMatchingConfig!;
    final String driverDist =
        "${config.driverDistanceKm.toStringAsFixed(1)} KM away";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Driver Matching Info",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ETA: ${config.estimatedArrival}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMatchingMetric(
                Icons.person_pin_circle,
                "Nearest Driver",
                driverDist,
              ),
              _buildMatchingMetric(
                Icons.analytics,
                "Route Score",
                "${(100 - (config.routeScore.clamp(0, 100))).toStringAsFixed(0)}%",
              ),
              _buildMatchingMetric(
                Icons.traffic,
                "Traffic Delay",
                config.trafficScore > 0
                    ? "${config.trafficScore.toStringAsFixed(0)} mins"
                    : "No Delay",
                valueColor: config.trafficScore > 5
                    ? Colors.red.shade700
                    : config.trafficScore > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingMetric(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFleetSelector(VehicleCapacity capacity) {
    int count = _fleet[capacity] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  capacity.name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.black54,
                  ),
                  onPressed: () => setState(() {
                    _fleet[capacity] = (count > 0) ? count - 1 : 0;
                    _recalculatePrice();
                  }),
                ),
                SizedBox(
                  width: 20,
                  child: Center(
                    child: Text(
                      "$count",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.black87),
                  onPressed: () => setState(() {
                    _fleet[capacity] = count + 1;
                    _recalculatePrice();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.black54, size: 22)
          : null,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}

// ==========================================================
// MAP PICKER SCREEN (Center Pin Navigation)
// ==========================================================
class MapPickerResult {
  final LatLng location;
  final String address;
  MapPickerResult({required this.location, required this.address});
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerScreen({super.key, required this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _currentLocation;
  bool _isMoving = false;
  String _currentAddress = "Select location on map";
  bool _isResolving = false;
  Timer? _resolveDebounce;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialPosition;
    _resolveAddress(_currentLocation);
  }

  @override
  void dispose() {
    _resolveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _resolveAddress(LatLng position) async {
    if (!mounted) return;
    setState(() => _isResolving = true);
    final String osmUrl =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1";
    try {
      final response = await http
          .get(
            Uri.parse(osmUrl),
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent': 'TransovaApp/1.0 (contact@transova.com)',
                    'Accept-Language': 'en',
                  },
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final address = data['address'];
        String name = "";
        if (address != null) {
          final parts = <String>[];
          final amenity =
              address['amenity'] ??
              address['shop'] ??
              address['tourism'] ??
              address['historic'] ??
              address['building'] ??
              address['office'];
          if (amenity != null) parts.add(amenity.toString());
          final road =
              address['road'] ?? address['pedestrian'] ?? address['street'];
          if (road != null) parts.add(road.toString());
          final suburb =
              address['suburb'] ?? address['neighbourhood'] ?? address['city'];
          if (suburb != null) parts.add(suburb.toString());

          if (parts.isNotEmpty) {
            if (parts.length > 2) {
              name = parts.take(3).join(', ');
            } else {
              name = parts.join(', ');
            }
          }
        }
        if (name.isEmpty && data['display_name'] != null) {
          final parts = data['display_name'].toString().split(', ');
          name = parts.take(3).join(', ');
        }
        if (name.isNotEmpty) {
          setState(() {
            _currentAddress = name;
            _isResolving = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Picker Geocoding error: $e");
    }
    if (mounted) {
      setState(() {
        _currentAddress =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        _isResolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Drag Map to Pin",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 16,
            ),
            onCameraMoveStarted: () => setState(() => _isMoving = true),
            onCameraMove: (CameraPosition position) =>
                _currentLocation = position.target,
            onCameraIdle: () {
              setState(() => _isMoving = false);
              _resolveDebounce?.cancel();
              _resolveDebounce = Timer(const Duration(milliseconds: 400), () {
                _resolveAddress(_currentLocation);
              });
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 40.0,
            ), // Offsets the pinpoint tip to true center
            child: Icon(
              Icons.location_on,
              size: 54,
              color: _isMoving ? Colors.black54 : Colors.black,
            ),
          ),
          // Interactive Bottom Info and Confirm Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "SELECTED POSITION",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      if (_isResolving)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isResolving
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                MapPickerResult(
                                  location: _currentLocation,
                                  address: _currentAddress,
                                ),
                              );
                            },
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
