class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? options;
  final String? optionStyle;
  final bool showSkip;
  final int? step;
  final bool isSummary;
  // Used by manage-jobs remove-labour step
  final List<Map<String, dynamic>>? labourList;
  final List<Map<String, dynamic>>? spareList;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.options,
    this.optionStyle,
    this.showSkip = false,
    this.step,
    this.isSummary = false,
    this.labourList,
    this.spareList,
  });
}
