import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'pin_digit_box_model.dart';
export 'pin_digit_box_model.dart';

class PinDigitBoxWidget extends StatefulWidget {
  const PinDigitBoxWidget({
    super.key,
    bool? filled,
  }) : filled = filled ?? true;

  final bool filled;

  @override
  State<PinDigitBoxWidget> createState() => _PinDigitBoxWidgetState();
}

class _PinDigitBoxWidgetState extends State<PinDigitBoxWidget> {
  late PinDigitBoxModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PinDigitBoxModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 56.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: widget.filled
              ? FlutterFlowTheme.of(context).primaryText
              : FlutterFlowTheme.of(context).alternate,
          width: 1.5,
        ),
      ),
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Visibility(
        visible: valueOrDefault<bool>(
          widget.filled,
          true,
        ),
        child: Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryText,
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
          ),
        ),
      ),
    );
  }
}
