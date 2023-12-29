import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  runApp(RadarMapsDemo());
}

class RadarMapsDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

String style = "radar-default-v1";
String publishableKey = "prj_test_pk_...";

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaplibreMap(
        styleString: 'https://api.radar.io/maps/styles/$style?publishableKey=$publishableKey',
        initialCameraPosition: CameraPosition(
          target: LatLng(40.7128, -74.0060), // example coordinates (New York City)
          zoom: 11.0,
        ),
      ),
    );
  }
}
