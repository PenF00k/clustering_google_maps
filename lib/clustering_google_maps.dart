library clustering_google_maps;

import 'dart:async';

import 'package:clustering_google_maps/src/aggregated_marker/aggregated_bitmap_descriptors.dart';
import 'package:clustering_google_maps/src/aggregated_marker/bitmap_descriptor_provider.dart';
import 'package:clustering_google_maps/src/db_helper.dart';
import 'package:clustering_google_maps/src/single_marker/bitmap_descriptor_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

export 'package:clustering_google_maps/src/lat_lang_geohash.dart';

export 'src/aggregated_marker/aggregated_bitmap_descriptors.dart';
export 'src/aggregated_marker/bitmap_descriptor_provider.dart';
export 'src/aggregated_marker/round_bitmap_descriptor_provider.dart';
export 'src/single_marker/bitmap_descriptor_provider.dart';

typedef GroupMarkerTappedCallback = Function(double zoom, LatLng location);

class ClusteringHelper<T, E> {
  ClusteringHelper.forDB({
    @required this.dbTable,
    @required this.dbLatColumn,
    @required this.dbLongColumn,
    @required this.dbGeohashColumn,
    @required this.updateMarkers,
    this.database,
    this.maxZoomForAggregatePoints = 13.5,
    this.singleBitmapDescriptorProvider,
    this.whereClause = "",
    @required this.aggregatedBitmapDescriptorProvider,
  })  : assert(dbTable != null),
        assert(dbGeohashColumn != null),
        assert(dbLongColumn != null),
        assert(dbLatColumn != null);

  ClusteringHelper.forMemory({
    @required this.list,
    @required this.updateMarkers,
    this.maxZoomForAggregatePoints = 13.5,
    double initialZoom,
    this.singleBitmapDescriptorProvider,
    @required this.aggregatedBitmapDescriptorProvider,
    this.onGroupMarkerPressed,
  })  : assert(list != null),
        _currentZoom = initialZoom;

  //After this value the map show the single points without aggregation
  final double maxZoomForAggregatePoints;

  //Database where we performed the queries
  Database database;

  //Name of table of the databasa SQLite where are stored the latitude, longitude and geoahash value
  String dbTable;

  //Name of column where is stored the latitude
  String dbLatColumn;

  //Name of column where is stored the longitude
  String dbLongColumn;

  //Name of column where is stored the geohash value
  String dbGeohashColumn;

  //Strategy to provide single bitmap descriptor
  final SingleBitmapDescriptorProvider<T, E> singleBitmapDescriptorProvider;

  //Where clause for query db
  String whereClause;

  //Variable for save the last zoom
  double _currentZoom = 0.0;

  //Function called when the map must show single point without aggregation
  // if null the class use the default function
  Function showSinglePoint;

  //Function for update Markers on Google Map
  Function(Set<Marker> markers) updateMarkers;

  //List of points for memory clustering
  List<PointDescriptor> list;

  //Strategy to provide group bitmap descriptor
  AggregatedBitmapDescriptorProvider aggregatedBitmapDescriptorProvider;

  // Callback called when group marker is tapped
  GroupMarkerTappedCallback onGroupMarkerPressed;

  //Call during the editing of CameraPosition
  //If you want updateMap during the zoom in/out set forceUpdate to true
  //this is NOT RECCOMENDED
  onCameraMove(CameraPosition position, {forceUpdate = false}) {
    _currentZoom = position.zoom;
    if (forceUpdate) {
      updateMap();
    }
  }

  //Call when user stop to move or zoom the map
  Future<void> onMapIdle() async {
    updateMap();
  }

  updateMap() {
    if (_currentZoom < maxZoomForAggregatePoints) {
      updateAggregatedPoints(zoom: _currentZoom);
    } else {
      if (showSinglePoint != null) {
        showSinglePoint();
      } else {
        updatePoints(_currentZoom);
      }
    }
  }

  // Used for update list
  // NOT RECCOMENDED for good performance (SQL IS BETTER)
  updateData(List<PointDescriptor> newList) {
    list = newList;
    updateMap();
  }

  Future<List<AggregatedBitmapDescriptors>> getAggregatedPoints(double zoom) async {
    print("loading aggregation");
    int level = 5;

    if (zoom <= 3) {
      level = 1;
    } else if (zoom < 5) {
      level = 2;
    } else if (zoom < 7.5) {
      level = 3;
    } else if (zoom < 10.5) {
      level = 4;
    } else if (zoom < 13) {
      level = 5;
    } else if (zoom < 13.5) {
      level = 6;
    } else if (zoom < 14.5) {
      level = 7;
    }

    try {
      List<AggregatedBitmapDescriptors> aggregatedPoints;
      if (database != null) {
        aggregatedPoints = await DBHelper.getAggregatedPoints(
            database: database,
            dbTable: dbTable,
            dbLatColumn: dbLatColumn,
            dbLongColumn: dbLongColumn,
            dbGeohashColumn: dbGeohashColumn,
            level: level,
            singleBitmapDescriptorProvider: singleBitmapDescriptorProvider,
            whereClause: whereClause);
      } else {
        aggregatedPoints = _retrieveAggregatedPoints(list, List(), level);
      }
      return aggregatedPoints;
    } catch (e) {
      print(e.toString());
      return List<AggregatedBitmapDescriptors>();
    }
  }

