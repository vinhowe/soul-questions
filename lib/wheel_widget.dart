import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class WheelWidget extends StatelessWidget {
  final int spokes;
  final Orientation orientation;

  WheelWidget({this.spokes = 5, this.orientation = Orientation.portrait});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color backgroundColor = theme.scaffoldBackgroundColor;
    return CustomPaint(painter: WheelPainter(lineColor: Colors.transparent, backgroundColor: backgroundColor, width: 5.0, segments: spokes, orientation: orientation));
  }
}

class WheelPainter extends CustomPainter {
  Color lineColor;
  Color backgroundColor;
  double width;
  int segments;
  Orientation orientation;

  double tau = 2*pi;

  WheelPainter({this.lineColor, this.backgroundColor, this.width, this.segments, this.orientation});

  @override
  void paint(Canvas canvas, Size size) {
    int adjustedSegments = max(segments, 1);

    Paint circle = new Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = width+2;

    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2)*20;

    Gradient gradient = RadialGradient(colors: <Color>[Colors.white, Colors.yellowAccent.withAlpha(0)],);

    Paint line = new Paint()
      ..color = Colors.black
      ..shader = gradient.createShader(new Rect.fromCircle(center: center, radius: radius/20))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    double startAngle = segments < 3 ? orientation == Orientation.portrait ? segments == 1 ? tau*1.5 : pi*2 : pi : pi;

    canvas.drawCircle(center, radius, circle);

    for(int i = 0; i < adjustedSegments; i++) {
      canvas.drawArc(
          new Rect.fromCircle(center: center, radius: radius), -startAngle/2 + (i* tau / adjustedSegments),
          tau / adjustedSegments, true, line);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
