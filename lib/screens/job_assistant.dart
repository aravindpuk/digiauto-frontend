import 'package:digiauto/cubit/job_assistant/assistant_cubit.dart';
import 'package:digiauto/models/chat.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:digiauto/services/speech_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobAssistantScreen extends StatefulWidget {
  const JobAssistantScreen({
    super.key,
    required this.hasExistingJobs,
  });

  final bool hasExistingJobs;

  @override
  State<JobAssistantScreen> createState() => _JobAssistantScreenState();
}

class _JobAssistantScreenState extends State<JobAssistantScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final VoiceService voiceService = VoiceService();
  final ScrollController _scrollController = ScrollController();
  late final JobAssistantCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = JobAssistantCubit(
      service: JobcardService(),
      hasExistingJobs: widget.hasExistingJobs,
    )..start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _send(JobAssistantCubit cubit) {
    if (_ctrl.text.trim().isEmpty) return;
    cubit.handleInput(_ctrl.text);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _addService(JobAssistantCubit cubit) {
    if (_ctrl.text.trim().isEmpty) return;
    cubit.addService(_ctrl.text, fromUserInput: true);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void onMic() async {
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      await voiceService.init();
      await voiceService.startListening((text) {
        setState(() {
          _ctrl.text += " $text";
        });
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text("Digi Assistant"),
              actions: [
                IconButton(
                  tooltip: "Restart",
                  onPressed: () => context.read<JobAssistantCubit>().reset(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEAF5FB), Color(0xFFF8F9FA)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.primaryColor.withOpacity(0.12),
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Digi Assistant",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Create a new jobcard by chat, or jump into job management from the assistant.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocConsumer<JobAssistantCubit, List<ChatMessage>>(
                      listener: (context, _) {
                        _scrollToBottom();
                        if (context.read<JobAssistantCubit>().isCompleted &&
                            Navigator.of(context).canPop()) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.of(context).pop(true);
                            }
                          });
                        }
                      },
                      builder: (context, messages) {
                        final cubit = context.read<JobAssistantCubit>();
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  12,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (_, i) => _messageTile(
                                  context,
                                  messages[i],
                                  cubit,
                                ),
                              ),
                            ),
                            if (cubit.isCollectingServices &&
                                cubit.services.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...cubit.services.map(
                                        (service) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: InputChip(
                                            label: Text(service),
                                            onDeleted: () {
                                              cubit.removeService(service);
                                              _scrollToBottom();
                                            },
                                          ),
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: cubit.finishServices,
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text("Done"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (cubit.canShowInput) _inputArea(context, cubit),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _messageTile(
    BuildContext context,
    ChatMessage msg,
    JobAssistantCubit cubit,
  ) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;
    final bubbleColor = msg.isSummary
        ? const Color(0xFF123247)
        : isUser
        ? theme.primaryColor
        : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                height: 1.4,
                color: isUser || msg.isSummary ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (isUser &&
              (msg.step ?? 0) >= 1 &&
              (msg.step ?? 0) <= JobAssistantCubit.serviceStep &&
              cubit.step >= JobAssistantCubit.reviewStep)
            TextButton.icon(
              onPressed: () => cubit.editStep(msg.step ?? 1),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("Edit"),
            ),
          if (msg.options?.isNotEmpty ?? false)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.options!
                  .map(
                    (option) => ActionChip(
                      label: Text(option),
                      onPressed: () {
                        cubit.selectOption(option);
                        _scrollToBottom();
                      },
                    ),
                  )
                  .toList(),
            ),
          if (msg.showSkip)
            TextButton(
              onPressed: cubit.skip,
              child: const Text("Skip this field"),
            ),
        ],
      ),
    );
  }

  Widget _inputArea(BuildContext context, JobAssistantCubit cubit) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !cubit.isSubmitting,
                textInputAction: cubit.isCollectingServices
                    ? TextInputAction.done
                    : TextInputAction.send,
                onSubmitted: (_) =>
                    cubit.isCollectingServices ? _addService(cubit) : _send(cubit),
                decoration: InputDecoration(
                  hintText: voiceService.isListening
                      ? "Listening..."
                      : cubit.inputHint,
                  filled: true,
                  fillColor: const Color(0xFFF4F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                voiceService.isListening ? Icons.mic : Icons.mic_none_rounded,
                color: voiceService.isListening ? Colors.red : Colors.grey,
              ),
              onPressed: onMic,
            ),
            if (cubit.isCollectingServices)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: () => _addService(cubit),
                  child: const Text("Add"),
                ),
              ),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () =>
                    cubit.isCollectingServices ? _addService(cubit) : _send(cubit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
