import '/components/button/button_widget.dart';
import '/components/profile_info_tile/profile_info_tile_widget.dart';
import '/components/settings_action_tile/settings_action_tile_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'profile_settings_widget.dart' show ProfileSettingsWidget;
import 'package:flutter/material.dart';

class ProfileSettingsModel extends FlutterFlowModel<ProfileSettingsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ProfileInfoTile.
  late ProfileInfoTileModel profileInfoTileModel1;
  // Model for ProfileInfoTile.
  late ProfileInfoTileModel profileInfoTileModel2;
  // Model for ProfileInfoTile.
  late ProfileInfoTileModel profileInfoTileModel3;
  // Model for SettingsActionTile.
  late SettingsActionTileModel settingsActionTileModel1;
  // Model for SettingsActionTile.
  late SettingsActionTileModel settingsActionTileModel2;
  // Model for SettingsActionTile.
  late SettingsActionTileModel settingsActionTileModel3;
  // Model for SettingsActionTile.
  late SettingsActionTileModel settingsActionTileModel4;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    profileInfoTileModel1 = createModel(context, () => ProfileInfoTileModel());
    profileInfoTileModel2 = createModel(context, () => ProfileInfoTileModel());
    profileInfoTileModel3 = createModel(context, () => ProfileInfoTileModel());
    settingsActionTileModel1 =
        createModel(context, () => SettingsActionTileModel());
    settingsActionTileModel2 =
        createModel(context, () => SettingsActionTileModel());
    settingsActionTileModel3 =
        createModel(context, () => SettingsActionTileModel());
    settingsActionTileModel4 =
        createModel(context, () => SettingsActionTileModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    profileInfoTileModel1.dispose();
    profileInfoTileModel2.dispose();
    profileInfoTileModel3.dispose();
    settingsActionTileModel1.dispose();
    settingsActionTileModel2.dispose();
    settingsActionTileModel3.dispose();
    settingsActionTileModel4.dispose();
    buttonModel.dispose();
  }
}
