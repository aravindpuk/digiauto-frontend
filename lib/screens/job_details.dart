import 'package:flutter/material.dart';

/// job_details_page.dart
/// Single-file, static UI demo for:
/// - Complaints list with completion toggles
/// - Add / remove labour & spare via BottomSheet
/// - Link labour/spare to a complaint (optional)
/// - Auto-updating job status and billing summary
///
/// Drop into a Flutter project and run.

class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  // ---- STATIC DUMMY COMPLAINTS ----
  List<Map<String, dynamic>> complaints = [
    {
      "title": "Engine Noise",
      "completed": false,
      "labours": [
        {"name": "Engine Tuning", "rate": 500},
      ],
      "spares": [
        {"name": "Engine Oil", "qty": 1, "rate": 350},
      ],
    },
    {"title": "Brake Issue", "completed": false, "labours": [], "spares": []},
    {
      "title": "General Service",
      "completed": false,
      "labours": [],
      "spares": [],
    },
  ];

  // Track which accordion is open
  int openedIndex = -1;
  String jobStatus = "In Progress";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Job Details", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7BA6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildJobHeader(),
          const SizedBox(height: 10),
          _buildCustomerDetails(),
          const SizedBox(height: 10),
          _buildVehicleDetails(),
          const SizedBox(height: 10),
          _buildBillSummary(),
          const SizedBox(height: 15),

          // _buildSectionTitle("Complaint-wise Work Status"),

          // ------------- ACCORDION COMPLAINTS -------------
          ...List.generate(complaints.length, (index) {
            return _buildComplaintAccordion(index);
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // JOB HEADER WITH STATUS BADGE
  Widget _buildJobHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Job ID: JOB1234",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7BA6),
                ),
              ),
              SizedBox(height: 6),
            ],
          ),

          // 🔥 STATUS BADGE BUTTON
          InkWell(
            onTap: _openStatusUpdateSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(jobStatus),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                jobStatus,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "In Progress":
        return const Color.fromARGB(255, 50, 121, 162);
      case "Completed":
        return const Color.fromARGB(255, 110, 202, 113);
      case "Delivered":
        return const Color.fromARGB(255, 61, 152, 64);
      default:
        return Colors.grey;
    }
  }

  void _openStatusUpdateSheet() {
    List<String> statusOptions = [
      "Pending",
      "In Progress",
      "Completed",
      "Delivered",
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update Job Status",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // OPTIONS
              ...statusOptions.map((status) {
                return RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(status),
                  value: status,
                  groupValue: jobStatus,
                  onChanged: (val) {
                    setState(() {
                      jobStatus = val!;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // CUSTOMER
  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Customer Details",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7BA6),
            ),
          ),
          SizedBox(height: 8),
          Text("Name: Arjun"),
          Text("Mobile: 9876543210"),
        ],
      ),
    );
  }

  // VEHICLE
  Widget _buildVehicleDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Vehicle Details",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7BA6),
            ),
          ),
          SizedBox(height: 8),
          Text("Vehicle No: KL 55 A 1234"),
          Text("Model: Swift"),
          Text("Type: Car"),
        ],
      ),
    );
  }

  // BILL SUMMARY
  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Billing Summary",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7BA6),
            ),
          ),
          SizedBox(height: 10),
          Text("Labour Total: ₹750"),
          Text("Spare Total: ₹550"),

          SizedBox(height: 6),
          Text(
            "Grand Total: ₹1300",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  Widget _buildSectionTitle(text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCORDION UI FOR EACH COMPLAINT
  Widget _buildComplaintAccordion(int index) {
    var item = complaints[index];
    bool isOpen = openedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _box(),
      child: Column(
        children: [
          // ----- ACCORDION HEADER -----
          InkWell(
            onTap: () {
              setState(() {
                openedIndex = (openedIndex == index) ? -1 : index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TITLE + BADGE
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          item["title"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7BA6),
                          ),
                        ),

                        // const SizedBox(width: 10),
                        Spacer(),
                        _statusBadge(item["completed"]),
                      ],
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),

          // ----- CONTENT WHEN OPEN -----
          if (isOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subTitle("Labours"),
                  ..._labourList(index),

                  _addButton("Add Labour", () => _openAddLabourSheet(index)),

                  const SizedBox(height: 10),

                  _subTitle("Spares"),
                  ..._spareList(index),

                  _addButton("Add Spare", () => _openAddSpareSheet(index)),

                  const Divider(height: 20),

                  // COMPLAINT COMPLETED CHECKBOX
                  Row(
                    children: [
                      Checkbox(
                        value: item["completed"],
                        onChanged: (val) {
                          setState(() {
                            complaints[index]["completed"] = val!;
                          });
                        },
                      ),
                      const Text("Mark Complaint Completed"),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LABOUR LIST
  List<Widget> _labourList(int i) {
    return complaints[i]["labours"].map<Widget>((lab) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(lab["name"]),
        trailing: Text("₹${lab["rate"]}"),
      );
    }).toList();
  }

  // SPARE LIST
  List<Widget> _spareList(int i) {
    return complaints[i]["spares"].map<Widget>((sp) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(sp["name"]),
        subtitle: Text("Qty: ${sp["qty"]}"),
        trailing: Text("₹${sp["rate"]}"),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // ADD BUTTON
  Widget _addButton(String text, VoidCallback onTap) {
    // return InkWell(
    //   onTap: onTap,
    //   child: Container(
    //     margin: const EdgeInsets.only(top: 6),
    //     padding: const EdgeInsets.all(10),
    //     decoration: BoxDecoration(
    //       color: Colors.blue.shade50,
    //       borderRadius: BorderRadius.circular(6),
    //     ),
    //     child: Row(
    //       children: [
    //         const Icon(Icons.add, color: Colors.blue),
    //         const SizedBox(width: 6),
    //         Text(text, style: const TextStyle(color: Colors.blue)),
    //       ],
    //     ),
    //   ),
    // );
    return TextButton(
      onPressed: onTap,
      child: Row(
        children: [
          const Icon(Icons.add, color: Colors.blue),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD LABOUR SHEET
  void _openAddLabourSheet(int index) {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController rateCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Labour",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: rateCtrl,
              decoration: const InputDecoration(labelText: "Rate"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  complaints[index]["labours"].add({
                    "name": nameCtrl.text,
                    "rate": double.tryParse(rateCtrl.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  // ADD SPARE SHEET
  void _openAddSpareSheet(int index) {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController qtyCtrl = TextEditingController();
    TextEditingController rateCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Spare",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Spare Name"),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            TextField(
              controller: rateCtrl,
              decoration: const InputDecoration(labelText: "Rate"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  complaints[index]["spares"].add({
                    "name": nameCtrl.text,
                    "qty": int.tryParse(qtyCtrl.text) ?? 1,
                    "rate": double.tryParse(rateCtrl.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BADGE
  Widget _statusBadge(bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        completed ? "Done" : "Pending",
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  // BOX STYLE
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
    ],
  );

  Widget _subTitle(text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
