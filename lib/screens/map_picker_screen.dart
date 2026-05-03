import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../utils/configs.dart';

/// Default fallback location: centre of India
const LatLng _kDefaultLocation = LatLng(20.5937, 78.9629);

class MapPickerScreen extends StatefulWidget {
  /// Optional initial location. If null, tries current GPS location.
  final LatLng? initialLocation;

  const MapPickerScreen({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;

  /// The position currently centred in the camera – i.e. the "picked" location.
  LatLng _pickedLocation = _kDefaultLocation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initLocation() async {
    if (widget.initialLocation != null) {
      setState(() {
        _pickedLocation = widget.initialLocation!;
        _isLoading = false;
      });
      return;
    }

    try {
      final permission = await _requestPermission();
      if (permission) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _pickedLocation = LatLng(pos.latitude, pos.longitude);
            _isLoading = false;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_pickedLocation),
          );
        }
      } else {
        toast(languages.lblLocationRequired);
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      log('MapPickerScreen location error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns true if location permission is granted.
  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(languages.lblPickLocation, style: boldTextStyle()),
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.iconColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: context.scaffoldBackgroundColor,
          statusBarIconBrightness:
              appStore.isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            mapType: MapType.normal,
            compassEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            // Track where camera centre is – that is the picked location.
            onCameraMove: (CameraPosition position) {
              _pickedLocation = position.target;
            },
            onCameraIdle: () {
              // Update the coordinate display when camera stops.
              if (mounted) setState(() {});
            },
          ),

          // ── Centre pin (static overlay) ──────────────────────────────────
          const Center(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: 48), // move up by half-pin height
              child: Icon(Icons.location_pin, color: Colors.red, size: 48),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: LoaderWidget(),
            ),

          // ── Bottom sheet: coordinates + confirm ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinate display
                  Text(
                    'Lat: ${_pickedLocation.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_pickedLocation.longitude.toStringAsFixed(6)}',
                    style: secondaryTextStyle(size: 13),
                  ),
                  12.height,
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: languages.lblConfirmLocation,
                      color: primaryColor,
                      textStyle: boldTextStyle(color: white),
                      height: 44,
                      onTap: () {
                        Navigator.pop(context, _pickedLocation);
                      },
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
