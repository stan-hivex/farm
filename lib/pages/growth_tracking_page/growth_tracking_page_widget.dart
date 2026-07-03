import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import 'growth_tracking_page_model.dart';

export 'growth_tracking_page_model.dart';

class GrowthTrackingPageWidget extends StatefulWidget {
  const GrowthTrackingPageWidget({super.key});

  static String routeName = 'GrowthTrackingPage';
  static String routePath = '/growthTracking';

  @override
  State<GrowthTrackingPageWidget> createState() => _GrowthTrackingPageWidgetState();
}

class _GrowthTrackingPageWidgetState extends State<GrowthTrackingPageWidget> {
  late GrowthTrackingPageModel _model;

  bool _loading = true;
  String _error = '';
  String _selectedPeriod = 'daily';
  List<double> _values = [];
  List<String> _labels = [];
  double _growth = 0.0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GrowthTrackingPageModel());
    _loadGrowth();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadGrowth() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Simulate growth history data
      final payload = [];
      final history = payload;

      final values = history
          .map<double>((item) => double.tryParse((item['total'] ?? item['value'] ?? item['amount'] ?? 0).toString()) ?? 0.0)
          .toList();
      final labels = history
          .map<String>((item) => item['date']?.toString() ?? item['day']?.toString() ?? item['label']?.toString() ?? '')
          .toList();
      final growth = (values.length > 1 && values.isNotEmpty && values.first > 0)
          ? ((values.last - values.first) / values.first) * 100
          : 0.0;

      if (!mounted) return;
      setState(() {
        _values = values;
        _labels = labels;
        _growth = growth;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Growth Tracking'),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGrowth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your growth overview', style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _periodChip('Daily', 'daily'),
                  _periodChip('Weekly', 'weekly'),
                  _periodChip('Monthly', 'monthly'),
                  _periodChip('Yearly', 'yearly'),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Performance', style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.successColor.withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_growth.toStringAsFixed(1)}%',
                              style: TextStyle(color: context.successColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                      else if (_error.isNotEmpty)
                        Text(_error, style: TextStyle(color: context.errorColorAccent))
                      else if (_values.isEmpty)
                        Text('No growth data available yet.', style: theme.bodyMedium)
                      else
                        SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterFlowLineChart(
                              data: [
                                FFLineChartData(
                                  xData: List.generate(_values.length, (index) => index.toDouble()),
                                  yData: _values,
                                  settings: LineChartBarData(
                                    color: theme.primary,
                                    barWidth: 2.5,
                                    isCurved: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true, color: theme.primary10),
                                  ),
                                )
                              ],
                              chartStylingInfo: const ChartStylingInfo(backgroundColor: Colors.transparent, showBorder: false),
                              axisBounds: AxisBounds(minX: 0, minY: 0, maxX: (_values.length - 1).toDouble(), maxY: _values.isNotEmpty ? _values.reduce((a, b) => a > b ? a : b) * 1.2 : 100),
                              xLabels: _labels,
                              xAxisLabelInfo: AxisLabelInfo(showLabels: true, labelTextStyle: theme.bodySmall.override(font: GoogleFonts.inter()), reservedSize: 28),
                              yAxisLabelInfo: const AxisLabelInfo(reservedSize: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedPeriod = value);
        _loadGrowth();
      },
    );
  }
}
