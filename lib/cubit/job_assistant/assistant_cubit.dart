import 'package:digiauto/models/chat.dart';
import 'package:digiauto/services/jobcard_service.dart';
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

  int step = introStep;
  int? editingStep;
  bool _isSubmitting = false;
  bool _created = false;

  final Map<int, String> answers = {};
  final List<String> services = [];

  bool get isCollectingServices => step == serviceStep && editingStep == null;
  bool get isReviewStep =>
      step == reviewStep && editingStep == null && !_isSubmitting;
  bool get canShowInput => step >= vehicleStep && step <= reviewStep;
  bool get isCompleted => _created;
  bool get isSubmitting => _isSubmitting;

  String get inputHint {
    if (_isSubmitting) {
      return "Creating job card...";
    }
    if (editingStep != null) {
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

  void start() {
    step = introStep;
    editingStep = null;
    _isSubmitting = false;
    _created = false;
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
      emit([
        ...state,
        const ChatMessage(
          text: "You can manage existing jobs from the home list.",
          isUser: false,
          step: introStep,
        ),
      ]);
    }
  }

  Future<void> handleInput(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _isSubmitting) return;

    if (editingStep != null) {
      _applyEdit(trimmed);
      return;
    }

    if (isCollectingServices) {
      addService(trimmed, fromUserInput: true);
      return;
    }

    if (isReviewStep) {
      final normalized = trimmed.toLowerCase();
      addUser(trimmed);
      if (normalized == "yes") {
        await submit();
      } else {
        addBot("Type yes to create the job card.");
      }
      return;
    }

    addUser(trimmed);
    answers[step] = trimmed;
    step++;
    askCurrentQuestion();
  }

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
    final trimmed = service.trim();
    if (trimmed.isEmpty || _isSubmitting) return;

    if (services.any((item) => item.toLowerCase() == trimmed.toLowerCase())) {
      addBot("$trimmed is already in the service list.");
      return;
    }

    if (fromUserInput) {
      addUser(trimmed, stepOverride: serviceStep);
    }

    services.add(trimmed);
    emit([
      ...state,
      ChatMessage(
        text: "Added service: $trimmed",
        isUser: false,
        step: serviceStep,
      ),
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
    showSummary();
  }

  void editStep(int targetStep) {
    if (_isSubmitting) return;
    if (targetStep < vehicleStep || targetStep > serviceStep) return;

    editingStep = targetStep;

    if (targetStep == serviceStep) {
      emit([
        ...state,
        const ChatMessage(
          text: "Update the services, then tap Done.",
          isUser: false,
          step: serviceStep,
        ),
      ]);
      return;
    }

    emit([
      ...state,
      ChatMessage(
        text: "Editing ${_fieldLabel(targetStep)}. ${_questionForStep(targetStep)}",
        isUser: false,
        showSkip: targetStep == chassisStep || targetStep == engineStep,
        step: targetStep,
      ),
    ]);
  }

  void removeService(String service) {
    if (_isSubmitting) return;
    services.remove(service);
    emit([
      ...state,
      ChatMessage(
        text: "Removed service: $service",
        isUser: false,
        step: serviceStep,
      ),
    ]);
  }

  void reset() => start();

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
          text: "Job card created successfully.",
          isUser: false,
        ),
      ]);
    } catch (_) {
      _isSubmitting = false;
      emit([
        ...state,
        const ChatMessage(
          text: "Could not create the job card. Please check the API and try again.",
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
        text: "Type yes to create job card, or tap Edit on any answer.",
        isUser: false,
        step: reviewStep,
      ),
    ]);
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

    if (target == serviceStep) {
      addService(value, fromUserInput: true);
      return;
    }

    if (!skipped) {
      addUser(value, stepOverride: target);
    }
    answers[target] = skipped ? '' : value.trim();
    editingStep = null;

    emit([
      ...state,
      ChatMessage(
        text: "${_fieldLabel(target)} updated.",
        isUser: false,
        step: target,
      ),
    ]);

    step = reviewStep;
    showSummary();
  }

  String _questionForStep(int stepValue) {
    switch (stepValue) {
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
        return "Year?";
      case chassisStep:
        return "Chassis number?";
      case engineStep:
        return "Engine number?";
      case kilometerStep:
        return "Kilometer?";
      case serviceStep:
        return "What services do they need? You can add multiple.";
      default:
        return "";
    }
  }

  String _fieldLabel(int stepValue) {
    switch (stepValue) {
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
      "Review job card",
      "",
      "Vehicle No: ${answers[vehicleStep] ?? '-'}",
      "Customer Name: ${answers[customerNameStep] ?? '-'}",
      "Mobile: ${answers[mobileStep] ?? '-'}",
      "Place: ${answers[placeStep] ?? '-'}",
      "Vehicle Model: ${answers[modelStep] ?? '-'}",
      "Vehicle Make: ${answers[makeStep] ?? '-'}",
      "Year: ${answers[yearStep] ?? '-'}",
      "Chassis: ${chassis == null || chassis.isEmpty ? 'Skipped' : chassis}",
      "Engine: ${engine == null || engine.isEmpty ? 'Skipped' : engine}",
      "Kilometer: ${answers[kilometerStep] ?? '-'}",
      "Services: ${services.isEmpty ? '-' : services.join(', ')}",
    ].join("\n");
  }
}
