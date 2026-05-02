import 'package:digiauto/models/chat.dart';
import 'package:digiauto/services/manage_job_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ManageStep {
  loadingList,
  showList,
  showActions,
  confirmStatus,
  confirmDelete,
  addLabourSelectComplaint,
  addLabourSearch, // user typing to search
  addLabourSelectFromResults, // results shown, waiting for chip tap
  addLabourConfirmPrice, // existing labour selected — show price, ask confirm or edit
  addLabourEnterPrice, // user typing a custom/edited price
  removeLabour,
  done,
  error,
}

class ManageJobCubit extends Cubit<List<ChatMessage>> {
  ManageJobCubit({required ManageJobService service})
    : _service = service,
      super([]);

  final ManageJobService _service;

  ManageStep manageStep = ManageStep.loadingList;
  bool isBusy = false;
  bool hasChanges = false;

  // selected job
  int? selectedJobId;
  String? selectedJobDisplay;
  String? selectedJobStatus;
  int? selectedVehicleModelId;
  int? selectedGarageId;

  // complaints on the jobcard
  List<Map<String, dynamic>> jobComplaints = [];
  int? selectedComplaintId;
  String? selectedComplaintText;

  // labour add sub-flow
  List<Map<String, dynamic>> labourSearchResults = [];
  int? pendingLabourId;
  String? pendingLabourName;
  String? pendingLabourSuggestedPrice; // from DB
  bool pendingLabourIsNew = false;

  // labour remove
  List<Map<String, dynamic>> existingLabours = [];

  bool get showInput =>
      manageStep == ManageStep.addLabourSearch ||
      manageStep == ManageStep.addLabourEnterPrice;

