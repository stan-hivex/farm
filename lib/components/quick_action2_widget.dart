import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_action2_model.dart';
export 'quick_action2_model.dart';

class QuickAction2Widget extends StatefulWidget {
  const QuickAction2Widget({
    super.key,
    Color? bg,
    this.icon,
    Color? iconColor,
    String? label,
  })  : bg = bg ?? const Color(0x00000000),
        iconColor = iconColor ?? const Color(0x00000000),
        label = label ?? 'Send';

  final Color bg;
  final Widget? icon;
  final Color iconColor;
  final String label;

  @override
  State<QuickAction2Widget> createState() => _QuickAction2WidgetState();
}

class _QuickAction2WidgetState extends State<QuickAction2Widget> {
  late QuickAction2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => QuickAction2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            color: valueOrDefault<Color>(
              widget.bg,
              FlutterFlowTheme.of(context).primaryText,
            ),
            borderRadius: BorderRadius.circular(20.0),
            shape: BoxShape.rectangle,
          ),
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: widget.icon!,
        ),
        Text(
          valueOrDefault<String>(
            widget.label,
            'Send',
          ),
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(const SizedBox(height: 4.0)),
    );
  }
}
