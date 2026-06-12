import '/components/category_chip/category_chip_widget.dart';
import '/components/project_card/project_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'investment_marketplace_widget.dart' show InvestmentMarketplaceWidget;
import 'package:flutter/material.dart';

class InvestmentMarketplaceModel
    extends FlutterFlowModel<InvestmentMarketplaceWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel1;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel2;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel3;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel4;
  // Model for ProjectCard.
  late ProjectCardModel projectCardModel1;
  // Model for ProjectCard.
  late ProjectCardModel projectCardModel2;
  // Model for ProjectCard.
  late ProjectCardModel projectCardModel3;
  // Model for ProjectCard.
  late ProjectCardModel projectCardModel4;

  @override
  void initState(BuildContext context) {
    categoryChipModel1 = createModel(context, () => CategoryChipModel());
    categoryChipModel2 = createModel(context, () => CategoryChipModel());
    categoryChipModel3 = createModel(context, () => CategoryChipModel());
    categoryChipModel4 = createModel(context, () => CategoryChipModel());
    projectCardModel1 = createModel(context, () => ProjectCardModel());
    projectCardModel2 = createModel(context, () => ProjectCardModel());
    projectCardModel3 = createModel(context, () => ProjectCardModel());
    projectCardModel4 = createModel(context, () => ProjectCardModel());
  }

  @override
  void dispose() {
    categoryChipModel1.dispose();
    categoryChipModel2.dispose();
    categoryChipModel3.dispose();
    categoryChipModel4.dispose();
    projectCardModel1.dispose();
    projectCardModel2.dispose();
    projectCardModel3.dispose();
    projectCardModel4.dispose();
  }
}
