import 'package:clustering_google_maps/src/single_marker/bitmap_descriptor_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AggregatedBitmapDescriptors<T, E> {
  final LatLng location;
  final int count;
  final PointDescriptor<E> dataForSinglePoint;
  final SingleBitmapDescriptorProvider<T, E> singleBitmapDescriptorProvider;

  AggregatedBitmapDescriptors(this.location, this.count, this.dataForSinglePoint, this.singleBitmapDescriptorProvider);

  AggregatedBitmapDescriptors.fromMap(
      Map<String, dynamic> map, String dbLatColumn, String dbLongColumn, this.singleBitmapDescriptorProvider,
      {this.dataForSinglePoint})
      : count = map['n_marker'],
        this.location = LatLng(map['lat'], map['long']);

  getId() {
    return location.latitude.toString() + "_" + location.longitude.toString() + "_$count";
  }
}
