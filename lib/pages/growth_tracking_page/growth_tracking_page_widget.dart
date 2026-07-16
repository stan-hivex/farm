
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'growth_tracking_page_model.dart';

export 'growth_tracking_page_model.dart';

class GrowthTrackingPageWidget extends StatefulWidget {
  const GrowthTrackingPageWidget({super.key});

  static String routeName = 'GrowthTrackingPage';
  static String routePath = '/growthTracking';

  @override
  State<GrowthTrackingPageWidget> createState() =>
      _GrowthTrackingPageWidgetState();
}

class _GrowthTrackingPageWidgetState extends State<GrowthTrackingPageWidget> {
  late GrowthTrackingPageModel _model;

  bool _loading = true;
  String _error = '';
  String _selectedPeriod = 'daily';
  List<double> _values = [];
  List<String> _labels = [];
  double _growth = 0.0;

  double get _chartMaxY =>
      _values.isNotEmpty ? max(72.0, _values.reduce(max) * 1.2) : 72.0;

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
      final period = {
        'daily': 7,
        'weekly': 30,
        'monthly': 90,
        'yearly': 365,
      }[_selectedPeriod]!;

      final payload = await ApiService.getGrowthHistory(days: period);
      final history =
          payload['data'] is List ? payload['data'] as List : <dynamic>[];

      final values = history
          .map<double>((item) =>
              double.tryParse(
                  (item['total'] ?? item['value'] ?? item['amount'] ?? 0)
                      .toString()) ??
              0.0)
          .toList();
      final labels = history
          .map<String>((item) =>
              item['date']?.toString() ??
              item['day']?.toString() ??
              item['label']?.toString() ??
              '')
          .toList();
      final growth =
          (values.length > 1 && values.isNotEmpty && values.first > 0)
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
              Text('Your growth overview',
                  style:
                      theme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
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
                color: theme.primaryBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Performance',
                                style: theme.titleMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.success.withAlpha(32),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_growth.toStringAsFixed(1)}%',
                              style: theme.labelLarge.override(
                                fontWeight: FontWeight.w700,
                                color: theme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        Center(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator()))
                      else if (_error.isNotEmpty)
                        Text(_error,
                            style:
                                theme.bodyMedium.override(color: theme.error))
                      else if (_values.isEmpty)
                        Text('No growth data available yet.',
                            style: theme.bodyMedium)
                      else
                        SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterFlowLineChart(
                              data: [
                                FFLineChartData(
                                  xData: List.generate(_values.length,
                                      (index) => index.toDouble()),
                                  yData: _values,
                                  settings: LineChartBarData(
                                    color: theme.primary,
                                    barWidth: 2.5,
                                    isCurved: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                        show: true, color: theme.primary10),
                                  ),
                                )
                              ],
                              chartStylingInfo: ChartStylingInfo(
                                backgroundColor: theme.primaryBackground,
                                showBorder: false,
                              ),
                              axisBounds: AxisBounds(
                                minX: 0,
                                minY: 0,
                                maxX: _values.isNotEmpty
                                    ? max(6.0, (_values.length - 1).toDouble())
                                    : 6.0,
                                maxY: _chartMaxY,
                              ),
                              xLabels: _labels,
                              xAxisLabelInfo: AxisLabelInfo(
                                showLabels: true,
                                labelTextStyle: theme.bodySmall.override(
                                    font: GoogleFonts.inter(),
                                    color: theme.secondaryText),
                                labelInterval: 1.0,
                                reservedSize: 26.0,
                              ),
                              yAxisLabelInfo: AxisLabelInfo(
                                showLabels: true,
                                labelTextStyle: theme.bodySmall.override(
                                    font: GoogleFonts.inter(),
                                    color: theme.secondaryText),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _periodChip('Daily', 'daily'),
                          const SizedBox(width: 8),
                          _periodChip('Weekly', 'weekly'),
                          const SizedBox(width: 8),
                          _periodChip('Monthly', 'monthly'),
                          const SizedBox(width: 8),
                          _periodChip('Yearly', 'yearly'),
                        ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedFillColor = isDarkMode ? Colors.white : Colors.black;
    final selectedTextColor = isDarkMode ? Colors.black : Colors.white;
    final unselectedTextColor = isDarkMode ? Colors.white : Colors.black87;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? selectedTextColor : unselectedTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedPeriod = value);
        _loadGrowth();
      },
      backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
      selectedColor: selectedFillColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? selectedFillColor : (isDarkMode ? Colors.white24 : Colors.black12),
          width: 1.2,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
