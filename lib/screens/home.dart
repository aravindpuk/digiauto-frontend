import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:digiauto/modal/labour.dart';
import 'package:digiauto/screens/job_details.dart';
import 'package:digiauto/screens/jobcard.dart';
import 'package:digiauto/screens/reports.dart';
import 'package:digiauto/screens/spare.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryColor = const Color(0xFF2E7BA6);
  final Color secondaryColor = const Color(0xFFFF5733);

  int currentIndex = 0;

  final iconList = [
    Icons.assignment_add,
    Icons.build_circle,
    Icons.handyman,
    Icons.bar_chart_rounded,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        // backgroundColor: primaryColor,
        elevation: 2,
        title: const Text(
          "Digi Auto",
          // style: TextStyle(
          //   color: Color(0xFFF8F9FA),
          //   fontWeight: FontWeight.w600,
          // ),
        ),
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

      // Tabs below app bar
      body: Column(
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
                _buildJobList("active"),
                _buildJobList("pending"),
                _buildJobList("completed"),
              ],
            ),
          ),
        ],
      ),

      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: secondaryColor.withOpacity(0.95),
      //   selectedItemColor: Colors.white,
      //   unselectedItemColor: Colors.white70,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //     BottomNavigationBarItem(icon: Icon(Icons.build), label: "Create Job"),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Spares"),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.bar_chart),
      //       label: "Reports",
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: "Settings"),
      //   ],
      // ),
      bottomNavigationBar: animatedBottomNavigation(),
    );
  }

  // --- Job List Builder ---
  Widget _buildJobList(String status) {
    final jobs = [
      {
        "vehicle": "KL 11 AB 2345",
        "customer": "John Smith",
        "date": "2025-11-05 09:45 AM",
        "cost": "₹ 2,350",
        "status": status == "completed" ? "delivered" : status,
      },
      {
        "vehicle": "KL 07 BC 5678",
        "customer": "David Mathew",
        "date": "2025-11-05 11:00 AM",
        "cost": "₹ 1,120",
        "status": status,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final color = _getBorderColor(job["status"]!);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailsPage()),
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
                // Colored border top
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
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            job["vehicle"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _getStatusIcon(job["status"]!),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Customer: ${job["customer"]}"),
                      Text("Date: ${job["date"]}"),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "Total: ${job["cost"]}",
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

  // --- Helpers ---
  Color _getBorderColor(String status) {
    switch (status) {
      case "pending":
        return Colors.redAccent;
      case "active":
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

  animatedBottomNavigation() {
    final labels = ["Create Job", "Spares", "Labours", "Reports", "Settings"];

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
          // means crate job
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobCardFormScreen()),
          );
        } else if (index == 1) {
          // spares
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpareForm()),
          );
        } else if (index == 2) {
          // labours
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => const LabourFormSheet(),
          );
        } else if (index == 3) {
          // reports
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportScreen()),
          );
        } else {
          // settings
        }
      },
      backgroundColor: secondaryColor.withOpacity(0.95),
    );
  }
}
