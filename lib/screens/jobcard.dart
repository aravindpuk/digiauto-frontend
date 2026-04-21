import 'package:digiauto/services/speech_text.dart';
import 'package:flutter/material.dart';

// class JobCardFormScreen extends StatefulWidget {
//   const JobCardFormScreen({super.key});

//   @override
//   State<JobCardFormScreen> createState() => _JobCardFormScreenState();
// }

// class _JobCardFormScreenState extends State<JobCardFormScreen> {
//   final _vehicleNoCtrl = TextEditingController();
//   final _customerNameCtrl = TextEditingController();
//   final _mobileCtrl = TextEditingController();
//   final _addressCtrl = TextEditingController();

//   final _makeCtrl = TextEditingController();
//   final _modelCtrl = TextEditingController();
//   final _yearCtrl = TextEditingController();
//   final _engineCtrl = TextEditingController();
//   final _chassisCtrl = TextEditingController();
//   final _kmCtrl = TextEditingController();

//   final List<TextEditingController> _complaints = [];

//   @override
//   void initState() {
//     super.initState();
//     _complaints.add(TextEditingController());
//   }

//   @override
//   void dispose() {
//     for (var c in _complaints) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Job Card")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _vehicleNumberSection(theme),
//             _customerSection(theme),
//             _vehicleDetailsSection(theme),
//             _jobDetailsSection(theme),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: theme.colorScheme.secondary,
//                 ),
//                 onPressed: () {},
//                 child: Text(
//                   "Create Job Card",
//                   style: TextStyle(color: theme.colorScheme.onSecondary),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _vehicleNumberSection(ThemeData theme) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _vehicleNoCtrl,
//                 decoration: InputDecoration(
//                   // labelText: "Vehicle Registration Number",
//                   label: RichText(
//                     text: const TextSpan(
//                       text: "Vehicle Registration Number",
//                       style: TextStyle(color: Colors.black),
//                       children: [
//                         TextSpan(
//                           text: "*",
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             IconButton(
//               icon: const Icon(Icons.search),
//               color: theme.colorScheme.primary,
//               onPressed: () {
//                 // API call later (fetch vehicle)
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _customerSection(ThemeData theme) {
//     return Card(
//       margin: const EdgeInsets.only(top: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Customer Details", theme),
//             TextField(
//               controller: _customerNameCtrl,
//               decoration: InputDecoration(
//                 // labelText: "Customer Name"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Customer Name",
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: "*",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             TextField(
//               controller: _mobileCtrl,
//               keyboardType: TextInputType.phone,
//               decoration: InputDecoration(
//                 // labelText: "Mobile Number"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Mobile Number",
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: "*",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             TextField(
//               controller: _addressCtrl,
//               maxLines: 2,
//               decoration: InputDecoration(
//                 // labelText: "Address"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Place",
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: "*",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _vehicleDetailsSection(ThemeData theme) {
//     return Card(
//       margin: const EdgeInsets.only(top: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Vehicle Details", theme),

//             /// MAKE AUTOCOMPLETE
//             Autocomplete<String>(
//               optionsBuilder: (text) {
//                 if (text.text.isEmpty) return const Iterable.empty();
//                 return ["Honda", "Hyundai", "Suzuki", "Tata", "Toyota"].where(
//                   (e) => e.toLowerCase().contains(text.text.toLowerCase()),
//                 );
//               },
//               onSelected: (val) => _makeCtrl.text = val,
//               fieldViewBuilder: (_, ctrl, focus, __) {
//                 ctrl.text = _makeCtrl.text;
//                 return TextField(
//                   controller: ctrl,
//                   focusNode: focus,
//                   decoration: InputDecoration(
//                     // labelText: "Vehicle Make"
//                     label: RichText(
//                       text: const TextSpan(
//                         text: "Vehicle Make",
//                         style: TextStyle(color: Colors.black),
//                         children: [
//                           TextSpan(
//                             text: "*",
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),

//             /// MODEL AUTOCOMPLETE
//             Autocomplete<String>(
//               optionsBuilder: (text) {
//                 if (text.text.isEmpty) return const Iterable.empty();
//                 return ["Swift", "City", "Creta", "Nexon"].where(
//                   (e) => e.toLowerCase().contains(text.text.toLowerCase()),
//                 );
//               },
//               onSelected: (val) => _modelCtrl.text = val,
//               fieldViewBuilder: (_, ctrl, focus, __) {
//                 ctrl.text = _modelCtrl.text;
//                 return TextField(
//                   controller: ctrl,
//                   focusNode: focus,
//                   decoration: InputDecoration(
//                     // labelText: "Vehicle Model"
//                     label: RichText(
//                       text: const TextSpan(
//                         text: "Vehicle Model",
//                         style: TextStyle(color: Colors.black),
//                         children: [
//                           TextSpan(
//                             text: "*",
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),

//             TextField(
//               controller: _yearCtrl,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 // labelText: "Manufacture Year"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Manufacture Year",
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: "*",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             TextField(
//               controller: _engineCtrl,
//               decoration: InputDecoration(
//                 // labelText: "Engine Number"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Engine Number",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),
//             ),
//             TextField(
//               controller: _chassisCtrl,
//               decoration: InputDecoration(
//                 // labelText: "Chassis Number"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Chassis Number",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _jobDetailsSection(ThemeData theme) {
//     return Card(
//       margin: const EdgeInsets.only(top: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Job Card Details", theme),

//             TextField(
//               controller: _kmCtrl,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 // labelText: "Current Kilometer"
//                 label: RichText(
//                   text: const TextSpan(
//                     text: "Current Kilometer",
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: "*",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             const Text("Service Request"),
//             const SizedBox(height: 8),

//             ..._complaints.asMap().entries.map((entry) {
//               final i = entry.key;
//               return Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _complaints[i],
//                       decoration: InputDecoration(hintText: "service ${i + 1}"),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.remove_circle, color: Colors.red),
//                     onPressed: () {
//                       setState(() => _complaints.removeAt(i));
//                     },
//                   ),
//                 ],
//               );
//             }),

//             Align(
//               alignment: Alignment.centerLeft,
//               child: TextButton.icon(
//                 icon: Icon(Icons.add, color: theme.colorScheme.secondary),
//                 label: const Text("Add Service"),
//                 onPressed: () {
//                   setState(() => _complaints.add(TextEditingController()));
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title, ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Text(
//         title,
//         style: theme.textTheme.titleMedium?.copyWith(
//           fontWeight: FontWeight.bold,
//           color: theme.colorScheme.primary,
//         ),
//       ),
//     );
//   }
// }

///// caht based ui...
///
///

class JobCardChatScreen extends StatefulWidget {
  const JobCardChatScreen({super.key});

  @override
  State<JobCardChatScreen> createState() => _JobCardChatScreenState();
}

class _JobCardChatScreenState extends State<JobCardChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  List<Map<String, dynamic>> messages = [
    {"isUser": false, "text": "Welcome! Let's create a job card 🚗"},
    {"isUser": false, "text": "Enter vehicle number"},
  ];

  List<String> serviceRequests = [];

  VoiceService voiceService = VoiceService();

  int step = 0;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"isUser": true, "text": text});
    });

    _msgCtrl.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      handleFlow(text);
    });
  }

  void handleFlow(String input) {
    String reply = "";

    switch (step) {
      case 0:
        reply = "Customer name?";
        break;
      case 1:
        reply = "Mobile number?";
        break;
      case 2:
        reply = "Enter service request (you can add multiple)";
        break;
      case 3:
        serviceRequests.add(input);
        reply = "Add another service or type 'done'";
        if (input.toLowerCase() == "done") {
          step++;
          reply =
              "Do you want to add engine number or chassis number? (or tap skip)";
        }
        break;
      case 4:
        if (input.toLowerCase() == "skip") {
          step++;
          reply = "Confirm job card? Type YES to continue";
        } else {
          reply = "Enter chassis number or type skip";
          step++;
        }
        break;
      case 5:
        reply = "Confirm job card? Type YES to continue";
        break;
      case 6:
        if (input.toLowerCase() == "yes") {
          reply = "✅ Job card created successfully!";
          createJobCardAPI();
        } else {
          reply = "Type YES to confirm";
          step--;
        }
        break;
    }

    setState(() {
      messages.add({"isUser": false, "text": reply});
      step++;
    });
  }

  /// 🔥 API CALL
  void createJobCardAPI() {
    // call your Django API here
    print("API CALLED");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Job Card")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _chatBubble(messages[index], theme, index);
              },
            ),
          ),
          _inputArea(theme),
        ],
      ),
    );
  }

  /// 💬 CHAT BUBBLE WITH EDIT OPTION
  Widget _chatBubble(Map<String, dynamic> msg, ThemeData theme, int index) {
    final isUser = msg["isUser"];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isUser ? theme.colorScheme.secondary : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg["text"],
              style: TextStyle(
                color: isUser ? theme.colorScheme.onSecondary : Colors.black,
              ),
            ),
          ),

          /// ✏️ EDIT BUTTON
          if (isUser)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                _msgCtrl.text = msg["text"];
                setState(() {
                  messages.removeAt(index);
                });
              },
            ),
        ],
      ),
    );
  }

  /// 🎤 INPUT AREA WITH MIC + SEND + SKIP
  Widget _inputArea(ThemeData theme) {
    return Column(
      children: [
        /// SKIP BUTTON FOR OPTIONAL
        if (step >= 4)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => sendMessage("skip"),
              child: const Text("Skip"),
            ),
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              /// 🎤 MIC BUTTON
              IconButton(
                icon: Icon(
                  voiceService.isListening ? Icons.stop : Icons.mic,
                  size: 30,
                  color: voiceService.isListening ? Colors.red : Colors.grey,
                ),
                onPressed: onMicPressed,
              ),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: voiceService.isListening
                        ? "Listening..."
                        : "Type or speak...",
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              CircleAvatar(
                backgroundColor: theme.colorScheme.secondary,
                child: IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.onSecondary),
                  onPressed: () => sendMessage(_msgCtrl.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🎤 SPEECH TO TEXT
  void onMicPressed() async {
    String lastText = _msgCtrl.text;
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      await voiceService.init();

      await voiceService.startListening((text) {
        setState(() {
          if (text.length > lastText.length) {
            _msgCtrl.text += text.substring(
              lastText.length,
            ); // fill into input field
          }
          lastText = text; // fill into input field
        });
      });
    }
    setState(() {});
  }
}
