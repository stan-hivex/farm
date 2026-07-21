import 'package:http/http.dart' as http;
import '/core/app_config.dart';

import '/components/action_circle/action_circle_widget.dart';
import '/components/scan_overlay_corner/scan_overlay_corner_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import '/backend/api_requests/wallet_api_service.dart';
import '/backend/api_requests/user_api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'q_r_scanner_model.dart';
export 'q_r_scanner_model.dart';

class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({super.key});

  static String routeName = 'QRScanner';
  static String routePath = '/qRScanner';

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late QRScannerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final MobileScannerController cameraController =
      MobileScannerController();

  bool isProcessing = false;
  bool isSubmittingTransfer = false;
  
  double walletBalance = 0.0;
  bool balanceLoading = true;

  @override
  void initState() {
    super.initState();

    _model = createModel(context, () => QRScannerModel());
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      setState(() => balanceLoading = true);
      
      final wallet = await WalletApiService.getWallet(
        token: FFAppState().accessToken,
      );
      
      setState(() {
        walletBalance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        balanceLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch wallet balance: $e');
      setState(() {
        walletBalance = 0.0;
        balanceLoading = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _showPaymentSheet({
    required String recipientIdentifier,
    String? recipientLabel,
    String? suggestedAmount,
  }) async {
    final amountController = TextEditingController(
      text: suggestedAmount ?? '',
    );
    final pinController = TextEditingController();
    final descriptionController = TextEditingController(text: 'QR payment');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send payment',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipientLabel != null && recipientLabel.isNotEmpty
                        ? 'Send funds to $recipientLabel'
                        : 'Send funds to $recipientIdentifier',
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'FARM ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmittingTransfer
                          ? null
                          : () async {
                              final amount = double.tryParse(
                                      amountController.text.trim()) ??
                                  0;
                              final pin = pinController.text.trim();

                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid amount'),
                                  ),
                                );
                                return;
                              }

                              if (pin.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter your PIN'),
                                  ),
                                );
                                return;
                              }

                              try {
                                if (!mounted) return;
                                setState(() => isSubmittingTransfer = true);

                                await WalletApiService.sendFunds(
                                  token: FFAppState().accessToken,
                                  recipient: recipientIdentifier,
                                  amount: amount,
                                  pin: pin,
                                  description: descriptionController.text.trim().isNotEmpty
                                      ? descriptionController.text.trim()
                                      : 'QR payment',
                                );

                                if (!mounted) return;
                                await _fetchWalletBalance();
                                Navigator.of(sheetContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transfer successful'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Transfer failed: ${e.toString().replaceFirst('Exception: ', '')}',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => isSubmittingTransfer = false);
                                }
                              }
                            },
                      child: isSubmittingTransfer
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> validateQr(String qrPayload) async {
    if (isProcessing) return;

    isProcessing = true;

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.api}/qr/validate',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode({
          'qr_payload': qrPayload,
        }),
      );

      debugPrint(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final qrData = data['data'];

        if (qrData['type'] == 'peer') {
          final recipientIdentifier = qrData['wallet_address']?.toString() ??
              qrData['recipient_identifier']?.toString() ??
              qrData['username']?.toString() ??
              qrData['phone']?.toString() ??
              '';

          if (recipientIdentifier.isNotEmpty) {
            if (mounted) {
              await _showPaymentSheet(
                recipientIdentifier: recipientIdentifier,
                recipientLabel: qrData['display_name']?.toString() ??
                    qrData['username']?.toString() ??
                    qrData['phone']?.toString(),
                suggestedAmount: qrData['suggested_amount']?.toString(),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to determine recipient from QR code'),
                ),
              );
            }
          }
        } else if (qrData['type'] == 'merchant') {
          context.pushNamed(
            'MerchantPayment',
            queryParameters: {
              'merchantId':
                  qrData['merchant_id'].toString(),
              'businessName':
                  qrData['business_name'].toString(),
              'qrPayload': qrPayload,
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR Code'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR Validation Error: $e',
          ),
        ),
      );
    }

    isProcessing = false;
  }
  Future<void> scanFromGallery() async {
  final picker = ImagePicker();

  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  final file = File(image.path);

  final barcodeCapture = await cameraController.analyzeImage(file.path);

  if (barcodeCapture == null || barcodeCapture.barcodes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No QR found in image")),
    );
    return;
  }

  final code = barcodeCapture.barcodes.first.rawValue;

  if (code != null) {
    await validateQr(code);
  }
}

