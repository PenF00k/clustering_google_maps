import 'dart:typed_data';
import 'dart:ui';

import 'package:clustering_google_maps/src/aggregated_marker/bitmap_descriptor_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quiver/collection.dart';

class RoundAggregatedBitmapDescriptorProvider implements AggregatedBitmapDescriptorProvider {
  LruMap<int, BitmapDescriptor> cache = LruMap<int, BitmapDescriptor>(maximumSize: 20);

  @override
  Future<BitmapDescriptor> get(double zoom, int pointsCount) async {
    if (cache.containsKey(pointsCount)) {
      return cache[pointsCount];
    }

    final bd = await ClusteringMarkerDrawer.generateMarkerBitmapDescriptor(pointsCount);
    cache[pointsCount] = bd;
    return bd;
  }
}

class ClusteringMarkerDrawer {
  static Future<BitmapDescriptor> generateMarkerBitmapDescriptor(int count,
      {Color color, double diameter, double countFontSize}) async {
    final bytes =
        await drawRoundMarkerWithNumber(count, color: color, diameter: diameter, countFontSize: countFontSize);
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  static Future<ByteData> drawRoundMarkerWithNumber(int count,
      {Color color, double diameter, double countFontSize}) async {
    diameter ??= 120;
    countFontSize ??= 48;

    PictureRecorder recorder = new PictureRecorder();
    Canvas c = new Canvas(recorder);
    final paint = Paint();
    if (color != null) {
      paint.color = color;
    }

//    final double s = markerSize.diameter;
//    final double h = markerSize.arrowHeight;
    final size = Size(diameter, diameter);
    final radius = diameter / 2;

    Offset center = new Offset(radius, radius);
    c.drawCircle(center, radius, paint);

//    // create a path
//    var path = Path();
//    path.moveTo(s * 0.2, (s - h) / 2);
//    path.lineTo(s * 0.8, (s - h) / 2);
//    path.lineTo(s * 0.5, s + h);
//// close the path to form a bounded shape
//    path.close();
//
//    c.drawPath(path, paint);

    if (count > 999) count = 999;
    final countString = "$count";
    final countOffset = _getPriceOffset(countString);
    _drawText(c, countString, diameter * countOffset.dx, diameter * countOffset.dy, fontSize: countFontSize);

//    final currencyOffset = markerSize.currencyOffset;
//    _drawText(c, "руб.", s * currencyOffset.dx, s * currencyOffset.dy, fontSize: markerSize.currencyFontSize);
    Picture p = recorder.endRecording();
    final image = await p.toImage(size.width.toInt(), size.height.toInt());
    return image.toByteData(format: ImageByteFormat.png);
  }

  static Offset _getPriceOffset(String priceString) {
    switch (priceString.length) {
      case 0:
      case 1:
        return const Offset(0.39, 0.27);

      case 2:
        return const Offset(0.27, 0.27);

      case 3:
        return const Offset(0.165, 0.27);

      default:
        throw Exception("The count $priceString is greater than 3 digits. Are you sure the price can be this great??");
    }
  }

  static void _drawText(Canvas canvas, String text, double x, double y,
      {double fontSize = 24, fontWeight: FontWeight.w700}) {
    TextSpan span = new TextSpan(
        style: new TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: fontWeight, fontFamily: 'Roboto'),
        text: text);
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(x, y));
  }
}
