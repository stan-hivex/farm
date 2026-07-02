import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class SettingsManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const SettingsManagementPage({super.key, this.onGoBack});

  @override
  State<SettingsManagementPage> createState() => _SettingsManagementPageState();
}

class _SettingsManagementPageState extends State<SettingsManagementPage> {
  final _bgColor = const Color(0xFF0B1320);
  final _cardColor = const Color(0xFF111B2A);
  final _accent = const Color(0xFFD4AF37);

  List<dynamic> _settings = [];
  bool _loading = true;
  String? _error;
  final Map<String, TextEditingController> _ctrls = {};

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
      final res = await AdminApiService.getSettings();
      final list = res['data'] as List? ?? [];
      for (final c in _ctrls.values) {
        c.dispose();
      }
      _ctrls.clear();
      setState(() {
        _settings = list;
        for (final s in list) {
          final k = s['setting_key'] as String;
          _ctrls[k] = TextEditingController(text: s['setting_value'] ?? '');
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String key) async {
    try {
      await AdminApiService.updateSetting(key, _ctrls[key]?.text ?? '');
      _snack('Setting updated ✓', context.successColor);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), context.errorColor);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating),
      );

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
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
              ? ListView(
                  children: const [SizedBox(height: 120), Center(child: CircularProgressIndicator())],
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Platform Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: context.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Configure platform-wide behaviour for FARM',
                      style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.7), fontSize: 13),
                    ),
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

                    if (_settings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.onSurface.withOpacity(0.1)),
                        ),
                        child: Column(children: [
                          Icon(Icons.settings_suggest_rounded, size: 32, color: context.onSurface.withOpacity(0.24)),
                          const SizedBox(height: 14),
                          Text(
                            'No platform settings available',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.54), fontSize: 14),
                          ),
                        ]),
                      )
                    else
                      ..._settings.map((s) {
                        final key = s['setting_key'] as String;
                        final desc = s['description'] as String? ?? '';
                        final value = s['setting_value']?.toString() ?? '';
                        final isBool = value == 'true' || value == 'false';
                        final controller = _ctrls[key]!;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.onSurface.withOpacity(0.1)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              key.replaceAll('_', ' ').toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: context.onSurface,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                desc,
                                style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (isBool)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    controller.text == 'true' ? 'Enabled' : 'Disabled',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: context.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Switch(
                                    value: controller.text == 'true',
                                    activeThumbColor: _accent,
                                    activeTrackColor: _accent.withAlpha((0.35 * 255).round()),
                                    inactiveThumbColor: context.onSurface,
                                    inactiveTrackColor: context.onSurface.withOpacity(0.12),
                                    onChanged: (v) {
                                      setState(() => controller.text = v ? 'true' : 'false');
                                      _save(key);
                                    },
                                  ),
                                ],
                              )
                            else
                              Column(children: [
                                TextField(
                                  controller: controller,
                                  style: GoogleFonts.plusJakartaSans(color: context.onSurface),
                                  decoration: InputDecoration(
                                    hintText: 'Enter value',
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () => _save(key),
                                    child: Text(
                                      'Save Setting',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        color: context.onBackground.withOpacity(0.87),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                          ]),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
