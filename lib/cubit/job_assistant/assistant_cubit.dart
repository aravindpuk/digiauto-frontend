import 'package:digiauto/models/chat.dart';
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

  // Manage-jobs sub-cubit — created on demand
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
  // manage-jobs mode uses step = 99
  static const int manageStep = 99;

  int step = introStep;
  int? editingStep;
  bool _isSubmitting = false;
  bool _created = false;
  bool _isManaging = false;

  final Map<int, String> answers = {};
  final List<String> services = [];

  bool get isCollectingServices => step == serviceStep && editingStep == null;
  bool get isEditingServices => editingStep == serviceStep;
  bool get isReviewStep =>
      step == reviewStep && editingStep == null && !_isSubmitting;
  bool get isCompleted => _created;
  bool get isSubmitting => _isSubmitting;
  bool get isManaging => _isManaging;

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
    if (_isSubmitting) return "Creating job card...";
    if (editingStep != null) {
      if (editingStep == serviceStep) return "Add a service";
      return "Update ${_fieldLabel(editingStep!)}";
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
        return "Type yes to create job card";
      default:
        return "Type here...";
    }
  }

  // ─── lifecycle ─────────────────────────────────────────────────────────────

  void start() {
    step = introStep;
    editingStep = null;
    _isSubmitting = false;
    _created = false;
    _isManaging = false;
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

  void selectOption(String value) {
    if (value == "Create New Jobcard") {
      addUser(value, stepOverride: introStep);
      step = vehicleStep;
      askCurrentQuestion();
      return;
    }

    if (value == "Manage Jobs") {
      addUser(value, stepOverride: introStep);
      _isManaging = true;
      step = manageStep;
      manageCubit = ManageJobCubit(service: ManageJobService());
      // Mirror manage cubit messages into this cubit's stream
      manageCubit!.stream.listen((msgs) {
        // Replace manage portion of messages (everything after intro)
        final introMsgs = state
            .where((m) => (m.step ?? 0) <= introStep)
            .toList();
        emit([...introMsgs, ...msgs]);
      });
      manageCubit!.start();
    }
  }

  // ─── input dispatcher ──────────────────────────────────────────────────────

  Future<void> handleInput(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _isSubmitting) return;

    if (_isManaging) {
      await manageCubit?.handleLabourSearchInput(trimmed);
      return;
    }

    if (editingStep != null && editingStep != serviceStep) {
      final error = _validate(editingStep!, trimmed);
      if (error != null) {
        addBot(error);
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
    final error = _validate(step, trimmed);
    if (error != null) {
      addBot(error);
      return;
    }
    addUser(trimmed);
    answers[step] = trimmed;
    step++;
    askCurrentQuestion();
  }

  /// Called from the UI when a chip/option is tapped in manage mode
  Future<void> handleManageOption(String option) async {
    final mc = manageCubit;
    if (mc == null) return;

    if (mc.manageStep == ManageStep.showList) {
      await mc.selectJob(option);
    } else if (mc.manageStep == ManageStep.showActions) {
      await mc.selectAction(option);
    } else if (mc.manageStep == ManageStep.confirmStatus) {
      await mc.confirmStatusUpdate(option.startsWith("Yes"));
    } else if (mc.manageStep == ManageStep.confirmDelete) {
      await mc.confirmDelete(option.startsWith("Yes"));
    } else if (mc.manageStep == ManageStep.addLabourSearch) {
      // Options here are labour search results
      mc.selectLabourOption(option);
    }
  }

  // ─── validation ────────────────────────────────────────────────────────────

  String? _validate(int stepValue, String value) {
    switch (stepValue) {
      case customerNameStep:
        if (RegExp(r'\d').hasMatch(value))
          return "Name should not contain numbers.";
        if (value.length < 2) return "Name is too short.";
        return null;
      case mobileStep:
        if (!RegExp(r'^\d+$').hasMatch(value))
          return "Mobile number should contain digits only.";
        if (value.length < 6) return "Mobile number must be at least 6 digits.";
        return null;
      case kilometerStep:
        if (!RegExp(r'^\d+$').hasMatch(value))
          return "Kilometer must be a number.";
        return null;
      case yearStep:
        if (!RegExp(r'^\d{4}$').hasMatch(value))
          return "Please enter a valid 4-digit year.";
        final y = int.tryParse(value) ?? 0;
        final now = DateTime.now().year;
        if (y < 1980 || y > now) return "Year must be between 1980 and $now.";
        return null;
      default:
        return null;
    }
  }

  // ─── skip / services / edit (same as before) ───────────────────────────────

  void skip() {
    if (_isSubmitting) return;
    if (editingStep != null) {
      if (editingStep == chassisStep || editingStep == engineStep)
        _applyEdit('', skipped: true);
      return;
    }
    if (step != chassisStep && step != engineStep) return;
    answers[step] = "";
    step++;
    askCurrentQuestion();
  }

  void addService(String service, {bool fromUserInput = false}) {
    final trimmed = service.trim();
    if (trimmed.isEmpty || _isSubmitting) return;
    if (services.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      addBot("\"$trimmed\" is already in the list.");
      return;
    }
    if (fromUserInput) addUser(trimmed, stepOverride: serviceStep);
    services.add(trimmed);
    emit([
      ...state,
      ChatMessage(text: "Added: $trimmed", isUser: false, step: serviceStep),
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
      addBot("Add at least one service before continuing.");
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
          text: "Add or remove services below, then tap Done.",
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

  Future<void> submit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    emit([
      ...state,
      const ChatMessage(
        text: "Creating job card...",
        isUser: false,
        step: reviewStep,
      ),
    ]);
    try {
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
      _created = true;
      step = reviewStep + 1;
      emit([
        ...state,
        const ChatMessage(
          text: "✅ Job card created successfully.",
          isUser: false,
        ),
      ]);
    } catch (e) {
      _isSubmitting = false;
      emit([
        ...state,
        ChatMessage(
          text:
              "Could not create the job card: ${e.toString().replaceAll('Exception: ', '')}",
          isUser: false,
          step: reviewStep,
        ),
      ]);
    }
  }

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
      const ChatMessage(
        text: "Type yes to create job card, or tap Edit on any answer above.",
        isUser: false,
        step: reviewStep,
      ),
    ]);
  }

  void _refreshSummaryInPlace() {
    final messages = List<ChatMessage>.from(state);
    final updated = _buildSummary();
    int summaryIdx = -1;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isSummary) {
        summaryIdx = i;
        break;
      }
    }
    if (summaryIdx != -1) {
      messages[summaryIdx] = ChatMessage(
        text: updated,
        isUser: false,
        isSummary: true,
        step: reviewStep,
      );
      if (summaryIdx + 1 < messages.length &&
          messages[summaryIdx + 1].step == reviewStep &&
          !messages[summaryIdx + 1].isUser &&
          !messages[summaryIdx + 1].isSummary) {
        messages.removeAt(summaryIdx + 1);
      }
      messages.add(
        const ChatMessage(
          text: "Type yes to create job card, or tap Edit on any answer above.",
          isUser: false,
          step: reviewStep,
        ),
      );
      emit(messages);
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

  String _buildSummary() {
    final chassis = answers[chassisStep];
    final engine = answers[engineStep];
    return [
      "📋 Review Job Card",
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
