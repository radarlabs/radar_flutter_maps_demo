import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  runApp(RadarMapsDemo());
}

class RadarMapsDemo extends StatefulWidget {
  @override
  RadarMapsState createState() => RadarMapsState();
}

String style = "radar-default-v1";
String publishableKey = "prj_live_pk_...";

class RadarMapsState extends State<RadarMapsDemo> {
  // map state
  late MaplibreMapController mapController;
  List<Symbol> markers = [];
  bool isCameraMovingProgrammatically = false;

  // state for info window
  LatLng? infoWindowPosition;
  Symbol? hqMarker;
  Symbol? selectedMarker;
  bool showInfoWindow = false;
  String infoWindowText = "";

  // async helper function to load image from assets
  Future<ui.Image> _loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  // helper to prepare images for map use
  Future<void> _addImageFromAsset(String name, String assetName) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Image image = await _loadImage(new Uint8List.view(data.buffer));
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imgBytes = byteData!.buffer.asUint8List();
    mapController.addImage(name, imgBytes);
  }

  // add the marker to the map at the given LatLng
  void _addMarker(LatLng latLng) async {
    final Symbol marker = await mapController.addSymbol(
      SymbolOptions(
        geometry: latLng,
        iconImage: "marker",
        iconSize: 1,
      ),
    );
    markers.add(marker);
  }

  // center map on given LatLng
  void _centerMapOnPosition(LatLng latLng) {
    setState(() {
      isCameraMovingProgrammatically = true; // user is not moving the map
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 14.0),
      ),
    ).then((_) {
      Future.delayed(Duration(seconds: 1), () { // wait for animation to complete
        setState(() {
          isCameraMovingProgrammatically = false; // camera movement finished
        });
      });
    });
  }

  // handle tap on marker
  void _onMarkerTapped(Symbol symbol) {
    String text = "";
    if (symbol == hqMarker) {
      text = "Radar HQ";
    } else {
      int index = markers.indexOf(symbol);
      text = "Marker ${index + 1}";
    }

    setState(() {
      selectedMarker = symbol;
      infoWindowPosition = symbol.options.geometry;
      showInfoWindow = true;
      infoWindowText = text;
    });

    _centerMapOnPosition(symbol.options.geometry!);
  }

  // create a new InfoWindow
  Widget _buildInfoWindow(Symbol? marker) {
    if (marker == null) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(infoWindowText),
      ),
    );
  }

  void _hideInfoWindow() {
    if (!isCameraMovingProgrammatically && showInfoWindow) {
      setState(() {
        showInfoWindow = false;
      });
    }
  }

  // add Radar logo to map
  Widget _buildLogo() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Image.asset(
        'images/logo.png',
        width: 74,
      ),
    );
  }

  // callback on map initialization
  void _onMapCreated(MaplibreMapController controller) async {
    mapController = controller;
    mapController.onSymbolTapped.add(_onMarkerTapped);
    await mapController.setSymbolIconAllowOverlap(true);
    await mapController.setSymbolIconIgnorePlacement(true);
  }

  // callback on may style loaded (initial render)
  void _onStyleLoaded() async {
    _addImageFromAsset("hq", "images/hq.png");
    _addImageFromAsset("marker", "images/marker.png");

    // add Radar logo to the map at HQ
    final Symbol hq = await mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(40.7342891, -73.9910334), // Latitude and Longitude of the marker
        iconImage: "hq",
        iconSize: 0.5,
      ),
    );
    hqMarker = hq;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // map
            MaplibreMap(
              styleString: 'https://api.radar.io/maps/styles/$style?publishableKey=$publishableKey',
              initialCameraPosition: CameraPosition(
                target: LatLng(40.7342891, -73.9910334), // initial position of the map (Radar HQ)
                zoom: 12.0,
              ),
              tiltGesturesEnabled: false,  // disable tilt gestures
              rotateGesturesEnabled: false,  // disable rotate gestures
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              onCameraIdle: () => _hideInfoWindow(),
              onMapClick: (point, latLng) async {
                _addMarker(latLng);
              },
            ),

            // info window
            if (showInfoWindow && infoWindowPosition != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16, // Adjust this value for desired position
                left: 0,
                right: 0,
                child: Center(
                  child: _buildInfoWindow(selectedMarker),
                ),
              ),

            // Radar logo
            Positioned(
              left: 10,
              bottom: 30,
              child: _buildLogo(),
            ),
          ]
        ),
      ),
    );
  }
}
