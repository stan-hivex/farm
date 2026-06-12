import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'project_card_widget.dart' show ProjectCardWidget;
import 'package:flutter/material.dart';

class ProjectCardModel extends FlutterFlowModel<ProjectCardWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
