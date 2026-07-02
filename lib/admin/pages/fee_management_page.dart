import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class FeeManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const FeeManagementPage({super.key, this.onGoBack});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final _bgColor = const Color(0xFF0B1320);
  final _cardColor = const Color(0xFF111B2A);
  final _accent = const Color(0xFFD4AF37);

  List<dynamic> _fees = [];
  bool _loading = true;
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApiService.getFees();
      final list = res['data'] as List? ?? [];
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      setState(() {
        _fees = list;
        for (final fee in list) {
          final id = _feeId(fee);
          _controllers[id] = TextEditingController(text: _feeValue(fee));
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _feeId(dynamic fee) {
    return fee['id']?.toString() ?? fee['fee_code']?.toString() ?? fee['name']?.toString() ?? '';
  }

  String _feeLabel(dynamic fee) {
    return fee['name']?.toString() ?? fee['fee_code']?.toString() ?? 'Fee setting';
  }

  String _feeDescription(dynamic fee) {
    return fee['description']?.toString() ?? fee['note']?.toString() ?? 'Update the fee value for this configuration.';
  }

  String _feeValue(dynamic fee) {
    return fee['value']?.toString() ?? '';
  }

  Future<void> _saveFee(String feeId) async {
    final controller = _controllers[feeId];
    if (controller == null) return;
    final value = controller.text.trim();
    if (value.isEmpty) {
      _snack('Enter a value before saving', context.warningColor);
      return;
    }

    setState(() => _saving[feeId] = true);
    try {
      await AdminApiService.updateFee(feeId, value);
      final index = _fees.indexWhere((fee) => _feeId(fee) == feeId);
      if (index != -1) {
        setState(() => _fees[index]['value'] = value);
      }
      _snack('Fee updated ✓', context.successColor);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), context.errorColor);
    } finally {
      if (mounted) setState(() => _saving[feeId] = false);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
      );

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _accent,
          backgroundColor: _bgColor,
          child: _loading
              ? ListView(children: const [SizedBox(height: 120), Center(child: CircularProgressIndicator())])
              : ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Fee Management',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, fontWeight: FontWeight.bold, color: context.onSurface)),
                  const SizedBox(height: 6),
                  Text('Review and update platform fee configurations.',
                      style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.errorColor.withAlpha((0.14 * 255).round()),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.errorColor.withAlpha((0.2 * 255).round())),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: context.errorColorAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.7))),
                        ),
                        TextButton(onPressed: _load, child: Text('Retry', style: TextStyle(color: _accent))),
                      ]),
                    ),

                  if (_fees.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.onSurface.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        Icon(Icons.percent_rounded, size: 32, color: context.onSurface.withOpacity(0.24)),
                        const SizedBox(height: 14),
                        Text('No fee configurations available',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.54), fontSize: 14)),
                      ]),
                    )
                  else
                    ..._fees.map((fee) {
                      final id = _feeId(fee);
                      final controller = _controllers[id]!;
                      final saving = _saving[id] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.onSurface.withOpacity(0.1)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_feeLabel(fee),
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: context.onSurface)),
                          const SizedBox(height: 8),
                          Text(_feeDescription(fee),
                              style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.6), fontSize: 12)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.plusJakartaSans(color: context.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Fee value',
                                  hintStyle: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.38)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1724),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.onSurface.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.onSurface.withOpacity(0.1)),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: saving ? null : () => _saveFee(id),
                                child: saving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: context.onBackground.withOpacity(0.87), strokeWidth: 2),
                                      )
                                    : Text('Save',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold, color: context.onBackground.withOpacity(0.87))),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    }),
                ]),
        ),
      ),
    );
  }
}
