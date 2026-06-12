import '/components/category_chip/category_chip_widget.dart';
import '/components/project_card/project_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'investment_marketplace_model.dart';
export 'investment_marketplace_model.dart';

class InvestmentMarketplaceWidget extends StatefulWidget {
  const InvestmentMarketplaceWidget({super.key});

  static String routeName = 'InvestmentMarketplace';
  static String routePath = '/investmentMarketplace';

  @override
  State<InvestmentMarketplaceWidget> createState() =>
      _InvestmentMarketplaceWidgetState();
}

class _InvestmentMarketplaceWidgetState
    extends State<InvestmentMarketplaceWidget> {
  late InvestmentMarketplaceModel _model;

  bool isLoading = true;
  bool loadingInvestments = false;

  List<dynamic> projects = [];
  List<dynamic> filteredProjects = [];

  String selectedCategory = "All";

  final String baseUrl = AppConfig.api;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InvestmentMarketplaceModel());
    fetchProjects();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> fetchProjects() async {
    setState(() => isLoading = true);

    try {
      final token = FFAppState().accessToken;

      final response = await http.get(
        Uri.parse('$baseUrl/investments'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          projects = data['data'] ?? [];
          filteredProjects = projects;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;

      if (category == "All") {
        filteredProjects = projects;
      } else {
        filteredProjects = projects
            .where((p) => (p['category'] ?? '').toString().toLowerCase() ==
                category.toLowerCase())
            .toList();
      }
    });
  }

  void openProject(String id) {
    Navigator.pushNamed(
      context,
      '/projectDetails',
      arguments: id,
    );
  }

  double _totalRaised() {
    return filteredProjects.fold(0.0, (sum, p) {
      final v = double.tryParse(p['raised_amount']?.toString() ?? '0') ?? 0.0;
      return sum + v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalRaised = _totalRaised();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 12),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investment Marketplace',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A loop of growth through tokenized assets',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, decoration: BoxDecoration(color: FlutterFlowTheme.of(context).alternate)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Active Investments',
                                    style: FlutterFlowTheme.of(context).labelSmall.override(
                                          color: FlutterFlowTheme.of(context).onPrimary80,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                  Text(
                                    '${totalRaised.toStringAsFixed(2)} FARM',
                                    style: FlutterFlowTheme.of(context).titleLarge.override(
                                          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context).onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              Icon(Icons.trending_up_rounded, color: FlutterFlowTheme.of(context).onPrimary, size: 32),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(onTap: () => filterByCategory('All'), child: CategoryChipWidget(label: 'All Projects', selected: selectedCategory == 'All')),
                            const SizedBox(width: 16),
                            GestureDetector(onTap: () => filterByCategory('Real Estate'), child: CategoryChipWidget(label: 'Real Estate', selected: selectedCategory == 'Real Estate')),
                            const SizedBox(width: 16),
                            GestureDetector(onTap: () => filterByCategory('Agriculture'), child: CategoryChipWidget(label: 'Agriculture', selected: selectedCategory == 'Agriculture')),
                            const SizedBox(width: 16),
                            GestureDetector(onTap: () => filterByCategory('Energy'), child: CategoryChipWidget(label: 'Energy', selected: selectedCategory == 'Energy')),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (isLoading)
                        Center(child: Lottie.network('https://dimg.dreamflow.cloud/v1/lottie/subtle+loading+dots', width: 40, height: 40))
                      else if (filteredProjects.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Column(
                            children: [
                              Lottie.network('https://assets10.lottiefiles.com/packages/lf20_jtbfg2nb.json', width: 120, height: 120),
                              const SizedBox(height: 8),
                              Text('No projects found', style: FlutterFlowTheme.of(context).labelSmall),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: filteredProjects.map<Widget>((p) {
                            final id = p['id']?.toString() ?? p['_id']?.toString() ?? p['project_id']?.toString() ?? '';
                            final img = p['image_url']?.toString() ?? p['image']?.toString() ?? p['img']?.toString() ?? p['img_desc']?.toString();
                            final price = p['token_price']?.toString() ?? p['price']?.toString() ?? p['tokenPrice']?.toString() ?? '';
                            final roi = p['roi_percent']?.toString() ?? p['roi']?.toString() ?? p['return_on_investment']?.toString() ?? '';
                            final duration = p['duration']?.toString() ?? p['term']?.toString() ?? p['tenor']?.toString() ?? '—';
                            final title = p['project_name']?.toString() ?? p['title']?.toString() ?? 'Untitled';

                            return GestureDetector(
                              onTap: () => openProject(id),
                              child: ProjectCardWidget(
                                card_id: id,
                                duration: duration,
                                img_desc: img,
                                price: price,
                                roi: roi,
                                title: title,
                                onInvest: () => openProject(id),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
