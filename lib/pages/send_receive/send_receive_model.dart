import '/components/action_tab/action_tab_widget.dart';
import '/components/button/button_widget.dart';
import '/components/contact_item/contact_item_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'send_receive_widget.dart' show SendReceiveWidget;
import 'package:flutter/material.dart';

class SendReceiveModel extends FlutterFlowModel<SendReceiveWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ActionTab.
  late ActionTabModel actionTabModel1;
  // Model for ActionTab.
  late ActionTabModel actionTabModel2;
  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for ContactItem.
  late ContactItemModel contactItemModel1;
  // Model for ContactItem.
  late ContactItemModel contactItemModel2;
  // Model for ContactItem.
  late ContactItemModel contactItemModel3;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    actionTabModel1 = createModel(context, () => ActionTabModel());
    actionTabModel2 = createModel(context, () => ActionTabModel());
    textFieldModel = createModel(context, () => TextFieldModel());
    contactItemModel1 = createModel(context, () => ContactItemModel());
    contactItemModel2 = createModel(context, () => ContactItemModel());
    contactItemModel3 = createModel(context, () => ContactItemModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    actionTabModel1.dispose();
    actionTabModel2.dispose();
    textFieldModel.dispose();
    contactItemModel1.dispose();
    contactItemModel2.dispose();
    contactItemModel3.dispose();
    buttonModel.dispose();
  }
}
