class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? options;
  final bool showSkip;
  final int? step;
  final bool isSummary;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.options,
    this.showSkip = false,
    this.step,
    this.isSummary = false,
  });
}
