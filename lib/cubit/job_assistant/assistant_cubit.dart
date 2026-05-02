import 'package:digiauto/models/chat.dart';
import 'package:digiauto/models/job_card.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:digiauto/services/manage_job_service.dart';
import 'package:digiauto/cubit/manage_job/manage_job_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobAssistantCubit extends Cubit<List<ChatMessage>> {
  JobAssistantCubit({
    required JobcardService service,
    required bool hasExistingJobs,
  }) : _service = service,
       _hasExistingJobs = hasExistingJobs,
       super([]);

  final JobcardService _service;
  final bool _hasExistingJobs;

  ManageJobCubit? manageCubit;

  static const int introStep = 0;
  static const int vehicleStep = 1;
  static const int customerNameStep = 2;
  static const int mobileStep = 3;
  static const int placeStep = 4;
  static const int modelStep = 5;
  static const int makeStep = 6;
  static const int yearStep = 7;
  static const int chassisStep = 8;
  static const int engineStep = 9;
  static const int kilometerStep = 10;
  static const int serviceStep = 11;
  static const int reviewStep = 12;
  static const int manageMode = 99;

  int step = introStep;
  int? editingStep;
  bool _isSubmitting = false;
  bool _created = false;
  bool _isManaging = false;
  bool _isEditingExisting = false;
  bool _hasManagedChanges = false;
  String? _editingJobId;

  final Map<int, String> answers = {};
  final List<String> services = [];

  bool get isCollectingServices => step == serviceStep && editingStep == null;
  bool get isEditingServices => editingStep == serviceStep;
  bool get isReviewStep =>
      step == reviewStep && editingStep == null && !_isSubmitting;
  bool get isCompleted => _created;
  bool get isSubmitting => _isSubmitting;
  bool get isManaging => _isManaging;
  bool get hasChanges =>
      _created || _hasManagedChanges || (manageCubit?.hasChanges ?? false);

  bool get canShowInput {
    if (_isManaging) return manageCubit?.showInput ?? false;
    return (step >= vehicleStep && step <= reviewStep) || editingStep != null;
  }

  bool get isNumericInput {
    final s = editingStep ?? step;
    return s == mobileStep || s == kilometerStep || s == yearStep;
  }

  String get inputHint {
    if (_isManaging) return manageCubit?.inputHint ?? "";
    if (_isSubmitting) {
      return _isEditingExisting ? "Saving job card..." : "Creating job card...";
    }
    if (editingStep != null) {
      return editingStep == serviceStep
          ? "Add a service"
          : "Update ${_fieldLabel(editingStep!)}";
    }
    switch (step) {
      case vehicleStep:
        return "Vehicle number";
      case customerNameStep:
        return "Customer name";
      case mobileStep:
        return "Mobile number";
      case placeStep:
        return "Place";
      case modelStep:
        return "Vehicle model";
      case makeStep:
        return "Vehicle make";
      case yearStep:
        return "Year";
      case chassisStep:
        return "Chassis number";
      case engineStep:
        return "Engine number";
      case kilometerStep:
        return "Kilometer";
      case serviceStep:
        return "Add a service";
      case reviewStep:
        return _isEditingExisting
            ? "Type yes to save changes"
            : "Type yes to create job card";
      default:
        return "Type here...";
    }
  }

  // ─── Start ─────────────────────────────────────────────────────────────────

  void start() {
    step = introStep;
    editingStep = null;
    _isSubmitting = false;
    _created = false;
    _isManaging = false;
    _isEditingExisting = false;
    _hasManagedChanges = false;
    _editingJobId = null;
    manageCubit = null;
    answers.clear();
    services.clear();

    emit([
      const ChatMessage(
        text: "Hi, I'm Digi Assistant. I'm here to help you with your jobs.",
        isUser: false,
      ),
      ChatMessage(
        text: "What would you like to do?",
        isUser: false,
        options: _hasExistingJobs
            ? const ["Create New Jobcard", "Manage Jobs"]
            : const ["Create New Jobcard"],
        step: introStep,
      ),
    ]);
  }

  // ─── Top-level option ──────────────────────────────────────────────────────

  void selectOption(String value) {
    if (_isEditingExisting) {
      if (value == "Save Changes") {
        submit();
        return;
      }
      final target = _editOptionStep(value);
      if (target != null) {
        editStep(target);
        return;
      }
    }
    if (value == "Create New Jobcard") {
      addUser(value, stepOverride: introStep);
      step = vehicleStep;
      askCurrentQuestion();
      return;
    }
    if (value == "Manage Jobs") {
      addUser(value, stepOverride: introStep);
      _isManaging = true;
      step = manageMode;
      final introMessages = List<ChatMessage>.from(state);
      manageCubit = ManageJobCubit(service: ManageJobService());
      manageCubit!.stream.listen((manageMessages) {
        emit([...introMessages, ...manageMessages]);
      });
      manageCubit!.start();
    }
  }

  // ─── Option chip taps from UI ──────────────────────────────────────────────

  Future<void> handleManageOption(String option) async {
    final mc = manageCubit;
    if (mc == null) return;

    switch (mc.manageStep) {
      case ManageStep.showList:
        await mc.selectJob(option);
        break;

      case ManageStep.showActions:
        if (option == "Edit Job Card") {
          await _startEditJobCard();
          break;
        }
        await mc.selectAction(option);
        break;

      case ManageStep.confirmStatus:
        await mc.confirmStatusUpdate(option.startsWith("Yes"));
        break;

      case ManageStep.confirmDelete:
        await mc.confirmDelete(option.startsWith("Yes"));
        break;

      case ManageStep.addLabourSelectComplaint:
        mc.selectComplaint(option);
        break;

      // Labour search results shown — user picks one
      case ManageStep.addLabourSelectFromResults:
        mc.selectLabourFromResults(option);
        break;

      // "Use ₹XXX" or "Enter Different Price"
      case ManageStep.addLabourConfirmPrice:
        await mc.handlePriceConfirmOption(option);
        break;

      default:
        break;
    }
  }

  // ─── Text input ────────────────────────────────────────────────────────────

  Future<void> handleInput(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _isSubmitting) return;

    if (_isManaging) {
      await manageCubit?.handleTextInput(trimmed);
      return;
    }

    if (editingStep != null && editingStep != serviceStep) {
      final err = _validate(editingStep!, trimmed);
      if (err != null) {
        addBot(err);
        return;
      }
      _applyEdit(trimmed);
      return;
    }
    if (editingStep == serviceStep || isCollectingServices) {
      addService(trimmed, fromUserInput: true);
      return;
    }
    if (isReviewStep) {
      addUser(trimmed);
      if (trimmed.toLowerCase() == "yes") {
        await submit();
      } else {
        addBot("Type yes to create the job card.");
      }
      return;
    }
    final err = _validate(step, trimmed);
    if (err != null) {
      addBot(err);
      return;
    }
    addUser(trimmed);
    answers[step] = trimmed;
    step++;
    askCurrentQuestion();
  }

  Future<void> _startEditJobCard() async {
    final jobId = manageCubit?.selectedJobId;
    if (jobId == null) return;

    addBot("Loading job card for editing...");
    try {
      final job = await _service.fetchJobDetail(jobId.toString());
      _loadJobIntoEditFlow(job);
    } catch (e) {
      addBot("Could not load job card for editing: ${_clean(e)}");
    }
  }

  void _loadJobIntoEditFlow(JobCard job) {
    _isManaging = false;
    _isEditingExisting = true;
    _editingJobId = job.id;
    step = reviewStep;
    editingStep = null;
    answers
      ..clear()
      ..addAll({
        vehicleStep: job.vehicleNumber,
        customerNameStep: job.customerName,
        mobileStep: job.mobile,
        placeStep: job.place,
        modelStep: job.vehicleModel,
        makeStep: job.vehicleMake,
        yearStep: job.year,
        chassisStep: job.chassisNumber,
        engineStep: job.engineNumber,
        kilometerStep: job.kilometer,
      });
    services
      ..clear()
      ..addAll(job.services.map((service) => service.text));
    emit([
      ...state,
      ChatMessage(
        text: _buildSummary(),
        isUser: false,
        isSummary: true,
        step: reviewStep,
      ),
      const ChatMessage(
        text: "Choose a field to edit or save the job card.",
        isUser: false,
        options: [
          "Edit Vehicle No",
          "Edit Customer",
          "Edit Mobile",
          "Edit Place",
          "Edit Model",
          "Edit Make",
          "Edit Year",
          "Edit Chassis",
          "Edit Engine",
          "Edit Kilometer",
          "Edit Services",
          "Save Changes",
        ],
        step: reviewStep,
      ),
    ]);
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  String? _validate(int s, String v) {
    switch (s) {
      case customerNameStep:
        if (RegExp(r'\d').hasMatch(v)) {
          return "Name should not contain numbers.";
        }
        if (v.length < 2) return "Name is too short.";
        return null;
      case mobileStep:
        if (!RegExp(r'^\d+$').hasMatch(v)) {
          return "Mobile should contain digits only.";
        }
        if (v.length < 6) return "Mobile must be at least 6 digits.";
        return null;
      case kilometerStep:
        if (!RegExp(r'^\d+$').hasMatch(v)) return "Kilometer must be a number.";
        return null;
      case yearStep:
        if (!RegExp(r'^\d{4}$').hasMatch(v)) {
          return "Enter a valid 4-digit year.";
        }
        final y = int.tryParse(v) ?? 0;
        final now = DateTime.now().year;
        if (y < 1980 || y > now) return "Year must be between 1980 and $now.";
        return null;
      default:
        return null;
    }
  }

  // ─── Services / skip / edit ────────────────────────────────────────────────

  void skip() {
    if (_isSubmitting) return;
    if (editingStep != null) {
      if (editingStep == chassisStep || editingStep == engineStep) {
        _applyEdit('', skipped: true);
      }
      return;
    }
    if (step != chassisStep && step != engineStep) return;
    answers[step] = "";
    step++;
    askCurrentQuestion();
  }

  void addService(String service, {bool fromUserInput = false}) {
    final t = service.trim();
    if (t.isEmpty || _isSubmitting) return;
    if (services.any((s) => s.toLowerCase() == t.toLowerCase())) {
      addBot('"$t" is already in the list.');
      return;
    }
    if (fromUserInput) addUser(t, stepOverride: serviceStep);
    services.add(t);
    emit([
      ...state,
      ChatMessage(text: "Added: $t", isUser: false, step: serviceStep),
    ]);
  }

  void removeService(String service) {
    if (_isSubmitting) return;
    services.remove(service);
    emit([
      ...state,
      ChatMessage(text: "Removed: $service", isUser: false, step: serviceStep),
    ]);
  }

  void finishServices() {
    if (_isSubmitting) return;
    if (services.isEmpty) {
      addBot("Add at least one service first.");
      return;
    }
    editingStep = null;
    step = reviewStep;
    _refreshSummaryInPlace();
  }

  void editStep(int targetStep) {
    if (_isSubmitting) return;
    if (targetStep < vehicleStep || targetStep > serviceStep) return;
    editingStep = targetStep;
    if (targetStep == serviceStep) {
      emit([
        ...state,
        const ChatMessage(
          text: "Add or remove services, then tap Done.",
          isUser: false,
          step: serviceStep,
        ),
      ]);
      return;
    }
    emit([
      ...state,
      ChatMessage(
        text:
            "Editing ${_fieldLabel(targetStep)}. ${_questionForStep(targetStep)}",
        isUser: false,
        showSkip: targetStep == chassisStep || targetStep == engineStep,
        step: targetStep,
      ),
    ]);
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit([
      ...state,
      ChatMessage(
        text: _isEditingExisting
            ? "Saving job card..."
            : "Creating job card...",
        isUser: false,
        step: reviewStep,
      ),
    ]);
    try {
      if (_isEditingExisting) {
        await _service.updateJobCard(
          jobcardId: _editingJobId!,
          vehicleNumber: answers[vehicleStep] ?? '',
          customerName: answers[customerNameStep] ?? '',
          mobile: answers[mobileStep] ?? '',
          place: answers[placeStep] ?? '',
          vehicleModel: answers[modelStep] ?? '',
          vehicleMake: answers[makeStep] ?? '',
          year: answers[yearStep] ?? '',
          chassisNumber: answers[chassisStep] ?? '',
          engineNumber: answers[engineStep] ?? '',
          kilometer: answers[kilometerStep] ?? '',
          services: List<String>.from(services),
        );
        _hasManagedChanges = true;
      } else {
        await _service.createJobCard(
          vehicleNumber: answers[vehicleStep] ?? '',
          customerName: answers[customerNameStep] ?? '',
          mobile: answers[mobileStep] ?? '',
          place: answers[placeStep] ?? '',
          vehicleModel: answers[modelStep] ?? '',
          vehicleMake: answers[makeStep] ?? '',
          year: answers[yearStep] ?? '',
          chassisNumber: answers[chassisStep] ?? '',
          engineNumber: answers[engineStep] ?? '',
          kilometer: answers[kilometerStep] ?? '',
          services: List<String>.from(services),
        );
      }
      _created = true;
      step = reviewStep + 1;
      emit([
        ...state,
        ChatMessage(
          text: _isEditingExisting
              ? "✅ Job card updated successfully."
              : "✅ Job card created successfully.",
          isUser: false,
        ),
      ]);
    } catch (e) {
      _isSubmitting = false;
      emit([
        ...state,
        ChatMessage(
          text: "Could not save: ${e.toString().replaceAll('Exception: ', '')}",
          isUser: false,
          step: reviewStep,
        ),
      ]);
    }
  }

  // ─── Summary helpers ───────────────────────────────────────────────────────

  void askCurrentQuestion() {
    if (step == reviewStep) {
      showSummary();
      return;
    }
    addBot(
      _questionForStep(step),
      skip: step == chassisStep || step == engineStep,
    );
  }

  void showSummary() {
    emit([
      ...state,
      ChatMessage(
        text: _buildSummary(),
        isUser: false,
        isSummary: true,
        step: reviewStep,
      ),
      _reviewFollowupMessage(),
    ]);
  }

  void _refreshSummaryInPlace() {
    final msgs = List<ChatMessage>.from(state);
    int idx = -1;
    for (int i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].isSummary) {
        idx = i;
        break;
      }
    }
    if (idx != -1) {
      msgs[idx] = ChatMessage(
        text: _buildSummary(),
        isUser: false,
        isSummary: true,
        step: reviewStep,
      );
      if (idx + 1 < msgs.length &&
          msgs[idx + 1].step == reviewStep &&
          !msgs[idx + 1].isUser &&
          !msgs[idx + 1].isSummary) {
        msgs.removeAt(idx + 1);
      }
      msgs.add(_reviewFollowupMessage());
      emit(msgs);
    } else {
      showSummary();
    }
  }

  void addBot(String text, {List<String>? options, bool skip = false}) {
    emit([
      ...state,
      ChatMessage(
        text: text,
        isUser: false,
        options: options,
        showSkip: skip,
        step: step,
      ),
    ]);
  }

  void addUser(String text, {int? stepOverride}) {
    emit([
      ...state,
      ChatMessage(
        text: text,
        isUser: true,
        step: stepOverride ?? editingStep ?? step,
      ),
    ]);
  }

  void _applyEdit(String value, {bool skipped = false}) {
    final target = editingStep;
    if (target == null) return;
    if (!skipped) addUser(value, stepOverride: target);
    answers[target] = skipped ? '' : value.trim();
    editingStep = null;
    step = reviewStep;
    _refreshSummaryInPlace();
  }

  void reset() => start();

  String _reviewPrompt() {
    return _isEditingExisting
        ? "Type yes to save changes, or tap Edit on any answer above."
        : "Type yes to create job card, or tap Edit on any answer above.";
  }

  ChatMessage _reviewFollowupMessage() {
    if (!_isEditingExisting) {
      return ChatMessage(
        text: _reviewPrompt(),
        isUser: false,
        step: reviewStep,
      );
    }
    return const ChatMessage(
      text: "Choose another field to edit or save the job card.",
      isUser: false,
      options: [
        "Edit Vehicle No",
        "Edit Customer",
        "Edit Mobile",
        "Edit Place",
        "Edit Model",
        "Edit Make",
        "Edit Year",
        "Edit Chassis",
        "Edit Engine",
        "Edit Kilometer",
        "Edit Services",
        "Save Changes",
      ],
      step: reviewStep,
    );
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  String _questionForStep(int s) {
    switch (s) {
      case vehicleStep:
        return "What is the vehicle number?";
      case customerNameStep:
        return "Customer name?";
      case mobileStep:
        return "Mobile number?";
      case placeStep:
        return "Place?";
      case modelStep:
        return "Vehicle model?";
      case makeStep:
        return "Vehicle make?";
      case yearStep:
        return "Year of manufacture?";
      case chassisStep:
        return "Chassis number?";
      case engineStep:
        return "Engine number?";
      case kilometerStep:
        return "Current kilometer reading?";
      case serviceStep:
        return "What services do they need? You can add multiple.";
      default:
        return "";
    }
  }

  String _fieldLabel(int s) {
    switch (s) {
      case vehicleStep:
        return "vehicle number";
      case customerNameStep:
        return "customer name";
      case mobileStep:
        return "mobile number";
      case placeStep:
        return "place";
      case modelStep:
        return "vehicle model";
      case makeStep:
        return "vehicle make";
      case yearStep:
        return "year";
      case chassisStep:
        return "chassis number";
      case engineStep:
        return "engine number";
      case kilometerStep:
        return "kilometer";
      case serviceStep:
        return "services";
      default:
        return "value";
    }
  }

  int? _editOptionStep(String option) {
    switch (option) {
      case "Edit Vehicle No":
        return vehicleStep;
      case "Edit Customer":
        return customerNameStep;
      case "Edit Mobile":
        return mobileStep;
      case "Edit Place":
        return placeStep;
      case "Edit Model":
        return modelStep;
      case "Edit Make":
        return makeStep;
      case "Edit Year":
        return yearStep;
      case "Edit Chassis":
        return chassisStep;
      case "Edit Engine":
        return engineStep;
      case "Edit Kilometer":
        return kilometerStep;
      case "Edit Services":
        return serviceStep;
      default:
        return null;
    }
  }

  String _buildSummary() {
    final chassis = answers[chassisStep];
    final engine = answers[engineStep];
    return [
      _isEditingExisting ? "📋 Edit Job Card" : "📋 Review Job Card",
      "",
      "🚗  Vehicle No : ${answers[vehicleStep] ?? '-'}",
      "👤  Customer   : ${answers[customerNameStep] ?? '-'}",
      "📞  Mobile     : ${answers[mobileStep] ?? '-'}",
      "📍  Place      : ${answers[placeStep] ?? '-'}",
      "🏎   Model      : ${answers[modelStep] ?? '-'}",
      "🔧  Make       : ${answers[makeStep] ?? '-'}",
      "📅  Year       : ${answers[yearStep] ?? '-'}",
      "🔩  Chassis    : ${chassis == null || chassis.isEmpty ? 'Skipped' : chassis}",
      "⚙️   Engine     : ${engine == null || engine.isEmpty ? 'Skipped' : engine}",
      "📏  KM         : ${answers[kilometerStep] ?? '-'}",
      "🛠   Services   : ${services.isEmpty ? '-' : services.join(', ')}",
    ].join("\n");
  }
}
