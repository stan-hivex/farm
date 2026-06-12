import '/components/escrow_item/escrow_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'escrow_hub_widget.dart' show EscrowHubWidget;
import 'package:flutter/material.dart';

class EscrowHubModel extends FlutterFlowModel<EscrowHubWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for EscrowItem.
  late EscrowItemModel escrowItemModel1;
  // Model for EscrowItem.
  late EscrowItemModel escrowItemModel2;
  // Model for EscrowItem.
  late EscrowItemModel escrowItemModel3;
  // Model for EscrowItem.
  late EscrowItemModel escrowItemModel4;

  @override
  void initState(BuildContext context) {
    escrowItemModel1 = createModel(context, () => EscrowItemModel());
    escrowItemModel2 = createModel(context, () => EscrowItemModel());
    escrowItemModel3 = createModel(context, () => EscrowItemModel());
    escrowItemModel4 = createModel(context, () => EscrowItemModel());
  }

  @override
  void dispose() {
    escrowItemModel1.dispose();
    escrowItemModel2.dispose();
    escrowItemModel3.dispose();
    escrowItemModel4.dispose();
  }
}
