import '/components/button/button_widget.dart';
import '/components/detail_chip/detail_chip_widget.dart';
import '/components/project_stat/project_stat_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'project_details_widget.dart' show ProjectDetailsWidget;
import 'package:flutter/material.dart';

class ProjectDetailsModel extends FlutterFlowModel<ProjectDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for DetailChip.
  late DetailChipModel detailChipModel1;
  // Model for DetailChip.
  late DetailChipModel detailChipModel2;
  // Model for ProjectStat.
  late ProjectStatModel projectStatModel1;
  // Model for ProjectStat.
  late ProjectStatModel projectStatModel2;
  // Model for ProjectStat.
  late ProjectStatModel projectStatModel3;
  // Model for ProjectStat.
  late ProjectStatModel projectStatModel4;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    detailChipModel1 = createModel(context, () => DetailChipModel());
    detailChipModel2 = createModel(context, () => DetailChipModel());
    projectStatModel1 = createModel(context, () => ProjectStatModel());
    projectStatModel2 = createModel(context, () => ProjectStatModel());
    projectStatModel3 = createModel(context, () => ProjectStatModel());
    projectStatModel4 = createModel(context, () => ProjectStatModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    detailChipModel1.dispose();
    detailChipModel2.dispose();
    projectStatModel1.dispose();
    projectStatModel2.dispose();
    projectStatModel3.dispose();
    projectStatModel4.dispose();
    buttonModel.dispose();
  }
}
