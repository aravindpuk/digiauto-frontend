import 'package:digiauto/models/chat.dart';
import 'package:digiauto/services/manage_job_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sub-steps inside manage-jobs
enum ManageStep {
  loadingList,   // fetching job list
  showList,      // showing job list as options
  showActions,   // showing action options for a selected job
  confirmStatus, // confirming status advance
  confirmDelete, // confirming delete
  addLabourSearch,  // user typing labour name
  addLabourAmount,  // user entering amount
  removeLabour,  // listing labours for removal
  done,          // terminal — pop back
  error,
}

class ManageJobCubit extends Cubit<List<ChatMessage>> {
  ManageJobCubit({required ManageJobService service})
      : _service = service,
        super([]);

  final ManageJobService _service;

  ManageStep manageStep = ManageStep.loadingList;
  bool isBusy = false;

  // selected job data
  int? selectedJobId;
  String? selectedJobDisplay;  // "DIGI-J01 • KL11U1234"
  String? selectedJobStatus;

  // labour add flow
  List<Map<String, dynamic>> labourSearchResults = [];
  int? pendingLabourId;
  String? pendingLabourName;

  // labour list for removal
  List<Map<String, dynamic>> existingLabours = [];

  // Whether input bar should be visible
  bool get showInput =>
      manageStep == ManageStep.addLabourSearch ||
      manageStep == ManageStep.addLabourAmount;

  String get inputHint {
    if (manageStep == ManageStep.addLabourSearch) return "Search labour name...";
    if (manageStep == ManageStep.addLabourAmount) return "Enter amount (₹)";
    return "";
  }

  // ── Start ─────────────────────────────────────────────────────────────────

  Future<void> start() async {
    _addBot("Fetching your job cards...");
    isBusy = true;
    try {
      final jobs = await _service.fetchManageList();
      isBusy = false;
      if (jobs.isEmpty) {
        _addBot("No active job cards found.");
        manageStep = ManageStep.done;
        return;
      }
      manageStep = ManageStep.showList;
      final options = jobs.map((j) =>
          "${j['job_id']} • ${j['vehicle_number']} (${j['status']})").toList();
      emit([
        ...state,
        ChatMessage(
          text: "Select a job card to manage:",
          isUser: false,
          options: options,
          step: 0,
        ),
      ]);
    } catch (e) {
      isBusy = false;
      manageStep = ManageStep.error;
      _addBot("Could not load jobs. Please try again.");
    }
  }

  // ── Job selected ──────────────────────────────────────────────────────────

  Future<void> selectJob(String display) async {
    _addUserMsg(display);
    isBusy = true;
    _addBot("Loading job details...");

    try {
      // Parse id from display string "DIGI-J01 • KL11U1234 (pending)"
      // We re-fetch the list to find the id
      final jobs = await _service.fetchManageList();
      isBusy = false;

      // Match by job_id prefix inside display
      final match = jobs.firstWhere(
        (j) => display.startsWith(j['job_id'].toString()),
        orElse: () => {},
      );
      if (match.isEmpty) {
        _addBot("Could not find that job. Please try again.");
        return;
      }

      selectedJobId      = match['id'] as int;
      selectedJobDisplay = "${match['job_id']} • ${match['vehicle_number']}";
      selectedJobStatus  = match['status'] as String;

      manageStep = ManageStep.showActions;
      _showActionOptions();
    } catch (e) {
      isBusy = false;
      _addBot("Something went wrong. Please try again.");
    }
  }

  void _showActionOptions() {
    final status = selectedJobStatus ?? "pending";
    final canAdvance = !["delivered"].contains(status.toLowerCase());

    final actions = [
      if (canAdvance) "Update Status",
      "Add Labour",
      "Remove Labour",
      "Edit Job Card",
      "Delete Job Card",
    ];

    emit([
      ...state,
      ChatMessage(
        text: "What would you like to do with $selectedJobDisplay?",
        isUser: false,
        options: actions,
        step: 1,
      ),
    ]);
  }

  // ── Action selected ───────────────────────────────────────────────────────

  Future<void> selectAction(String action) async {
    _addUserMsg(action);

    switch (action) {
      case "Update Status":
        await _startStatusUpdate();
        break;
      case "Add Labour":
        await _startAddLabour();
        break;
      case "Remove Labour":
        await _startRemoveLabour();
        break;
      case "Edit Job Card":
        manageStep = ManageStep.done;
        // Signal to the screen to open the creation flow in edit mode
        emit([...state,
          const ChatMessage(
            text: "Opening job card editor...",
            isUser: false, step: 2)]);
        break;
      case "Delete Job Card":
        _startDelete();
        break;
    }
  }

  // ── Status update ─────────────────────────────────────────────────────────

