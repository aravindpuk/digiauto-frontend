import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:digiauto/custom_widgets/assistant_button.dart';
import 'package:digiauto/models/job_card.dart';
import 'package:digiauto/screens/job_details.dart';
import 'package:digiauto/screens/reports.dart';
import 'package:digiauto/screens/spare.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobcardService _jobcardService = JobcardService();

  final Color primaryColor = const Color(0xFF2E7BA6);
  final Color secondaryColor = const Color(0xFFFF5733);

  int currentIndex = 0;
  late Future<List<JobCard>> _jobsFuture;

  final iconList = [
    Icons.build_circle,
    Icons.bar_chart_rounded,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _jobsFuture = _jobcardService.fetchJobs();
  }

  void _reloadJobs() {
    setState(() {
      _jobsFuture = _jobcardService.fetchJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 2,
        title: const Text("Digi Auto"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search by vehicle Number...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.only(top: 10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<JobCard>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          final jobs = snapshot.data ?? const <JobCard>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildStateCard(
              title: "Could not load jobs",
              subtitle: "Check the Django API connection and try again.",
            );
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "Active"),
                    Tab(text: "Pending"),
                    Tab(text: "Completed"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobList("active", jobs),
                    _buildJobList("pending", jobs),
                    _buildJobList("completed", jobs),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: animatedBottomNavigation(),
      floatingActionButton: FutureBuilder<List<JobCard>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          return AssistantButton(
            hasExistingJobs: (snapshot.data ?? const <JobCard>[]).isNotEmpty,
            onJobCreated: _reloadJobs,
          );
        },
      ),
    );
  }

  Widget _buildJobList(String status, List<JobCard> jobs) {
    final filteredJobs = jobs.where((job) {
      final normalized = job.status.toLowerCase();
      if (status == "completed") {
        return normalized == "completed" || normalized == "delivered";
      }
      return normalized == status;
    }).toList();

    if (filteredJobs.isEmpty) {
      return _buildStateCard(
        title: "No $status jobs yet",
        subtitle: " Active Jobs will appear here.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        final color = _getBorderColor(job.status.toLowerCase());

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailsPage(job: job)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job.vehicleNumber.isEmpty
                                  ? "Vehicle pending"
                                  : job.vehicleNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _getStatusIcon(job.status.toLowerCase()),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Customer: ${job.customerName.isEmpty ? '-' : job.customerName}",
                      ),
                      Text("Date: ${job.createdAt}"),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "Total: ${job.total}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
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
      },
    );
  }

  Widget _buildStateCard({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 40,
                color: primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(String status) {
    switch (status) {
      case "pending":
        return Colors.redAccent;
      case "active":
      case "in progress":
        return primaryColor;
      case "completed":
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case "pending":
        return const Icon(Icons.access_time, color: Colors.redAccent);
      case "active":
      case "in progress":
        return Icon(Icons.build_circle, color: primaryColor);
      case "completed":
        return const Icon(Icons.check_circle, color: Colors.blue);
      case "delivered":
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_shipping, color: Colors.green),
            SizedBox(width: 4),
            Text(
              "Delivered",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  Widget animatedBottomNavigation() {
    const labels = ["Spares", "Reports", "Settings"];

    return AnimatedBottomNavigationBar.builder(
      itemCount: iconList.length,
      tabBuilder: (index, isActive) {
        final color = isActive ? Colors.white : Colors.white70;
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconList[index], size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
      activeIndex: currentIndex,
      gapLocation: GapLocation.none,
      notchSmoothness: NotchSmoothness.softEdge,
      onTap: (index) {
        setState(() => currentIndex = index);
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpareForm()),
          );
        }
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          );
        }
        if (index == 2) {
          // Handle settings navigation
        }
      },
      backgroundColor: secondaryColor.withOpacity(0.95),
    );
  }
}
