import '/components/action_circle/action_circle_widget.dart';
import '/components/scan_overlay_corner/scan_overlay_corner_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'q_r_scanner_widget.dart' show QRScannerWidget;
import 'package:flutter/material.dart';

class QRScannerModel extends FlutterFlowModel<QRScannerWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ScanOverlayCorner.
  late ScanOverlayCornerModel scanOverlayCornerModel1;
  // Model for ScanOverlayCorner.
  late ScanOverlayCornerModel scanOverlayCornerModel2;
  // Model for ScanOverlayCorner.
  late ScanOverlayCornerModel scanOverlayCornerModel3;
  // Model for ScanOverlayCorner.
  late ScanOverlayCornerModel scanOverlayCornerModel4;
  // Model for ActionCircle.
  late ActionCircleModel actionCircleModel1;
  // Model for ActionCircle.
  late ActionCircleModel actionCircleModel2;
  // Model for ActionCircle.
  late ActionCircleModel actionCircleModel3;

  @override
  void initState(BuildContext context) {
    scanOverlayCornerModel1 =
        createModel(context, () => ScanOverlayCornerModel());
    scanOverlayCornerModel2 =
        createModel(context, () => ScanOverlayCornerModel());
    scanOverlayCornerModel3 =
        createModel(context, () => ScanOverlayCornerModel());
    scanOverlayCornerModel4 =
        createModel(context, () => ScanOverlayCornerModel());
    actionCircleModel1 = createModel(context, () => ActionCircleModel());
    actionCircleModel2 = createModel(context, () => ActionCircleModel());
    actionCircleModel3 = createModel(context, () => ActionCircleModel());
  }

  @override
  void dispose() {
    scanOverlayCornerModel1.dispose();
    scanOverlayCornerModel2.dispose();
    scanOverlayCornerModel3.dispose();
    scanOverlayCornerModel4.dispose();
    actionCircleModel1.dispose();
    actionCircleModel2.dispose();
    actionCircleModel3.dispose();
  }
}
