import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'secure_pin_dot_model.dart';
export 'secure_pin_dot_model.dart';

class SecurePinDotWidget extends StatefulWidget {
  const SecurePinDotWidget({
    super.key,
    bool? filled,
  }) : filled = filled ?? true;

  final bool filled;

  @override
  State<SecurePinDotWidget> createState() => _SecurePinDotWidgetState();
}

class _SecurePinDotWidgetState extends State<SecurePinDotWidget> {
  late SecurePinDotModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SecurePinDotModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16.0,
      height: 16.0,
      decoration: BoxDecoration(
        color: widget.filled
            ? FlutterFlowTheme.of(context).primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
      ),
    );
  }
}
