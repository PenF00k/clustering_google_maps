import 'package:clustering_google_maps/src/aggregated_marker/aggregated_bitmap_descriptors.dart';
import 'package:clustering_google_maps/src/lat_lang_geohash.dart';
import 'package:clustering_google_maps/src/single_marker/bitmap_descriptor_provider.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Future<List<AggregatedBitmapDescriptors>> getAggregatedPoints(
      {@required Database database,
      @required String dbTable,
      @required String dbLatColumn,
      @required String dbLongColumn,
      @required String dbGeohashColumn,
      @required int level,
      @required SingleBitmapDescriptorProvider singleBitmapDescriptorProvider,
      String whereClause = ""}) async {
    print("--------- START QUERY AGGREGATION");
    try {
      if (database == null) {
        throw Exception("Database must not be null");
      }
      var result =
          await database.rawQuery('SELECT COUNT(*) as n_marker, AVG($dbLatColumn) as lat, AVG($dbLongColumn) as long '
              'FROM $dbTable $whereClause GROUP BY substr($dbGeohashColumn,1,$level);');

      List<AggregatedBitmapDescriptors> aggregatedPoints = new List();

      for (Map<String, dynamic> item in result) {
        print(item);
        var p =
            new AggregatedBitmapDescriptors.fromMap(item, dbLatColumn, dbLongColumn, singleBitmapDescriptorProvider);
        aggregatedPoints.add(p);
      }
      print("--------- COMPLETE QUERY AGGREGATION");
      return aggregatedPoints;
    } catch (e) {
      print(e.toString());
      print("--------- COMPLETE QUERY AGGREGATION WITH ERROR");
      return List<AggregatedBitmapDescriptors>();
    }
  }

  static Future<List<PointDescriptor>> getPoints(
      {@required Database database,
      @required String dbTable,
      @required String dbLatColumn,
      @required String dbLongColumn,
      @required SingleBitmapDescriptorProvider singleBitmapDescriptorProvider,
      String whereClause = ""}) async {
    try {
      var result = await database.rawQuery('SELECT $dbLatColumn as lat, $dbLongColumn as long '
          'FROM $dbTable $whereClause;');
      List<LatLngAndGeohash> points = new List();
      for (Map<String, dynamic> item in result) {
        var p = new LatLngAndGeohash.fromMap(item);
        points.add(p);
      }
      print("--------- COMPLETE QUERY");
      return points.map((llgh) => singleBitmapDescriptorProvider.createPointDescriptor(llgh)).toList();
    } catch (e) {
      print(e.toString());
      return List<PointDescriptor>();
    }
  }
}
