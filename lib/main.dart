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
String publishableKey = "prj_test_pk_...";

class RadarMapsState extends State<RadarMapsDemo> {
  late MaplibreMapController mapController;

  // async helper function to load image from assets
  Future<ui.Image> _loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  // helper to add images to map
  Future<void> _addImageFromAsset(String name, String assetName) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Image image = await _loadImage(new Uint8List.view(data.buffer));
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imgBytes = byteData!.buffer.asUint8List();
    mapController.addImage(name, imgBytes);
  }

  // add the marker to the map as a symbol
  void _addMarker() {
    mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(37.7749, -122.4194), // Latitude and Longitude of the marker
        iconImage: "marker",
        iconSize: 1.5,
      ),
    );
  }

  // callback on map initialization
  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
  }

  // callback on may style loaded (initial render)
  void _onStyleLoaded() {
    _addImageFromAsset("marker", "images/marker.png");
    _addMarker();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: MaplibreMap(
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          styleString: 'https://api.radar.io/maps/styles/$style?publishableKey=$publishableKey',
          initialCameraPosition: CameraPosition(
            target: LatLng(37.7749, -122.4194), // initial position of the map (San Francisco)
            zoom: 12.0,
          ),
        ),
      ),
    );
  }
}
