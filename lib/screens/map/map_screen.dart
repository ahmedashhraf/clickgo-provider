import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/services/location_service.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/constant.dart';

class MapScreen extends StatefulWidget {
  final double? latLong;
  final double? latitude;

  MapScreen({this.latLong, this.latitude});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  String? mapStyle;

  String _currentAddress = '';

  final destinationAddressController = TextEditingController();
  final destinationAddressFocusNode = FocusNode();

  String _destinationAddress = '';

  Set<Marker> markers = {};
  LatLng? _pickedLocation;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    if (appStore.isDarkMode) {
      DefaultAssetBundle.of(context)
          .loadString('assets/json/map_style_dark.json')
          .then((value) {
        mapStyle = value;
        setState(() {});
      }).catchError(onError);
    }
    afterBuildCreated(() {
      _getCurrentLocation();
    });
  }

  // Method for retrieving the current location
  void _getCurrentLocation() async {
    if (widget.latitude != null && widget.latLong != null) {
      _handleTap(LatLng(widget.latitude!, widget.latLong!));
      return;
    }
    appStore.setLoading(true);
    await getUserLocationPosition().then((position) async {
      setAddress();

      _pickedLocation = LatLng(position.latitude, position.longitude);

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickedLocation!, zoom: 18.0),
        ),
      );

      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId(_currentAddress),
          position: _pickedLocation!,
          infoWindow: InfoWindow(
              title: 'Start $_currentAddress', snippet: _destinationAddress),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );

      setState(() {});
    }).catchError((e) {
      toast(e.toString());
    });

    appStore.setLoading(false);
  }

  // Method for retrieving the address
  Future<void> setAddress() async {
    try {
      Position position = await getUserLocationPosition().catchError((e) {
        throw e;
      });

      _currentAddress = await buildFullAddressFromLatLong(
              position.latitude, position.longitude)
          .catchError((e) {
        log(e);
        throw e;
      });
      destinationAddressController.text = _currentAddress;
      _destinationAddress = _currentAddress;

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  _handleTap(LatLng point) async {
    _pickedLocation = point;
    appStore.setLoading(true);

    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: const InfoWindow(),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );

    destinationAddressController.text =
        await buildFullAddressFromLatLong(point.latitude, point.longitude)
            .catchError((e) {
      throw e;
    });

    _destinationAddress = destinationAddressController.text;

    appStore.setLoading(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBarWidget(
        languages.chooseYourLocation,
        backWidget: BackWidget(),
        color: primaryColor,
        elevation: 0,
        textColor: white,
        textSize: APP_BAR_TEXT_SIZE,
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            markers: Set<Marker>.from(markers),
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            style: mapStyle,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) async {
              mapController = controller;
              if (widget.latitude != null && widget.latLong != null) {
                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(widget.latitude!, widget.latLong!),
                        zoom: 18.0),
                  ),
                );
              }
            },
            onTap: _handleTap,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ClipOval(
                  child: Material(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    child: InkWell(
                      splashColor: context.primaryColor.withValues(alpha: 0.8),
                      child: const SizedBox(
                          width: 50, height: 50, child: Icon(Icons.add)),
                      onTap: () {
                        mapController.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ClipOval(
                  child: Material(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    child: InkWell(
                      splashColor: context.primaryColor.withValues(alpha: 0.8),
                      child: const SizedBox(
                          width: 50, height: 50, child: Icon(Icons.remove)),
                      onTap: () {
                        mapController.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                  ),
                ),
              ],
            ).paddingLeft(10),
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipOval(
                  child: Material(
                    color: context.primaryColor
                        .withValues(alpha: 0.2), // button color
                    child:
                        const Icon(Icons.my_location, size: 25).paddingAll(10),
                  ),
                ).paddingRight(8).onTap(() async {
                  appStore.setLoading(true);

                  await getUserLocationPosition().then((value) {
                    mapController.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                            target: LatLng(value.latitude, value.longitude),
                            zoom: 18.0),
                      ),
                    );

                    _handleTap(LatLng(value.latitude, value.longitude));
                  }).catchError(onError);

                  appStore.setLoading(false);
                }),
                8.height,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppTextField(
                      textFieldType: TextFieldType.MULTILINE,
                      controller: destinationAddressController,
                      focus: destinationAddressFocusNode,
                      textStyle: primaryTextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white
                              : Colors.black),
                      decoration:
                          inputDecoration(context, hint: languages.hintAddress)
                              .copyWith(
                                  fillColor: appStore.isDarkMode
                                      ? Colors.black54
                                      : Colors.white70),
                    ),
                  ],
                ),
                8.height,
                AppButton(
                  width: context.width(),
                  height: 16,
                  color: primaryColor.withValues(alpha: 0.8),
                  text: languages.setAddress.toUpperCase(),
                  textStyle: boldTextStyle(color: white, size: 12),
                  onTap: () {
                    if (destinationAddressController.text.isNotEmpty &&
                        _pickedLocation != null) {
                      finish(context, {
                        'address': destinationAddressController.text,
                        'latitude': _pickedLocation!.latitude,
                        'longitude': _pickedLocation!.longitude,
                      });
                    } else {
                      toast(languages.lblPickAddress);
                    }
                  },
                ),
                8.height,
              ],
            ).paddingAll(16),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
