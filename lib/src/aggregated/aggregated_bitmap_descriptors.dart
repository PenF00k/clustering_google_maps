import 'package:google_maps_flutter/google_maps_flutter.dart';

class AggregatedBitmapDescriptors {
  final LatLng location;
  final int count;

  AggregatedBitmapDescriptors(this.location, this.count);

  AggregatedBitmapDescriptors.fromMap(Map<String, dynamic> map, String dbLatColumn, String dbLongColumn)
      : count = map['n_marker'],
        this.location = LatLng(map['lat'], map['long']);

  getId() {
    return location.latitude.toString() + "_" + location.longitude.toString() + "_$count";
  }
}
