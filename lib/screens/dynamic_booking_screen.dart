// Location: lib/screens/dynamic_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pricing_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DynamicBookingScreen extends StatefulWidget {
  final String? initialServiceType;

  const DynamicBookingScreen({super.key, this.initialServiceType});

  @override
  State<DynamicBookingScreen> createState() => _DynamicBookingScreenState();
}

class _DynamicBookingScreenState extends State<DynamicBookingScreen> {
  // --- EXISTING STATE VARIABLES ---
  ServiceCategory _selectedService = ServiceCategory.wedding;
  final Map<VehicleCapacity, int> _fleet = {};

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

  // --- MAP & LOCATION STATE VARIABLES ---
  final String _googleApiKey = "AIzaSyDg_iklQdlv-pMqy7R3zAPgai2hBeyElrU";
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<dynamic> _placePredictions = [];
  bool _isSearchingPickup = false;
  bool _isSearchingDest = false;
  Timer? _debounce;
  String _estimatedDuration = "";

  @override
  void initState() {
    super.initState();

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
  // NOTIFICATION SERVICES (SMS & EMAIL)
  // ==========================================================

  Future<void> _sendSmsNotification(String phoneNumber, double price) async {
    // In production, trigger this via a Firebase Cloud Function for security.
    debugPrint("Triggering SMS to $phoneNumber for amount: $price");

    // Logic: Post to your SMS Gateway (Twilio/Africa's Talking)
    // await http.post(Uri.parse('https://your-server.com/send-sms'), ...);
  }

  Future<void> _sendEmailNotification(String email, double price) async {
    // Best Practice: Write to a 'mail' collection in Firestore.
    // The Firebase "Trigger Email" extension will handle the rest.
    try {
      await FirebaseFirestore.instance.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'TRANSOVA Booking Confirmation',
          'html': '<h1>Booking Received!</h1><p>Your booking for ${PricingEngine.formatCurrency(price)} is being processed.</p>',
        },
      });
      debugPrint("Email notification queued for $email");
    } catch (e) {
      debugPrint("Email error: $e");
    }
  }

  // ==========================================================
  // HELPER: WEB CORS PROXY
  // ==========================================================
  Uri _buildGoogleApiUri(String googleUrl) {
    if (kIsWeb) {
      return Uri.parse("https://corsproxy.io/?${Uri.encodeComponent(googleUrl)}");
    }
    return Uri.parse(googleUrl);
  }

  // ==========================================================
  // 1. SMART LOCATION & GPS DETECTION
  // ==========================================================
  Future<void> _determineCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _pickupLatLng = LatLng(position.latitude, position.longitude);

    _updateMapCamera(_pickupLatLng!);
    _setMarker(_pickupLatLng!, "pickup", "Current Location");
    await _getAddressFromLatLng(_pickupLatLng!, isPickup: true);
  }

  Future<void> _getAddressFromLatLng(LatLng position, {required bool isPickup}) async {
    final String urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_googleApiKey";
    final url = _buildGoogleApiUri(urlString);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            if (isPickup) {
              _pickupController.text = data['results'][0]['formatted_address'];
            } else {
              _destinationController.text = data['results'][0]['formatted_address'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
  }

  // ==========================================================
  // 2. LIVE AUTOCOMPLETE & PLACES API
  // ==========================================================
  void _onSearchChanged(String query, bool isPickup) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _placePredictions = []);
        return;
      }
      setState(() {
        _isSearchingPickup = isPickup;
        _isSearchingDest = !isPickup;
      });

      final String urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey";
      final url = _buildGoogleApiUri(urlString);

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            setState(() => _placePredictions = data['predictions']);
          }
        }
      } catch (e) {
        debugPrint("Autocomplete Error: $e");
      }
    });
  }

  Future<void> _getPlaceDetails(String placeId, String description, bool isPickup) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _placePredictions = [];
      _isSearchingPickup = false;
      _isSearchingDest = false;
      if (isPickup) {
        _pickupController.text = description;
      } else {
        _destinationController.text = description;
      }
    });

    final String urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    final url = _buildGoogleApiUri(urlString);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final lat = data['result']['geometry']['location']['lat'];
          final lng = data['result']['geometry']['location']['lng'];
          final latLng = LatLng(lat, lng);

          if (isPickup) {
            _pickupLatLng = latLng;
            _setMarker(latLng, "pickup", "Pickup");
          } else {
            _destinationLatLng = latLng;
            _setMarker(latLng, "destination", "Destination", isDestination: true);
          }

          if (_pickupLatLng != null && _destinationLatLng != null) {
            _drawRouteAndCalculate();
          } else {
            _updateMapCamera(latLng);
          }
        }
      }
    } catch (e) {
      debugPrint("Place Details Error: $e");
    }
  }

  // ==========================================================
  // MAP PICKER LOGIC
  // ==========================================================
  Future<void> _pickLocationOnMap(TextEditingController controller) async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (pickedLocation != null) {
      bool isPickup = controller == _pickupController;

      setState(() {
        if (isPickup) {
          _pickupLatLng = pickedLocation;
          _setMarker(pickedLocation, "pickup", "Pickup");
        } else {
          _destinationLatLng = pickedLocation;
          _setMarker(pickedLocation, "destination", "Destination", isDestination: true);
        }
      });

      await _getAddressFromLatLng(pickedLocation, isPickup: isPickup);

      if (_pickupLatLng != null && _destinationLatLng != null) {
        _drawRouteAndCalculate();
      } else {
        _updateMapCamera(pickedLocation);
      }
    }
  }

  // ==========================================================
  // DISTANCE CALCULATION TRIGGER
  // ==========================================================
  Future<void> _calculateDistance() async {
    FocusScope.of(context).unfocus();
    setState(() => _isCalculatingDistance = true);

    if (_pickupLatLng != null && _destinationLatLng != null) {
      await _drawRouteAndCalculate();
    } else if (_pickupController.text.isNotEmpty && _destinationController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the exact location from the dropdown suggestions or map.'))
      );
    }

    setState(() => _isCalculatingDistance = false);
  }

  // ==========================================================
  // ROUTE, DISTANCE & POLYLINE DRAWING
  // ==========================================================
  void _setMarker(LatLng point, String id, String title, {bool isDestination = false}) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: point,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(isDestination ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen),
      ));
    });
  }

  Future<void> _drawRouteAndCalculate() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    final String urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}&key=$_googleApiKey";
    final url = _buildGoogleApiUri(urlString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];

          final distanceMeters = route['legs'][0]['distance']['value'];
          final double km = distanceMeters / 1000;
          _estimatedDuration = route['legs'][0]['duration']['text'];

          _distanceController.text = km.toStringAsFixed(1);
          _recalculatePrice();

          String encodedPolyline = route['overview_polyline']['points'];
          List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);

          setState(() {
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blueAccent,
              width: 5,
              points: polylineCoordinates,
            ));
          });

          _fitRouteOnMap();
        }
      }
    } catch (e) {
      debugPrint("Routing Error: $e");
    }
  }

  Future<void> _updateMapCamera(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 15)));
  }

  Future<void> _fitRouteOnMap() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    final GoogleMapController controller = await _mapController.future;

    LatLngBounds bounds;
    if (_pickupLatLng!.latitude > _destinationLatLng!.latitude && _pickupLatLng!.longitude > _destinationLatLng!.longitude) {
      bounds = LatLngBounds(southwest: _destinationLatLng!, northeast: _pickupLatLng!);
    } else if (_pickupLatLng!.longitude > _destinationLatLng!.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(_pickupLatLng!.latitude, _destinationLatLng!.longitude),
          northeast: LatLng(_destinationLatLng!.latitude, _pickupLatLng!.longitude));
    } else if (_pickupLatLng!.latitude > _destinationLatLng!.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(_destinationLatLng!.latitude, _pickupLatLng!.longitude),
          northeast: LatLng(_pickupLatLng!.latitude, _destinationLatLng!.longitude));
    } else {
      bounds = LatLngBounds(southwest: _pickupLatLng!, northeast: _destinationLatLng!);
    }

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  // ==========================================================
  // BUSINESS & PRICING LOGIC
  // ==========================================================
  void _recalculatePrice() {
    setState(() {
      _errorMessage = null;
      _totalPrice = 0.0;
    });

    final double distance = double.tryParse(_distanceController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;

    if (distance <= 0) return;

    try {
      if (_selectedService == ServiceCategory.cargo || _selectedService == ServiceCategory.sanitation) {
        final breakdown = PricingEngine.calculateFare(
          distanceKm: distance,
          serviceType: _selectedService,
          vehicleCapacity: VehicleCapacity.cargoVehicle,
          weightKg: weight,
        );
        _totalPrice = breakdown.totalPrice;
      } else {
        _fleet.forEach((capacity, quantity) {
          final breakdown = PricingEngine.calculateFare(
            distanceKm: distance,
            serviceType: _selectedService,
            vehicleCapacity: capacity,
            weightKg: weight,
          );
          _totalPrice += (breakdown.totalPrice * quantity);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Invalid argument(s): ', '');
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all details and add items to your booking.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, int> fleetData = {};
      _fleet.forEach((key, value) => fleetData[key.name] = value);

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerName': _nameController.text,
        'customerPhone': _phoneController.text,
        'pickup': _pickupController.text,
        'destination': _destinationController.text,
        'pickupCoordinates': _pickupLatLng != null ? GeoPoint(_pickupLatLng!.latitude, _pickupLatLng!.longitude) : null,
        'destinationCoordinates': _destinationLatLng != null ? GeoPoint(_destinationLatLng!.latitude, _destinationLatLng!.longitude) : null,
        'estimatedDuration': _estimatedDuration,
        'userId': user?.uid ?? 'guest',
        'serviceType': _selectedService.name,
        'distanceKm': double.tryParse(_distanceController.text) ?? 0,
        'fleet': fleetData,
        'totalPrice': _totalPrice,
        'status': 'pending',
        'assignedDriver': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TRIGGER NOTIFICATIONS
      await _sendSmsNotification(_phoneController.text, _totalPrice);
      if (user?.email != null) {
        await _sendEmailNotification(user!.email!, _totalPrice);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your booking is received, check your email and SMS!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // 5. UBER-STYLE UI BUILDER
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    bool showWeightInput = _selectedService == ServiceCategory.cargo || _selectedService == ServiceCategory.sanitation;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP BACKGROUND
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(-6.816064, 39.280335), zoom: 12),
            onMapCreated: (GoogleMapController controller) => _mapController.complete(controller),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(top: 180, bottom: 400),
          ),

          // 2. BACK BUTTON & FLOATING SEARCH PANEL (TOP)
          Positioned(
            top: 50, left: 16, right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)]),
                  child: Column(
                    children: [
                      TextField(
                        controller: _pickupController,
                        onChanged: (val) => _onSearchChanged(val, true),
                        onSubmitted: (_) => _calculateDistance(),
                        decoration: _inputDecoration("Pickup Location", Icons.circle, iconColor: Colors.green),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _destinationController,
                        onChanged: (val) => _onSearchChanged(val, false),
                        onSubmitted: (_) => _calculateDistance(),
                        decoration: _inputDecoration("Where to?", Icons.square, iconColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. LIVE AUTOCOMPLETE SUGGESTIONS OVERLAY
          if (_placePredictions.isNotEmpty)
            Positioned(
              top: 250, left: 16, right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final place = _placePredictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.grey),
                      title: Text(place['description']),
                      onTap: () => _getPlaceDetails(place['place_id'], place['description'], _isSearchingPickup),
                    );
                  },
                ),
              ),
            ),

          // 4. BOTTOM BOOKING SHEET
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                          const SizedBox(height: 24),

                          DropdownButtonFormField<ServiceCategory>(
                            decoration: _inputDecoration("Service Type", Icons.category),
                            value: _selectedService,
                            items: ServiceCategory.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (val) { if (val != null) setState(() { _selectedService = val; _recalculatePrice(); }); },
                          ),
                          const SizedBox(height: 16),

                          if (!showWeightInput) ...[
                            const Text("Select Fleet", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...VehicleCapacity.values.where((v) => v != VehicleCapacity.cargoVehicle).map((capacity) => _buildFleetSelector(capacity)),
                            const SizedBox(height: 16),
                          ],

                          TextField(
                            controller: _pickupController,
                            decoration: _inputDecoration(
                              "Pickup Location",
                              Icons.my_location,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.map, color: Colors.black),
                                onPressed: () => _pickLocationOnMap(_pickupController),
                              ),
                            ),
                            onEditingComplete: _calculateDistance,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _destinationController,
                            decoration: _inputDecoration(
                              "Destination",
                              Icons.location_on,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.map, color: Colors.black),
                                onPressed: () => _pickLocationOnMap(_destinationController),
                              ),
                            ),
                            onEditingComplete: _calculateDistance,
                          ),
                          const SizedBox(height: 16),

                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                controller: _distanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration("Distance (KM)", Icons.map),
                              ),
                              if (_isCalculatingDistance) const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: showWeightInput
                                ? TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration("Total Weight (KG)", Icons.scale),
                            )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),

                          const Text("Customer Information", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(controller: _nameController, decoration: _inputDecoration("Full Name", Icons.person)),
                          const SizedBox(height: 8),
                          TextField(controller: _phoneController, decoration: _inputDecoration("Phone Number", Icons.phone)),

                          const SizedBox(height: 32),

                          if (_errorMessage != null)
                            Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("ESTIMATED TOTAL:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(PricingEngine.formatCurrency(_totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _submitBooking,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Confirm & Request Fleet", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
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

  Widget _buildFleetSelector(VehicleCapacity capacity) {
    int count = _fleet[capacity] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(capacity.name.toUpperCase()),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => setState(() { _fleet[capacity] = (count > 0) ? count - 1 : 0; _recalculatePrice(); })),
              Text("$count", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: () => setState(() { _fleet[capacity] = count + 1; _recalculatePrice(); })),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Color iconColor = Colors.black54, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
    );
  }
}

// ==========================================================
// MAP PICKER SCREEN
// ==========================================================
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _pickedLocation = const LatLng(-6.816064, 39.280335);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tap map to drop pin", style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _pickedLocation),
            child: const Text("CONFIRM", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _pickedLocation, zoom: 14),
        onTap: (LatLng location) {
          setState(() {
            _pickedLocation = location;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId('picked_location'),
            position: _pickedLocation,
            infoWindow: const InfoWindow(title: 'Selected Location'),
          )
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}