  // NOT RECCOMENDED for good performance (SQLite IS BETTER)
  List<AggregatedBitmapDescriptors> _retrieveAggregatedPoints(
      List<PointDescriptor> inputList, List<AggregatedBitmapDescriptors> resultList, int level) {
//    print("input list lenght: " + inputList.length.toString());

    if (inputList.isEmpty) {
      return resultList;
    }
    final List<PointDescriptor<E>> newInputList = List.from(inputList);
    List<PointDescriptor<E>> tmp;
    final t = newInputList[0].latLngAndGeohash.geohash.substring(0, level);
    tmp = newInputList.where((p) => p.latLngAndGeohash.geohash.substring(0, level) == t).toList();
    newInputList.removeWhere((p) => p.latLngAndGeohash.geohash.substring(0, level) == t);
    double latitude = 0;
    double longitude = 0;
    tmp.forEach((l) {
      latitude += l.latLngAndGeohash.location.latitude;
      longitude += l.latLngAndGeohash.location.longitude;
    });
    final count = tmp.length;

    PointDescriptor<E> data = count == 1 ? tmp[0] : null;

    final a = AggregatedBitmapDescriptors<T, E>(
        LatLng(latitude / count, longitude / count), count, data, singleBitmapDescriptorProvider);
    resultList.add(a);
    return _retrieveAggregatedPoints(newInputList, resultList, level);
  }

  Future<void> updateAggregatedPoints({double zoom = 0.0}) async {
    List<AggregatedBitmapDescriptors<T, E>> aggregation = await getAggregatedPoints(zoom);
    print("aggregation lenght: " + aggregation.length.toString());

    final markers = aggregation.map<Future<Marker>>((a) async {
      BitmapDescriptor bitmapDescriptor = BitmapDescriptor.defaultMarker;
      Marker marker;
      if (a.count == 1) {
//        bitmapDescriptor = singleBitmapDescriptorProvider ?? BitmapDescriptor.defaultMarker;
        marker = await a.singleBitmapDescriptorProvider.get(a.dataForSinglePoint.data);
      } else {
        // >1
//        bitmapDescriptor = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), a.bitmabAssetName);
        bitmapDescriptor = await aggregatedBitmapDescriptorProvider.get(zoom, a.count);
//        bitmapDescriptor = BitmapDescriptor.fromAsset(a.bitmabAssetName, package: "clustering_google_maps");
      }
      final MarkerId markerId = MarkerId(a.getId());

      if (marker != null) return marker;

      return Marker(
        markerId: markerId,
        position: a.location,
//        infoWindow: InfoWindow(title: a.count.toString()),
        icon: bitmapDescriptor,
        onTap: () {
          onGroupMarkerPressed(_currentZoom, a.location);
        },
      );
    });

    List<Marker> res = await Future.wait(markers);

    if (res.length == 0) res = <Marker>[];

    updateMarkers(res.toSet());
  }

  updatePoints(double zoom) async {
    print("update single points");
    try {
      List<PointDescriptor> listOfPoints;
      if (database != null) {
        listOfPoints = await DBHelper.getPoints(
            database: database,
            dbTable: dbTable,
            dbLatColumn: dbLatColumn,
            dbLongColumn: dbLongColumn,
            singleBitmapDescriptorProvider: singleBitmapDescriptorProvider,
            whereClause: whereClause);
      } else {
        listOfPoints = list;
//            .map((pd) => singleBitmapDescriptorProvider.createPointDescriptor(pd.latLngAndGeohash, data: pd.data))
//            .toList();
      }

      final markers = listOfPoints.map((p) async {
        final marker = await singleBitmapDescriptorProvider.get(p.data);
        if (marker != null) return marker;

        final MarkerId markerId = MarkerId(p.latLngAndGeohash.getId());
        return Marker(
          markerId: markerId,
          position: p.latLngAndGeohash.location,
          infoWindow: InfoWindow(
              title:
                  "${p.latLngAndGeohash.location.latitude.toStringAsFixed(2)},${p.latLngAndGeohash.location.longitude.toStringAsFixed(2)}"),
          icon: BitmapDescriptor.defaultMarker,
        );
      });

      List<Marker> res = await Future.wait(markers);

      if (res.length == 0) res = <Marker>[];

      updateMarkers(res.toSet());
    } catch (ex) {
      print(ex.toString());
    }
  }
}
