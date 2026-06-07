import 'package:flutter/material.dart';

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 250,
    this.cutOutHeight = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return getLeftTopPath(rect)..lineTo(rect.right, rect.bottom)..lineTo(rect.left, rect.bottom)..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final actualBorderLengthX = borderLength > cutOutWidth / 2 + borderOffset ? cutOutWidth / 2 + borderOffset : borderLength;
    final actualBorderLengthY = borderLength > cutOutHeight / 2 + borderOffset ? cutOutHeight / 2 + borderOffset : borderLength;
    final actualCutOutWidth = cutOutWidth < width ? cutOutWidth : width;
    final actualCutOutHeight = cutOutHeight < height ? cutOutHeight : height;

    final backgroundPaint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth;
    final boxPaint = Paint()..color = borderColor..style = PaintingStyle.fill..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - actualCutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - actualCutOutHeight / 2 + borderOffset - cutOutBottomOffset,
      actualCutOutWidth - borderOffset * 2,
      actualCutOutHeight - borderOffset * 2,
    );

    canvas..saveLayer(rect, backgroundPaint)..drawRect(rect, backgroundPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.right - actualBorderLengthX, cutOutRect.top, cutOutRect.right, cutOutRect.top + actualBorderLengthY, topRight: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.left, cutOutRect.top, cutOutRect.left + actualBorderLengthX, cutOutRect.top + actualBorderLengthY, topLeft: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.right - actualBorderLengthX, cutOutRect.bottom - actualBorderLengthY, cutOutRect.right, cutOutRect.bottom, bottomRight: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromLTRBAndCorners(cutOutRect.left, cutOutRect.bottom - actualBorderLengthY, cutOutRect.left + actualBorderLengthX, cutOutRect.bottom, bottomLeft: Radius.circular(borderRadius)), borderPaint)
      ..drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), boxPaint)..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(borderColor: borderColor, borderWidth: borderWidth, overlayColor: overlayColor);
  }
}

class ScannerVisorPainter extends CustomPainter {
  final Color color;
  final double laserPosition;

  ScannerVisorPainter({required this.color, required this.laserPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerSize = 40.0;
    final path = Path();

    // Top Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);

    // Top Right
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);

    // Bottom Right
    path.moveTo(size.width, size.height - cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerSize, size.height);

    // Bottom Left
    path.moveTo(cornerSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerSize);

    canvas.drawPath(path, paint);

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // Laser Line
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, size.height * laserPosition - 0.5, size.width, 1))
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(0, size.height * laserPosition),
      Offset(size.width, size.height * laserPosition),
      laserPaint,
    );

    // Laser Glow
    final laserGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * laserPosition - 5, size.width, 10),
      laserGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerVisorPainter oldDelegate) => 
      oldDelegate.laserPosition != laserPosition || oldDelegate.color != color;
}
