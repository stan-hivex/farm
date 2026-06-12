import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_field_model.dart';
export 'text_field_model.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget({
    super.key,
    bool? label,
    bool? helper,
    String? hint,
    String? value,
    this.leading_icon,
    bool? leading_icon_present,
    this.trailing_icon,
    bool? trailing_icon_present,
    String? variant,
    bool? error,
  })  : label = label ?? false,
        helper = helper ?? false,
        hint = hint ?? 'Enter @username',
        value = value ?? '',
        leading_icon_present = leading_icon_present ?? true,
        trailing_icon_present = trailing_icon_present ?? false,
        variant = variant ?? 'outlined',
        error = error ?? false;

  final bool label;
  final bool helper;
  final String hint;
  final String value;
  final Widget? leading_icon;
  final bool leading_icon_present;
  final Widget? trailing_icon;
  final bool trailing_icon_present;
  final String variant;
  final bool error;

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late TextFieldModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TextFieldModel());

    _model.inputTextController ??= TextEditingController(text: widget.value);
    _model.inputFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label ? true : false)
            Text(
              widget.label.toString(),
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: widget.error
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    lineHeight: 1.3,
                  ),
            ),
          Container(
            height: 40.0,
            decoration: BoxDecoration(
              color: () {
                if (widget.variant == 'filled') {
                  return FlutterFlowTheme.of(context).secondaryBackground;
                } else if (widget.variant == 'ghost') {
                  return Colors.transparent;
                } else {
                  return Colors.transparent;
                }
              }(),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(valueOrDefault<double>(
                  () {
                    if (widget.variant == 'filled') {
                      return 8.0;
                    } else if (widget.variant == 'ghost') {
                      return 8.0;
                    } else {
                      return 8.0;
                    }
                  }(),
                  0.0,
                )),
                topRight: Radius.circular(valueOrDefault<double>(
                  () {
                    if (widget.variant == 'filled') {
                      return 8.0;
                    } else if (widget.variant == 'ghost') {
                      return 8.0;
                    } else {
                      return 8.0;
                    }
                  }(),
                  0.0,
                )),
                bottomLeft: Radius.circular(valueOrDefault<double>(
                  () {
                    if (widget.variant == 'filled') {
                      return 8.0;
                    } else if (widget.variant == 'ghost') {
                      return 8.0;
                    } else {
                      return 8.0;
                    }
                  }(),
                  0.0,
                )),
                bottomRight: Radius.circular(valueOrDefault<double>(
                  () {
                    if (widget.variant == 'filled') {
                      return 8.0;
                    } else if (widget.variant == 'ghost') {
                      return 8.0;
                    } else {
                      return 8.0;
                    }
                  }(),
                  0.0,
                )),
              ),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: () {
                  if (widget.error) {
                    return FlutterFlowTheme.of(context).error;
                  } else if (widget.variant == 'filled') {
                    return Colors.transparent;
                  } else if (widget.variant == 'ghost') {
                    return Colors.transparent;
                  } else {
                    return FlutterFlowTheme.of(context).alternate;
                  }
                }(),
                width: () {
                  if (widget.error) {
                    return 1.0;
                  } else if (widget.variant == 'filled') {
                    return 1.0;
                  } else if (widget.variant == 'ghost') {
                    return 0.0;
                  } else {
                    return 1.0;
                  }
                }(),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  valueOrDefault<double>(
                    () {
                      if (widget.variant == 'filled') {
                        return 8.0;
                      } else if (widget.variant == 'ghost') {
                        return 8.0;
                      } else {
                        return 8.0;
                      }
                    }(),
                    0.0,
                  ),
                  valueOrDefault<double>(
                    () {
                      if (widget.variant == 'filled') {
                        return 8.0;
                      } else if (widget.variant == 'ghost') {
                        return 8.0;
                      } else {
                        return 8.0;
                      }
                    }(),
                    0.0,
                  ),
                  valueOrDefault<double>(
                    () {
                      if (widget.variant == 'filled') {
                        return 8.0;
                      } else if (widget.variant == 'ghost') {
                        return 8.0;
                      } else {
                        return 8.0;
                      }
                    }(),
                    0.0,
                  ),
                  valueOrDefault<double>(
                    () {
                      if (widget.variant == 'filled') {
                        return 8.0;
                      } else if (widget.variant == 'ghost') {
                        return 8.0;
                      } else {
                        return 8.0;
                      }
                    }(),
                    0.0,
                  )),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (valueOrDefault<bool>(
                    widget.leading_icon_present,
                    true,
                  ))
                    widget.leading_icon!,
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _model.inputTextController,
                      focusNode: _model.inputFocusNode,
                      obscureText: false,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: valueOrDefault<String>(
                          widget.hint,
                          'Enter @username',
                        ),
                        hintStyle: FlutterFlowTheme.of(context)
                            .bodyMedium
                            .override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: () {
                                if (widget.variant == 'filled') {
                                  return FlutterFlowTheme.of(context).accent3;
                                } else if (widget.variant == 'ghost') {
                                  return FlutterFlowTheme.of(context).accent3;
                                } else {
                                  return FlutterFlowTheme.of(context).accent3;
                                }
                              }(),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.5,
                            ),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: () {
                              if (widget.variant == 'filled') {
                                return FlutterFlowTheme.of(context).primaryText;
                              } else if (widget.variant == 'ghost') {
                                return FlutterFlowTheme.of(context).primaryText;
                              } else {
                                return FlutterFlowTheme.of(context).primaryText;
                              }
                            }(),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.5,
                          ),
                      validator: _model.inputTextControllerValidator
                          .asValidator(context),
                    ),
                  ),
                  if (valueOrDefault<bool>(
                    widget.trailing_icon_present,
                    false,
                  ))
                    widget.trailing_icon!,
                ],
              ),
            ),
          ),
          if (widget.helper ? true : false)
            Text(
              widget.helper.toString(),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
                    color: widget.error
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodySmall.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
        ].divide(const SizedBox(height: 6.0)),
      ),
    );
  }
}
