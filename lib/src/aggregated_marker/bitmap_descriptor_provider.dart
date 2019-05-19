import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class AggregatedBitmapDescriptorProvider {
  Future<BitmapDescriptor> get(double zoom, int pointsCount);
}