void scanByUsername() {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("Scan by Username / Phone"),
        content: StatefulBuilder(
          builder: (context, setState) {
            List<dynamic> suggestionUsers = [];

            Future<void> searchUsers(String value) async {
              if (!UserApiService.shouldSearchSuggestions(value)) {
                setState(() => suggestionUsers = []);
                return;
              }

              try {
                final users = await UserApiService.searchUsers(
                  token: FFAppState().accessToken,
                  query: value.trim(),
                );
                if (!mounted) return;
                setState(() => suggestionUsers = users);
              } catch (_) {
                if (!mounted) return;
                setState(() => suggestionUsers = []);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: 'Recipient username or phone number',
                        helperText: 'You can scan by username or phone number',
                        helperStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) async {
                        controller.text = value;
                        await searchUsers(value);
                      },
                      onSubmitted: (_) async {
                        final input = controller.text.trim();
                        if (input.isEmpty) return;
                        Navigator.pop(context);
                        await validateQr(input);
                      },
                    ),
                    if (suggestionUsers.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: suggestionUsers.map((u) {
                            final user = u as Map<String, dynamic>;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                child: Text(
                                  (user['username'] ?? 'u').toString().trim().isNotEmpty
                                      ? (user['username'] ?? 'u').toString().trim()[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(UserApiService.getSuggestionLabel(user)),
                              onTap: () {
                                controller.text = UserApiService.getSuggestionValue(user);
                                setState(() => suggestionUsers = []);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a username or phone number to scan'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await validateQr(input);
            },
            child: Text("Scan"),
          ),
        ],
      );
    },
  );
}

void showMyQrCode() {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("My QR Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${FFAppState().userName}",
            ),
            const SizedBox(height: 12),
            Text("@${FFAppState().userName}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      );
    },
  );
} 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor:
            FlutterFlowTheme.of(context).primary,
        body: Stack(
          children: [
            CachedNetworkImage(
              fadeInDuration:
                  const Duration(milliseconds: 0),
              fadeOutDuration:
                  const Duration(milliseconds: 0),
              imageUrl:
                  'https://dimg.dreamflow.cloud/v1/image/blurry%20dark%20modern%20interior%20background',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            /// DARK OVERLAY
            Container(
              color: context.background.withAlpha((0.45 * 255).round()),
            ),

            SafeArea(
              child: Column(
                children: [
                  /// TOP BAR
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        FlutterFlowIconButton(
                          borderRadius: 9999,
                          buttonSize: 44,
                          fillColor:
                              FlutterFlowTheme.of(context)
                                  .onPrimary13,
                          icon: Icon(
                            Icons.close_rounded,
                            color:
                                FlutterFlowTheme.of(context)
                                    .onPrimary,
                            size: 24,
                          ),
                          onPressed: () {
                            context.goNamed('Dashboard');
                          },
                        ),

                        Text(
                          'Scan QR Code',
                          style:
                              FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font:
                                        GoogleFonts
                                            .plusJakartaSans(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .onPrimary,
                                  ),
                        ),

                        FlutterFlowIconButton(
                          borderRadius: 9999,
                          buttonSize: 44,
                          fillColor:
                              FlutterFlowTheme.of(context)
                                  .onPrimary13,
                          icon: Icon(
                            Icons.flash_on_rounded,
                            color:
                                FlutterFlowTheme.of(context)
                                    .onPrimary,
                            size: 24,
                          ),
                          onPressed: () async {
                            await cameraController
                                .toggleTorch();
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  /// SCANNER SECTION
                  Column(
                    children: [
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            /// CAMERA
                            ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: MobileScanner(
      fit: BoxFit.cover,
      controller: cameraController,
      scanWindow: Rect.fromCenter(
  center: const Offset(140, 140),
  width: 250,
  height: 250,
),
                                onDetect: (capture) async {
                                  final List<Barcode>
                                      barcodes =
                                      capture.barcodes;

                                  for (final barcode
                                      in barcodes) {
                                    final String? code =
                                        barcode.rawValue;

                                    if (code != null) {
                                      await validateQr(
                                          code);
                                      break;
                                    }
                                  }
                                },
                              ),
                            ),

                            /// OVERLAY CORNERS
                            Positioned(
                              top: 0,
                              left: 0,
                              child: wrapWithModel(
                                model: _model
                                    .scanOverlayCornerModel1,
                                updateCallback: () =>
                                    safeSetState(() {}),
                                child:
                                    const ScanOverlayCornerWidget(
                                  border_side:
                                      Color(0x00000000),
                                  radius: 0,
                                ),
                              ),
                            ),

                            Positioned(
                              top: 0,
                              right: 0,
                              child: wrapWithModel(
                                model: _model
                                    .scanOverlayCornerModel2,
                                updateCallback: () =>
                                    safeSetState(() {}),
                                child:
                                    const ScanOverlayCornerWidget(
                                  border_side:
                                      Color(0x00000000),
                                  radius: 0,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: wrapWithModel(
                                model: _model
                                    .scanOverlayCornerModel3,
                                updateCallback: () =>
                                    safeSetState(() {}),
                                child:
                                    const ScanOverlayCornerWidget(
                                  border_side:
                                      Color(0x00000000),
                                  radius: 0,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: wrapWithModel(
                                model: _model
                                    .scanOverlayCornerModel4,
                                updateCallback: () =>
                                    safeSetState(() {}),
                                child:
                                    const ScanOverlayCornerWidget(
                                  border_side:
                                      Color(0x00000000),
                                  radius: 0,
                                ),
                              ),
                            ),

                            /// SCANNING LINE
                            IgnorePointer(
                              child: Lottie.network(
                                'https://dimg.dreamflow.cloud/v1/lottie/horizontal+scanning+line',
                                width: 240,
                                height: 240,
                                fit: BoxFit.contain,
                                animate: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Opacity(
                        opacity: 0.9,
                        child: Text(
                          'Align QR code within the frame',
                          style:
                              FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font:
                                        GoogleFonts.inter(),
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .onPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  /// ACTION BUTTONS
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model:
                              _model.actionCircleModel1,
                          updateCallback: () =>
                              safeSetState(() {}),
                          child: GestureDetector(
                            onTap: scanFromGallery,
                            child: ActionCircleWidget(
                              icon: Icon(
                                Icons.image_rounded,
                                color:
                                    FlutterFlowTheme.of(
                                            context)
                                        .onPrimary,
                                size: 24,
                              ),
                              label: 'Gallery',
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        wrapWithModel(
                          model:
                              _model.actionCircleModel2,
                          updateCallback: () =>
                              safeSetState(() {}),
                          child: GestureDetector(
                            onTap: scanByUsername,
                            child: ActionCircleWidget(
                              icon: Icon(
                                Icons.person_search_rounded,
                                color:
                                    FlutterFlowTheme.of(
                                            context)
                                        .onPrimary,
                                size: 24,
                              ),
                              label: 'Username / Phone',
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        wrapWithModel(
                          model:
                              _model.actionCircleModel3,
                          updateCallback: () =>
                              safeSetState(() {}),
                          child: GestureDetector(
                            onTap: showMyQrCode,
                            child: ActionCircleWidget(
                              icon: Icon(
                                Icons.qr_code_2_rounded,
                                color:
                                    FlutterFlowTheme.of(
                                            context)
                                        .onPrimary,
                                size: 24,
                              ),
                              label: 'My Code',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// USER CARD
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 32,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            FlutterFlowTheme.of(context)
                                .onPrimary,
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    FlutterFlowTheme.of(
                                            context)
                                        .primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                FFAppState()
                                        .userName
                                        .isNotEmpty
                                    ? FFAppState()
                                        .userName
                                        .substring(0, 2)
                                        .toUpperCase()
                                    : 'US',
                                style:
                                    FlutterFlowTheme.of(
                                            context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts
                                              .plusJakartaSans(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .onPrimary,
                                        ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Sending from @${FFAppState().userName}',
                                  style:
                                      FlutterFlowTheme.of(
                                              context)
                                          .labelSmall,
                                ),

                                Text(
                                  balanceLoading
                                      ? 'Balance: Loading...'
                                      : 'Balance: ${walletBalance.toStringAsFixed(2)} FARM',
                                  style:
                                      FlutterFlowTheme.of(
                                              context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts
                                                .plusJakartaSans(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
