import 'package:flutter/material.dart';
import 'dart:convert';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/core/theme_extensions.dart';

import '/app_state.dart';

class ChangePinPageWidget extends StatefulWidget {
  const ChangePinPageWidget({super.key});

  static String routeName = 'change_pin_page';
  static String routePath = '/changePinPage';

  @override
  State<ChangePinPageWidget> createState() =>
      _ChangePinPageWidgetState();
}

class _ChangePinPageWidgetState
    extends State<ChangePinPageWidget> {
  String oldPin = '';
  String newPin = '';
  String confirmPin = '';

  bool step2 = false;
  bool step3 = false;

  bool isLoading = false;

  // ================= ADD DIGITS =================
  void add(String v) {
    setState(() {
      if (!step2 && oldPin.length < 4) {
        oldPin += v;

        if (oldPin.length == 4) {
          step2 = true;
        }
      } else if (!step3 &&
          newPin.length < 4) {
        newPin += v;

        if (newPin.length == 4) {
          step3 = true;
        }
      } else if (confirmPin.length < 4) {
        confirmPin += v;
      }
    });
  }

  // ================= DELETE =================
  void delete() {
    setState(() {
      if (confirmPin.isNotEmpty) {
        confirmPin = confirmPin.substring(
          0,
          confirmPin.length - 1,
        );
      } else if (newPin.isNotEmpty) {
        newPin = newPin.substring(
          0,
          newPin.length - 1,
        );
      } else if (oldPin.isNotEmpty) {
        oldPin = oldPin.substring(
          0,
          oldPin.length - 1,
        );
      }
    });
  }

  // ================= RESET =================
  void resetPins() {
    setState(() {
      oldPin = '';
      newPin = '';
      confirmPin = '';

      step2 = false;
      step3 = false;
    });
  }

  // ================= SUBMIT =================
  Future<void> submit() async {
    if (oldPin.length < 4 ||
        newPin.length < 4 ||
        confirmPin.length < 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Complete all PIN fields",
          ),
        ),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "New PINs do not match",
          ),
        ),
      );

      setState(() {
        newPin = '';
        confirmPin = '';
        step3 = false;
      });

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.api}/auth/change-pin',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode({
          "old_pin": oldPin,
          "new_pin": newPin,
          "confirm_pin": confirmPin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'PIN changed successfully',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Failed to change PIN',
            ),
          ),
        );

        // Reset only old pin if incorrect
        if ((data['message'] ?? '')
            .toString()
            .toLowerCase()
            .contains('old pin')) {
          setState(() {
            oldPin = '';
            step2 = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // ================= DOTS =================
  Widget dots(String value) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.all(8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < value.length
                ? context.background
                : context.borderColor,
          ),
        ),
      ),
    );
  }

  // ================= KEY =================
  Widget key(String value) {
    return GestureDetector(
      onTap: () => add(value),
      child: Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.background,
          borderRadius:
              BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            color: context.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= KEYPAD =================
  Widget keypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9']
        ])
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: row
                .map((e) => key(e))
                .toList(),
          ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SizedBox(width: 90),

            key('0'),

            Container(
              width: 75,
              height: 75,
              margin: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: delete,
                icon: Icon(
                  Icons.backspace_outlined,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: context.background,
        foregroundColor: context.onSurface,
        title: Text(
          "Change PIN",
          style: TextStyle(color: context.onSurface),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: Icon(
                  Icons.lock_reset,
                  color: context.onSurface,
                  size: 45,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                !step2
                    ? "Enter Old PIN"
                    : !step3
                        ? "Enter New PIN"
                        : "Confirm New PIN",
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                !step2
                    ? "Input your current transaction PIN"
                    : !step3
                        ? "Create a new secure PIN"
                        : "Confirm your new PIN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 40),

              if (!step2) dots(oldPin),

              if (step2 && !step3)
                dots(newPin),

              if (step3) dots(confirmPin),

              const SizedBox(height: 40),

              keypad(),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : submit,
                  style:
                      ElevatedButton.styleFrom(
                      backgroundColor:
                          FlutterFlowTheme.of(context).primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: context.onSurface,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save PIN",
                          style: TextStyle(
                              color: FlutterFlowTheme.of(context).onPrimary,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