  Future<void> _startStatusUpdate() async {
    final current = selectedJobStatus ?? "pending";
    const order = ["pending", "active", "completed", "delivered"];
    final idx = order.indexOf(current.toLowerCase());
    final next = idx >= 0 && idx < order.length - 1 ? order[idx + 1] : null;

    if (next == null) {
      _addBot("This job is already at the final status.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }

    manageStep = ManageStep.confirmStatus;
    emit([
      ...state,
      ChatMessage(
        text: "Current status: $current\nNext status will be: $next\n\nAre you sure you want to update?",
        isUser: false,
        options: const ["Yes, Update", "Cancel"],
        step: 2,
      ),
    ]);
  }

  Future<void> confirmStatusUpdate(bool confirmed) async {
    if (!confirmed) {
      _addUserMsg("Cancel");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }
    _addUserMsg("Yes, Update");
    isBusy = true;
    _addBot("Updating status...");
    try {
      final newStatus = await _service.updateStatus(selectedJobId!);
      isBusy = false;
      selectedJobStatus = newStatus;
      _addBot("✅ Status updated to \"$newStatus\" successfully.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    } catch (e) {
      isBusy = false;
      _addBot("Failed to update status: ${e.toString().replaceAll('Exception: ', '')}");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void _startDelete() {
    manageStep = ManageStep.confirmDelete;
    emit([
      ...state,
      ChatMessage(
        text: "⚠️ Are you sure you want to delete $selectedJobDisplay? This cannot be undone.",
        isUser: false,
        options: const ["Yes, Delete", "Cancel"],
        step: 2,
      ),
    ]);
  }

  Future<void> confirmDelete(bool confirmed) async {
    if (!confirmed) {
      _addUserMsg("Cancel");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }
    _addUserMsg("Yes, Delete");
    isBusy = true;
    _addBot("Deleting job card...");
    try {
      await _service.deleteJobCard(selectedJobId!);
      isBusy = false;
      _addBot("✅ Job card deleted successfully.");
      manageStep = ManageStep.done;
    } catch (e) {
      isBusy = false;
      _addBot("Failed to delete: ${e.toString().replaceAll('Exception: ', '')}");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  // ── Add Labour ────────────────────────────────────────────────────────────

  Future<void> _startAddLabour() async {
    manageStep = ManageStep.addLabourSearch;
    labourSearchResults = [];
    pendingLabourId = null;
    pendingLabourName = null;
    _addBot("Type a labour name to search, or enter a new one:");
  }

  Future<void> handleLabourSearchInput(String query) async {
    if (query.trim().isEmpty) return;

    if (manageStep == ManageStep.addLabourSearch) {
      // Search
      try {
        labourSearchResults = await _service.searchLabour(query.trim());
      } catch (_) {
        labourSearchResults = [];
      }

      if (labourSearchResults.isEmpty) {
        // Use as new labour name directly
        pendingLabourId   = null;
        pendingLabourName = query.trim();
        manageStep = ManageStep.addLabourAmount;
        _addUserMsg(query.trim());
        _addBot('Adding "$pendingLabourName" as new labour. Enter the amount (₹):');
      } else {
        final options = labourSearchResults
            .map((l) => l['name'].toString())
            .toList()
          ..add("➕ Add \"${query.trim()}\" as new");

        emit([
          ...state,
          ChatMessage(
            text: "Select a labour or add new:",
            isUser: false,
            options: options,
            step: 3,
          ),
        ]);
      }
      return;
    }

    if (manageStep == ManageStep.addLabourAmount) {
      final amount = query.trim();
      if (double.tryParse(amount) == null) {
        _addBot("Please enter a valid number for the amount.");
        return;
      }
      _addUserMsg(amount);
      await _submitLabour(amount);
    }
  }

  void selectLabourOption(String option) {
    if (option.startsWith("➕ Add")) {
      // Extract name between quotes
      final name = option.replaceAll(RegExp(r'^➕ Add "'), "").replaceAll('"', "");
      pendingLabourId   = null;
      pendingLabourName = name;
    } else {
      final match = labourSearchResults.firstWhere(
        (l) => l['name'].toString() == option,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        pendingLabourId   = match['id'] as int;
        pendingLabourName = match['name'] as String;
      }
    }
    manageStep = ManageStep.addLabourAmount;
    _addUserMsg(option);
    _addBot("Enter the labour amount (₹):");
  }

  Future<void> _submitLabour(String amount) async {
    isBusy = true;
    _addBot("Adding labour...");
    try {
      final result = await _service.addLabour(
        jobcardId:  selectedJobId!,
        labourId:   pendingLabourId,
        labourName: pendingLabourId == null ? pendingLabourName : null,
        amount:     amount,
      );
      isBusy = false;
      _addBot("✅ Labour \"${result['labour_name']}\" (₹${result['amount']}) added successfully.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    } catch (e) {
      isBusy = false;
      _addBot("Failed to add labour: ${e.toString().replaceAll('Exception: ', '')}");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  // ── Remove Labour ─────────────────────────────────────────────────────────

  Future<void> _startRemoveLabour() async {
    isBusy = true;
    _addBot("Fetching labour list...");
    try {
      final detail = await _service.fetchDetail(selectedJobId!);
      isBusy = false;
      final labours = List<Map<String, dynamic>>.from(
          detail['labour_services'] ?? []);
      if (labours.isEmpty) {
        _addBot("No labour services added to this job card yet.");
        manageStep = ManageStep.showActions;
        _showActionOptions();
        return;
      }
      existingLabours = labours;
      manageStep = ManageStep.removeLabour;
      // Pass labour list through options so the UI can render delete chips
      emit([
        ...state,
        ChatMessage(
          text: "Tap 🗑 to remove a labour service:",
          isUser: false,
          labourList: labours,
          step: 3,
        ),
      ]);
    } catch (e) {
      isBusy = false;
      _addBot("Could not fetch labour list.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  Future<void> removeLabour(int labourServiceId, String labourName) async {
    isBusy = true;
    _addBot("Removing \"$labourName\"...");
    try {
      await _service.removeLabour(
        jobcardId:       selectedJobId!,
        labourServiceId: labourServiceId,
      );
      isBusy = false;
      existingLabours.removeWhere((l) => l['id'] == labourServiceId);
      _addBot("✅ \"$labourName\" removed.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    } catch (e) {
      isBusy = false;
      _addBot("Failed to remove: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void _addBot(String text, {List<String>? options, int step = 0}) {
    emit([
      ...state,
      ChatMessage(
        text: text, isUser: false, options: options, step: step),
    ]);
  }

  void _addUserMsg(String text) {
    emit([...state,
      ChatMessage(text: text, isUser: true, step: 0)]);
  }
}