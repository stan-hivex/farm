import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'scan_overlay_corner_model.dart';
export 'scan_overlay_corner_model.dart';

class ScanOverlayCornerWidget extends StatefulWidget {
  const ScanOverlayCornerWidget({
    super.key,
    Color? border_side,
    double? radius,
  })  : border_side = border_side ?? const Color(0x00000000),
        radius = radius ?? 0.0;

  final Color border_side;
  final double radius;

  @override
  State<ScanOverlayCornerWidget> createState() =>
      _ScanOverlayCornerWidgetState();
}

class _ScanOverlayCornerWidgetState extends State<ScanOverlayCornerWidget> {
  late ScanOverlayCornerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScanOverlayCornerModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0.0),
        shape: BoxShape.rectangle,
      ),
    );
  }
}
