import 'package:clustering_google_maps/src/lat_lang_geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class SingleBitmapDescriptorProvider<T, E> {
  final PointDescriptor _pointDescriptor;

  SingleBitmapDescriptorProvider(this._pointDescriptor);

  PointDescriptor get pointDescriptor => _pointDescriptor;

  Future<Marker> get<E>(E data);
}

abstract class PointDescriptor<E> {
  final LatLngAndGeohash _latLngAndGeohash;

  PointDescriptor(this._latLngAndGeohash);

  LatLngAndGeohash get latLngAndGeohash => _latLngAndGeohash;

  E get data;
}

//abstract class PointDescriptor {
//  final LatLng _latLng;
//
//  PointDescriptor(this._latLng);
//
//  String getId();
//
//  LatLng get latLng => _latLng;
//
//  String get geohash => Geohash.encode(latLng.latitude, latLng.longitude);
//}
