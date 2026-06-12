import '/components/pin_digit_box_widget.dart';
import '/components/security_note_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'pin_setup_page_widget.dart' show PinSetupPageWidget;
import 'package:flutter/material.dart';

class PinSetupPageModel extends FlutterFlowModel<PinSetupPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel1;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel2;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel3;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel4;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel5;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel6;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel7;
  // Model for PinDigitBox.
  late PinDigitBoxModel pinDigitBoxModel8;
  // Model for SecurityNote.
  late SecurityNoteModel securityNoteModel;

  @override
  void initState(BuildContext context) {
    pinDigitBoxModel1 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel2 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel3 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel4 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel5 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel6 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel7 = createModel(context, () => PinDigitBoxModel());
    pinDigitBoxModel8 = createModel(context, () => PinDigitBoxModel());
    securityNoteModel = createModel(context, () => SecurityNoteModel());
  }

  @override
  void dispose() {
    pinDigitBoxModel1.dispose();
    pinDigitBoxModel2.dispose();
    pinDigitBoxModel3.dispose();
    pinDigitBoxModel4.dispose();
    pinDigitBoxModel5.dispose();
    pinDigitBoxModel6.dispose();
    pinDigitBoxModel7.dispose();
    pinDigitBoxModel8.dispose();
    securityNoteModel.dispose();
  }
}