  String get inputHint {
    if (manageStep == ManageStep.addLabourSearch) {
      return "Search or type labour name...";
    }
    if (manageStep == ManageStep.addLabourEnterPrice) return "Enter amount (₹)";
    return "";
  }

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    _bot("Fetching your job cards...");
    isBusy = true;
    try {
      final jobs = await _service.fetchManageList();
      isBusy = false;
      if (jobs.isEmpty) {
        _bot("No active job cards found.");
        manageStep = ManageStep.done;
        return;
      }
      manageStep = ManageStep.showList;
      emit([
        ...state,
        ChatMessage(
          text: "Select a job card to manage:",
          isUser: false,
          options: jobs
              .map(
                (j) =>
                    "${j['job_id']} • ${j['vehicle_number']} (${j['status']})",
              )
              .toList(),
          step: 10,
        ),
      ]);
    } catch (e) {
      isBusy = false;
      manageStep = ManageStep.error;
      _bot("Could not load jobs. Please try again.");
    }
  }

  // ── Job selected ───────────────────────────────────────────────────────────

  Future<void> selectJob(String display) async {
    _user(display);
    isBusy = true;
    _bot("Loading job details...");
    try {
      final jobs = await _service.fetchManageList();
      final match = jobs.firstWhere(
        (j) => display.startsWith(j['job_id'].toString()),
        orElse: () => {},
      );
      if (match.isEmpty) {
        isBusy = false;
        _bot("Could not find that job. Please try again.");
        return;
      }

      selectedJobId = match['id'] as int;
      selectedJobDisplay = "${match['job_id']} • ${match['vehicle_number']}";
      selectedJobStatus = match['status'] as String;

      // Fetch detail to get complaints and vehicle model
      final detail = await _service.fetchDetail(selectedJobId!);
      isBusy = false;

      jobComplaints = List<Map<String, dynamic>>.from(
        detail['services'] ?? detail['complaints_list'] ?? [],
      );
      selectedGarageId = detail['garage_id'] as int?;
      selectedVehicleModelId = detail['vehicle_model_id'] as int?;

      manageStep = ManageStep.showActions;
      _showActionOptions();
    } catch (e) {
      isBusy = false;
      _bot("Something went wrong. Please try again.");
    }
  }

  void _showActionOptions() {
    final st = (selectedJobStatus ?? "pending").toLowerCase();
    emit([
      ...state,
      ChatMessage(
        text: "What would you like to do with $selectedJobDisplay?",
        isUser: false,
        step: 11,
        options: [
          if (st != "delivered") "Update Status",
          "Add Labour",
          "Remove Labour",
          "Edit Job Card",
          "Delete Job Card",
        ],
      ),
    ]);
  }

  // ── Action selected ────────────────────────────────────────────────────────

  Future<void> selectAction(String action) async {
    _user(action);
    switch (action) {
      case "Update Status":
        await _startStatusUpdate();
        break;
      case "Add Labour":
        _startAddLabour();
        break;
      case "Remove Labour":
        await _startRemoveLabour();
        break;
      case "Edit Job Card":
        manageStep = ManageStep.done;
        break;
      case "Delete Job Card":
        _startDelete();
        break;
    }
  }

  // ── Status update ──────────────────────────────────────────────────────────

  Future<void> _startStatusUpdate() async {
    const order = ["pending", "active", "completed", "delivered"];
    final idx = order.indexOf((selectedJobStatus ?? "pending").toLowerCase());
    final next = (idx >= 0 && idx < order.length - 1) ? order[idx + 1] : null;
    if (next == null) {
      _bot("This job is already at the final status.");
      _showActionOptions();
      return;
    }
    manageStep = ManageStep.confirmStatus;
    emit([
      ...state,
      ChatMessage(
        text:
            "Current status: ${selectedJobStatus ?? 'pending'}\nNext status: $next\n\nAre you sure?",
        isUser: false,
        options: const ["Yes, Update", "Cancel"],
        step: 12,
      ),
    ]);
  }

  Future<void> confirmStatusUpdate(bool confirmed) async {
    if (!confirmed) {
      _user("Cancel");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }
    _user("Yes, Update");
    isBusy = true;
    _bot("Updating status...");
    try {
      final newStatus = await _service.updateStatus(selectedJobId!);
      isBusy = false;
      selectedJobStatus = newStatus;
      hasChanges = true;
      _bot('✅ Status updated to "$newStatus" successfully.');
    } catch (e) {
      isBusy = false;
      _bot("Failed to update status: ${_clean(e)}");
    }
    manageStep = ManageStep.showActions;
    _showActionOptions();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  void _startDelete() {
    manageStep = ManageStep.confirmDelete;
    emit([
      ...state,
      ChatMessage(
        text:
            "⚠️ Are you sure you want to delete $selectedJobDisplay?\nThis cannot be undone.",
        isUser: false,
        options: const ["Yes, Delete", "Cancel"],
        step: 12,
      ),
    ]);
  }

  Future<void> confirmDelete(bool confirmed) async {
    if (!confirmed) {
      _user("Cancel");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }
    _user("Yes, Delete");
    isBusy = true;
    _bot("Deleting job card...");
    try {
      await _service.deleteJobCard(selectedJobId!);
      isBusy = false;
      hasChanges = true;
      _bot("✅ Job card deleted successfully.");
      manageStep = ManageStep.done;
    } catch (e) {
      isBusy = false;
      _bot("Failed to delete: ${_clean(e)}");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  // ── Add Labour — Step 1: select complaint ──────────────────────────────────

  void _startAddLabour() {
    _resetLabourState();

    if (jobComplaints.isEmpty) {
      _bot("No services found on this job card. Please add services first.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
      return;
    }

    manageStep = ManageStep.addLabourSelectComplaint;
    emit([
      ...state,
      ChatMessage(
        text: "Which service is this labour for?",
        isUser: false,
        options: jobComplaints.map((c) => c['text'].toString()).toList(),
        step: 13,
      ),
    ]);
  }

  // Called when user taps a complaint chip
  void selectComplaint(String text) {
    final match = jobComplaints.firstWhere(
      (c) => c['text'].toString() == text,
      orElse: () => {'id': null, 'text': text},
    );
    selectedComplaintId = match['id'] as int?;
    selectedComplaintText = text;
    _user(text);

    manageStep = ManageStep.addLabourSearch;
    _bot('Got it — "$text". Now search for a labour name:');
  }

  // ── Add Labour — Step 2: search ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> previewLabourSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty || manageStep != ManageStep.addLabourSearch) return [];
    labourSearchResults = await _service.searchLabour(
      q,
      garageId: selectedGarageId,
      vehicleModelId: selectedVehicleModelId,
    );
    return labourSearchResults;
  }

  // Called from handleTextInput when step == addLabourSearch
  Future<void> _handleLabourSearch(String query) async {
    _user(query);
    try {
      labourSearchResults = await _service.searchLabour(
        query,
        garageId: selectedGarageId,
        vehicleModelId: selectedVehicleModelId,
      );
    } catch (_) {
      labourSearchResults = [];
    }

    if (labourSearchResults.isEmpty) {
      // Labour doesn't exist — treat typed text as new labour name
      pendingLabourId = null;
      pendingLabourName = query;
      pendingLabourSuggestedPrice = null;
      pendingLabourIsNew = true;
      manageStep = ManageStep.addLabourEnterPrice;
      _bot(
        '"$query" is not in the system yet.\nEnter the amount (₹) to add it:',
      );
    } else {
      // Show results as chips
      manageStep = ManageStep.addLabourSelectFromResults;
      final options =
          labourSearchResults.map((l) => l['name'].toString()).toList()
            ..add('➕ Add "$query" as new');
      emit([
        ...state,
        ChatMessage(
          text: "Select a matching labour:",
          isUser: false,
          options: options,
          step: 14,
        ),
      ]);
    }
  }

  // ── Add Labour — Step 3a: user selects from results ────────────────────────

  void selectLabourFromResults(String option) {
    _user(option);

    if (option.startsWith("➕ Add")) {
      // New labour — extract name
      final name = option
          .replaceFirst(RegExp(r'^➕ Add "'), '')
          .replaceAll(RegExp(r'".*$'), '');
      pendingLabourId = null;
      pendingLabourName = name;
      pendingLabourSuggestedPrice = null;
      pendingLabourIsNew = true;
      manageStep = ManageStep.addLabourEnterPrice;
      _bot('"$name" is not in the system yet.\nEnter the amount (₹):');
      return;
    }

    // Existing labour selected
    final match = labourSearchResults.firstWhere(
      (l) => l['name'].toString() == option,
      orElse: () => {},
    );
    if (match.isEmpty) return;

    pendingLabourId = match['id'] as int;
    pendingLabourName = match['name'] as String;
    pendingLabourSuggestedPrice = match['suggested_price'] as String?;
    pendingLabourIsNew = false;

    // ── Step 3b: show suggested price, let user confirm or edit ───────────
    manageStep = ManageStep.addLabourConfirmPrice;

    if (pendingLabourSuggestedPrice != null) {
      emit([
        ...state,
        ChatMessage(
          text:
              "Labour: $pendingLabourName\nSuggested price: ₹$pendingLabourSuggestedPrice\n\nUse this price or enter a different one?",
          isUser: false,
          options: [
            "Use ₹$pendingLabourSuggestedPrice",
            "Enter Different Price",
          ],
          step: 14,
        ),
      ]);
    } else {
      // No price in DB — go straight to entry
      manageStep = ManageStep.addLabourEnterPrice;
      _bot(
        "$pendingLabourName selected.\nNo default price found. Enter the amount (₹):",
      );
    }
  }

  // Called when user taps "Use ₹XXX" or "Enter Different Price"
  Future<void> handlePriceConfirmOption(String option) async {
    _user(option);
    if (option.startsWith("Use ₹")) {
      // Confirm suggested price directly
      await _submitLabour(pendingLabourSuggestedPrice!);
    } else {
      // Ask user to type a price
      manageStep = ManageStep.addLabourEnterPrice;
      _bot("Enter the amount (₹):");
    }
  }

  // ── Add Labour — Step 4: price typed ──────────────────────────────────────

  Future<void> _handlePriceInput(String input) async {
    if (double.tryParse(input) == null) {
      _bot("Please enter a valid number (e.g. 450 or 350.50).");
      return;
    }
    _user(input);
    await _submitLabour(input);
  }

  // ── Submit labour ─────────────────────────────────────────────────────────

  Future<void> _submitLabour(String amount) async {
    isBusy = true;
    _bot("Adding labour...");
    try {
      final result = await _service.addLabour(
        jobcardId: selectedJobId!,
        labourId: pendingLabourIsNew ? null : pendingLabourId,
        labourName: pendingLabourIsNew ? pendingLabourName : null,
        amount: amount,
        complaintId: selectedComplaintId,
      );
      isBusy = false;
      hasChanges = true;
      _bot(
        '✅ "${result['labour_name']}" (₹${result['amount']}) added'
        ' for "$selectedComplaintText".',
      );
    } catch (e) {
      isBusy = false;
      _bot("Failed to add labour: ${_clean(e)}");
    }
    manageStep = ManageStep.showActions;
    _showActionOptions();
  }

  // ── Remove Labour ─────────────────────────────────────────────────────────

  Future<void> _startRemoveLabour() async {
    isBusy = true;
    _bot("Fetching labour list...");
    try {
      final detail = await _service.fetchDetail(selectedJobId!);
      isBusy = false;
      existingLabours = List<Map<String, dynamic>>.from(
        detail['labour_services'] ?? [],
      );
      if (existingLabours.isEmpty) {
        _bot("No labour services added to this job card yet.");
        manageStep = ManageStep.showActions;
        _showActionOptions();
        return;
      }
      manageStep = ManageStep.removeLabour;
      emit([
        ...state,
        ChatMessage(
          text: "Tap 🗑 to remove a labour service:",
          isUser: false,
          labourList: existingLabours,
          step: 15,
        ),
      ]);
    } catch (e) {
      isBusy = false;
      _bot("Could not fetch labour list.");
      manageStep = ManageStep.showActions;
      _showActionOptions();
    }
  }

  Future<void> removeLabour(int labourServiceId, String labourName) async {
    isBusy = true;
    _bot('Removing "$labourName"...');
    try {
      await _service.removeLabour(
        jobcardId: selectedJobId!,
        labourServiceId: labourServiceId,
      );
      isBusy = false;
      hasChanges = true;
      existingLabours.removeWhere((l) => l['id'] == labourServiceId);
      _bot('✅ "$labourName" removed successfully.');
    } catch (e) {
      isBusy = false;
      _bot("Failed to remove: ${_clean(e)}");
    }
    manageStep = ManageStep.showActions;
    _showActionOptions();
  }

  // ── Main text input dispatcher ─────────────────────────────────────────────

  Future<void> handleTextInput(String input) async {
    final t = input.trim();
    if (t.isEmpty) return;
    switch (manageStep) {
      case ManageStep.addLabourSearch:
        await _handleLabourSearch(t);
        break;
      case ManageStep.addLabourEnterPrice:
        await _handlePriceInput(t);
        break;
      default:
        break;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _resetLabourState() {
    selectedComplaintId = null;
    selectedComplaintText = null;
    pendingLabourId = null;
    pendingLabourName = null;
    pendingLabourSuggestedPrice = null;
    pendingLabourIsNew = false;
    labourSearchResults = [];
  }

  void _bot(String text, {List<String>? options, int step = 0}) {
    emit([
      ...state,
      ChatMessage(text: text, isUser: false, options: options, step: step),
    ]);
  }

  void _user(String text) =>
      emit([...state, ChatMessage(text: text, isUser: true, step: 0)]);

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');
}
