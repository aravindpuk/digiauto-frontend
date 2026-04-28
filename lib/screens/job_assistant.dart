import 'package:digiauto/cubit/job_assistant/assistant_cubit.dart';
import 'package:digiauto/cubit/manage_job/manage_job_cubit.dart';
import 'package:digiauto/models/chat.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:digiauto/services/speech_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobAssistantScreen extends StatefulWidget {
  const JobAssistantScreen({super.key, required this.hasExistingJobs});
  final bool hasExistingJobs;

  @override
  State<JobAssistantScreen> createState() => _JobAssistantScreenState();
}

class _JobAssistantScreenState extends State<JobAssistantScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final VoiceService voiceService = VoiceService();
  final ScrollController _scroll = ScrollController();
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
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_cubit.isCollectingServices || _cubit.isEditingServices) {
      _cubit.addService(text, fromUserInput: true);
    } else {
      _cubit.handleInput(text);
    }
    _ctrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _onMic() async {
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      await voiceService.init();
      await voiceService.startListening(
        (t) => setState(() => _ctrl.text += " $t"),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Scaffold(
            appBar: AppBar(
              title: const Text("Digi Assistant"),
              actions: [
                IconButton(
                  tooltip: "Restart",
                  onPressed: () => ctx.read<JobAssistantCubit>().reset(),
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
                  _headerCard(theme),
                  Expanded(
                    child: BlocConsumer<JobAssistantCubit, List<ChatMessage>>(
                      listener: (ctx, _) {
                        _scrollToBottom();
                        final c = ctx.read<JobAssistantCubit>();
                        if (c.isCompleted && Navigator.of(ctx).canPop()) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) Navigator.of(ctx).pop(true);
                          });
                        }
                        // manage done — pop
                        if (c.isManaging &&
                            c.manageCubit?.manageStep == ManageStep.done &&
                            Navigator.of(ctx).canPop()) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) Navigator.of(ctx).pop(true);
                          });
                        }
                      },
                      builder: (ctx, messages) {
                        final cubit = ctx.read<JobAssistantCubit>();
                        final isServiceMode =
                            cubit.isCollectingServices ||
                            cubit.isEditingServices;

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  12,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (_, i) =>
                                    _messageTile(ctx, messages[i], cubit),
                              ),
                            ),

                            // Service chips
                            if (isServiceMode && cubit.services.isNotEmpty)
                              _serviceChips(cubit),

                            // Input bar — only when relevant
                            if (cubit.canShowInput)
                              _inputArea(ctx, cubit, isServiceMode),
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _headerCard(ThemeData theme) => Container(
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text("Create a new jobcard or manage existing jobs."),
            ],
          ),
        ),
      ],
    ),
  );

  // ─── Message tile ──────────────────────────────────────────────────────────

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

    final msgStep = msg.step ?? 0;
    final showEdit =
        isUser &&
        msgStep >= JobAssistantCubit.vehicleStep &&
        msgStep <= JobAssistantCubit.serviceStep &&
        cubit.step > msgStep &&
        cubit.editingStep == null &&
        !cubit.isSubmitting &&
        !cubit.isManaging;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                height: 1.45,
                color: isUser || msg.isSummary ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Edit button (create flow)
          if (showEdit)
            TextButton.icon(
              onPressed: () => cubit.editStep(msgStep),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text("Edit"),
            ),

          // Option chips
          if (msg.options?.isNotEmpty ?? false)
            _optionChips(context, msg.options!, cubit),

          // Labour list with delete buttons (manage mode)
          if (msg.labourList?.isNotEmpty ?? false)
            _labourRemoveList(context, msg.labourList!, cubit),

          // Skip
          if (msg.showSkip)
            TextButton(
              onPressed: cubit.skip,
              child: const Text("Skip this field"),
            ),
        ],
      ),
    );
  }

  // ─── Option chips ──────────────────────────────────────────────────────────

  Widget _optionChips(
    BuildContext context,
    List<String> options,
    JobAssistantCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (o) => ActionChip(
                label: Text(o),
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.08),
                onPressed: () {
                  if (cubit.isManaging) {
                    cubit.handleManageOption(o);
                  } else {
                    cubit.selectOption(o);
                  }
                  _scrollToBottom();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Labour remove list ────────────────────────────────────────────────────

  Widget _labourRemoveList(
    BuildContext context,
    List<Map<String, dynamic>> labours,
    JobAssistantCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: labours.map((l) {
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['labour_name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "₹${l['amount'] ?? '-'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Remove",
                onPressed: () => _confirmRemoveLabour(
                  context,
                  cubit,
                  l['id'] as int,
                  l['labour_name'].toString(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmRemoveLabour(
    BuildContext context,
    JobAssistantCubit cubit,
    int id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Labour"),
        content: Text('Remove "$name" from this job card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              cubit.manageCubit?.removeLabour(id, name);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Service chips ─────────────────────────────────────────────────────────

  Widget _serviceChips(JobAssistantCubit cubit) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 12),
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
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(s),
                onDeleted: () {
                  cubit.removeService(s);
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
  );

  // ─── Input area ────────────────────────────────────────────────────────────

  Widget _inputArea(
    BuildContext context,
    JobAssistantCubit cubit,
    bool isServiceMode,
  ) {
    final theme = Theme.of(context);
    final keyboardType = isServiceMode
        ? TextInputType.text
        : cubit.isNumericInput
        ? TextInputType.number
        : TextInputType.text;
    final formatters = cubit.isNumericInput
        ? [FilteringTextInputFormatter.digitsOnly]
        : <TextInputFormatter>[];

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
                keyboardType: keyboardType,
                inputFormatters: formatters,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
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
              onPressed: _onMic,
            ),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: IconButton(
                tooltip: isServiceMode ? "Add service" : "Send",
                icon: Icon(
                  isServiceMode ? Icons.add : Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
