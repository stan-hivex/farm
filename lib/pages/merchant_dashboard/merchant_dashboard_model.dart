import '/components/button/button_widget.dart';
import '/components/merchant_stat_card/merchant_stat_card_widget.dart';
import '/components/merchant_transaction_item/merchant_transaction_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'merchant_dashboard_widget.dart' show MerchantDashboardWidget;
import 'package:flutter/material.dart';

class MerchantDashboardModel extends FlutterFlowModel<MerchantDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MerchantStatCard.
  late MerchantStatCardModel merchantStatCardModel1;
  // Model for MerchantStatCard.
  late MerchantStatCardModel merchantStatCardModel2;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for MerchantTransactionItem.
  late MerchantTransactionItemModel merchantTransactionItemModel1;
  // Model for MerchantTransactionItem.
  late MerchantTransactionItemModel merchantTransactionItemModel2;
  // Model for MerchantTransactionItem.
  late MerchantTransactionItemModel merchantTransactionItemModel3;
  // Model for MerchantTransactionItem.
  late MerchantTransactionItemModel merchantTransactionItemModel4;

  @override
  void initState(BuildContext context) {
    merchantStatCardModel1 =
        createModel(context, () => MerchantStatCardModel());
    merchantStatCardModel2 =
        createModel(context, () => MerchantStatCardModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    merchantTransactionItemModel1 =
        createModel(context, () => MerchantTransactionItemModel());
    merchantTransactionItemModel2 =
        createModel(context, () => MerchantTransactionItemModel());
    merchantTransactionItemModel3 =
        createModel(context, () => MerchantTransactionItemModel());
    merchantTransactionItemModel4 =
        createModel(context, () => MerchantTransactionItemModel());
  }

  @override
  void dispose() {
    merchantStatCardModel1.dispose();
    merchantStatCardModel2.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    merchantTransactionItemModel1.dispose();
    merchantTransactionItemModel2.dispose();
    merchantTransactionItemModel3.dispose();
    merchantTransactionItemModel4.dispose();
  }
}
