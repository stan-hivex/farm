import 'dart:convert';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProjectDetailsWidget extends StatefulWidget {
  final String projectId;

  const ProjectDetailsWidget({
    super.key,
    required this.projectId,
  });

  static String routeName = 'ProjectDetails';
  static String routePath = '/projectDetails';

  @override
  State<ProjectDetailsWidget> createState() => _ProjectDetailsWidgetState();
}

class _ProjectDetailsWidgetState extends State<ProjectDetailsWidget> {
  bool isLoading = true;
  bool investing = false;

  Map<String, dynamic>? project;

  final TextEditingController amountController = TextEditingController();

  final String baseUrl = AppConfig.api;

  @override
  void initState() {
    super.initState();
    fetchProject();
  }

  Future<void> fetchProject() async {
  if (widget.projectId.isEmpty) {
    setState(() {
      isLoading = false;
      project = null;
    });
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/${widget.projectId}'),
    );

    debugPrint("PROJECT RESPONSE: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['data'] != null) {
      setState(() {
        project = data['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        project = null;
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("ERROR: $e");

    setState(() {
      project = null;
      isLoading = false;
    });
  }
}

  Future<void> investNow() async {
    if (amountController.text.isEmpty) return;

    setState(() {
      investing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/invest'),
        headers: {
          'Content-Type': 'application/json',

          // ADD USER TOKEN
          'Authorization': 'Bearer YOUR_JWT_TOKEN',
        },
        body: jsonEncode({
          'project_id': project!['id'],
          'amount': double.parse(amountController.text),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
          ),
        );

        fetchProject();

        amountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Investment failed'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      investing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (project == null) {
      return const Scaffold(
        body: Center(
          child: Text('Project not found'),
        ),
      );
    }

    final totalTokens =
        double.tryParse(project!['total_tokens'].toString()) ?? 0;

    final soldTokens =
        double.tryParse(project!['sold_tokens'].toString()) ?? 0;

    final availableTokens =
        double.tryParse(project!['available_tokens'].toString()) ?? 0;

    final fundingPercent =
        totalTokens == 0 ? 0.0 : (soldTokens / totalTokens);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // HERO IMAGE
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          project!['image_url'] ??
                          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854',
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),

                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius:
                                        BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    project!['category'] ?? 'AgriTech',
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius:
                                        BorderRadius.circular(50),
                                  ),
                                  child: const Text('Verified'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Text(
                              project!['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey,
                                ),

                                const SizedBox(width: 4),

                                Text(
                                  project!['location'] ??
                                      'Kenya',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // GROWTH PROJECTION
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Growth Projection',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            Text(
                              '${project!['roi_percentage']}% ROI',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'Chart Area\n(Connect your FlutterFlow chart here)',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // STATS GRID
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: GridView(
                    physics:
                        const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    children: [
                      statCard(
                        'Total Value',
                        '${project!['total_value']} FARM',
                      ),

                      statCard(
                        'Token Price',
                        '${project!['token_price']} FARM',
                      ),

                      statCard(
                        'Duration',
                        '${project!['duration_months']} Months',
                      ),

                      statCard(
                        'Available Tokens',
                        '${availableTokens.toStringAsFixed(0)} / ${totalTokens.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ABOUT
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About the Project',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          project!['description'] ?? '',
                          style: const TextStyle(
                            height: 1.6,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // FUNDING
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Funding Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            Text(
                              '${(fundingPercent * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        LinearPercentIndicator(
                          lineHeight: 10,
                          percent: fundingPercent,
                          progressColor: Colors.green,
                          backgroundColor:
                              Colors.grey.shade300,
                          barRadius:
                              const Radius.circular(50),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sold: ${soldTokens.toStringAsFixed(0)}',
                            ),

                            Text(
                              'Available: ${availableTokens.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 140),
              ],
            ),
          ),

          // BOTTOM INVEST BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType:
                            TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              investing ? null : investNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      16),
                            ),
                          ),
                          child: investing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Invest Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}