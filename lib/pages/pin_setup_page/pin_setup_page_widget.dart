
import '/pages/dashboard/dashboard_widget.dart';
import '/components/pin_digit_box_widget.dart';
import '/components/security_note_widget.dart';


import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';


import 'pin_setup_page_model.dart';
export 'pin_setup_page_model.dart';

class PinSetupPageWidget extends StatefulWidget {
  const PinSetupPageWidget({super.key});

  static String routeName = 'pin_setup_page';
  static String routePath = '/pinSetupPage';

  @override
  State<PinSetupPageWidget> createState() =>
      _PinSetupPageWidgetState();
}

class _PinSetupPageWidgetState
    extends State<PinSetupPageWidget> {
  late PinSetupPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _pin = '';
  String _confirmPin = '';

  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();

    _model = createModel(
      context,
      () => PinSetupPageModel(),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void onKeyPressed(String value) {
    setState(() {
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += value;
        }

        if (_pin.length == 4) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += value;
        }
      }
    });
  }

  void onDelete() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(
          0,
          _confirmPin.length - 1,
        );
      } else if (!_isConfirming &&
          _pin.isNotEmpty) {
        _pin = _pin.substring(
          0,
          _pin.length - 1,
        );
      }
    });
  }

  Future<void> validatePins() async {
    if (_pin.length < 4 ||
        _confirmPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter complete PIN',
          ),
        ),
      );
      return;
    }

    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PINs do not match',
          ),
        ),
      );

      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });

      return;
    }

    await savePin();
  }

  Future<void> savePin() async {
    try {
      print(
        "TOKEN: ${FFAppState().accessToken}",
      );

      final response = await http.post(
        Uri.parse(
          '${AppConfig.api}/auth/set-pin',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode({
  "pin": _pin.trim(),
  "confirm_pin": _confirmPin.trim(),
}),
      );

      print(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'PIN set successfully',
            ),
          ),
        );

        context.goNamed(
          DashboardWidget.routeName,
        );
      } else {
  final data = jsonDecode(response.body);

  String message =
      data['message'] ?? 'Failed to set PIN';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  Widget keypadButton(String number) {
    return GestureDetector(
      onTap: () => onKeyPressed(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius:
              BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget deleteButton() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildKeypad() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            9,
            (index) => keypadButton(
              '${index + 1}',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SizedBox(width: 82),

            keypadButton('0'),

            const SizedBox(width: 12),

            deleteButton(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Create Transaction PIN',
                  textAlign: TextAlign.center,
                  style:
                      FlutterFlowTheme.of(
                              context)
                          .headlineMedium
                          .override(
                            font:
                                GoogleFonts
                                    .plusJakartaSans(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                            letterSpacing:
                                0,
                          ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Set a secure PIN to authorize transactions',
                  textAlign: TextAlign.center,
                  style:
                      FlutterFlowTheme.of(
                              context)
                          .bodyMedium,
                ),

                const SizedBox(height: 40),

                Text(
                  !_isConfirming
                      ? 'Enter PIN'
                      : 'Confirm PIN',
                  textAlign: TextAlign.center,
                  style:
                      FlutterFlowTheme.of(
                              context)
                          .titleMedium,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceEvenly,
                  children: List.generate(
                    4,
                    (index) {
                      final filled =
                          !_isConfirming
                              ? _pin.length >
                                  index
                              : _confirmPin
                                      .length >
                                  index;

                      return PinDigitBoxWidget(
                        filled: filled,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                wrapWithModel(
                  model:
                      _model.securityNoteModel,
                  updateCallback: () =>
                      safeSetState(() {}),
                  child:
                      const SecurityNoteWidget(
                    title:
                        'Enhanced Security',
                    body:
                        'Your PIN protects transfers and sensitive actions.',
                  ),
                ),

                const SizedBox(height: 40),

                buildKeypad(),

                const SizedBox(height: 30),

                FFButtonWidget(
                  onPressed: () async {
                    await validatePins();
                  },
                  text: 'Verify PIN',
                  options: FFButtonOptions(
                    height: 55,
                    color: Colors.black,
                    textStyle:
                        const TextStyle(
                      color: Color.fromARGB(255, 121, 248, 3),
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

