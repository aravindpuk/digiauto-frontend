import 'dart:async';

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
  Timer? _labourSearchDebounce;
  List<Map<String, dynamic>> _labourSuggestions = [];
  Timer? _spareSearchDebounce;
  List<Map<String, dynamic>> _spareSuggestions = [];
  bool _allowPop = false;

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
    _labourSearchDebounce?.cancel();
    _spareSearchDebounce?.cancel();
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
    setState(() {
      _labourSuggestions = [];
      _spareSuggestions = [];
    });
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

  void _closeWithResult(bool changed) {
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(changed);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return PopScope(
            canPop: _allowPop,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _closeWithResult(_cubit.hasChanges);
              }
            },
            child: Scaffold(
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
                  color: Color(0xFFEAF5FB),
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
                              if (mounted) _closeWithResult(true);
                            });
                          }
                          // manage done — pop
                          if (c.isManaging &&
                              c.manageCubit?.manageStep == ManageStep.done &&
                              Navigator.of(ctx).canPop()) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _closeWithResult(c.hasChanges);
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
            ),
          );
        },
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _headerCard(ThemeData theme) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD9E8EF)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                "Jobcard creation and workshop actions",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
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
    if (!isUser && msg.text.startsWith("Managing ")) {
      return _jobContextCard(context, msg.text.replaceFirst("Managing ", ""));
    }
    final bubbleColor = msg.isSummary
        ? const Color(0xFF123247)
        : isUser
        ? theme.primaryColor
        : Colors.white;
    final textColor = isUser || msg.isSummary ? Colors.white : Colors.black87;

    final msgStep = msg.step ?? 0;
    final showEdit =
        isUser &&
        msgStep >= JobAssistantCubit.vehicleStep &&
        msgStep <= JobAssistantCubit.serviceStep &&
        cubit.step > msgStep &&
        cubit.editingStep == null &&
        !cubit.isSubmitting &&
        !cubit.isManaging;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: EdgeInsets.only(
                left: isUser ? 54 : 0,
                right: isUser ? 0 : 54,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 3),
                  bottomRight: Radius.circular(isUser ? 3 : 12),
                ),
                border: isUser || msg.isSummary
                    ? null
                    : Border.all(color: const Color(0xFFE2EEF3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  height: 1.36,
                  fontSize: msg.isSummary ? 13.2 : 14,
                  color: textColor,
                  fontWeight: msg.isSummary ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),

            if (showEdit)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => cubit.editStep(msgStep),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text("Edit"),
              ),

            if (msg.options?.isNotEmpty ?? false)
              _optionContent(context, msg, cubit),

            if (msg.labourList?.isNotEmpty ?? false)
              _labourRemoveList(context, msg.labourList!, cubit),

            if (msg.spareList?.isNotEmpty ?? false)
              _spareRemoveList(context, msg.spareList!, cubit),

            if (msg.showSkip)
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: cubit.skip,
                child: const Text("Skip this field"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _jobContextCard(BuildContext context, String display) {
    final theme = Theme.of(context);
    final parts = display.split(" • ");
    final jobId = parts.isNotEmpty ? parts.first : display;
    final vehicle = parts.length > 1 ? parts[1] : "";
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_outlined, color: theme.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (vehicle.isNotEmpty)
                  Text(
                    vehicle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "Selected",
              style: TextStyle(
                color: Color(0xFF187348),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionContent(
    BuildContext context,
    ChatMessage msg,
    JobAssistantCubit cubit,
  ) {
    final options = msg.options ?? const <String>[];
    switch (msg.optionStyle) {
      case "introActions":
        return _introActionCards(context, options, cubit);
      case "jobCards":
        return _jobCardOptions(context, options, cubit);
      case "manageActions":
        return _manageActionGrid(context, options, cubit);
      default:
        return _optionChips(context, options, cubit);
    }
  }

  void _handleOptionTap(JobAssistantCubit cubit, String option) {
    if (cubit.isManaging) {
      cubit.handleManageOption(option);
    } else {
      cubit.selectOption(option);
    }
    _scrollToBottom();
  }

  Widget _introActionCards(
    BuildContext context,
    List<String> options,
    JobAssistantCubit cubit,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.86,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          children: options.map((option) {
            final isCreate = option == "Create New Jobcard";
            return _largeActionTile(
              context: context,
              title: isCreate ? "Create Jobcard" : "Manage Jobs",
              subtitle: isCreate
                  ? "Start a guided service entry"
                  : "Open active jobs and actions",
              icon: isCreate
                  ? Icons.add_circle_outline
                  : Icons.fact_check_outlined,
              onTap: () => _handleOptionTap(cubit, option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _largeActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCEAF0)),
            ),
            child: Row(
              children: [
                Icon(icon, color: theme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobCardOptions(
    BuildContext context,
    List<String> options,
    JobAssistantCubit cubit,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.86,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          children: options.map((option) {
            final parsed = _parseJobOption(option);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleOptionTap(cubit, option),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDCEAF0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F4FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_outlined,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parsed.$1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parsed.$2,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(parsed.$3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  (String, String, String) _parseJobOption(String option) {
    final parts = option.split(" • ");
    final jobId = parts.isNotEmpty ? parts.first : option;
    final rest = parts.length > 1 ? parts[1] : "";
    final match = RegExp(r'^(.*)\s+\((.*)\)$').firstMatch(rest);
    if (match == null) return (jobId, rest, "");
    return (jobId, match.group(1) ?? rest, match.group(2) ?? "");
  }

  Widget _statusBadge(String status) {
    final label = status.isEmpty ? "open" : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2B6D43),
        ),
      ),
    );
  }

  Widget _manageActionGrid(
    BuildContext context,
    List<String> options,
    JobAssistantCubit cubit,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.86,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.9,
          children: options.map((option) {
            final danger = option == "Delete Job Card";
            return Material(
              color: danger ? const Color(0xFFFFF1F1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _handleOptionTap(cubit, option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: danger
                          ? const Color(0xFFFFD1D1)
                          : const Color(0xFFDCEAF0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _actionIcon(option),
                        size: 19,
                        color: danger
                            ? Colors.red.shade700
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: danger
                                ? Colors.red.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _actionIcon(String option) {
    switch (option) {
      case "Update Status":
        return Icons.trending_up_rounded;
      case "Add Labour":
        return Icons.engineering_outlined;
      case "Remove Labour":
        return Icons.person_remove_outlined;
      case "Add Spare":
        return Icons.add_box_outlined;
      case "Remove Spare":
        return Icons.inventory_2_outlined;
      case "Edit Job Card":
        return Icons.edit_note_outlined;
      case "Delete Job Card":
        return Icons.delete_outline;
      default:
        return Icons.touch_app_outlined;
    }
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
                ).primaryColor.withValues(alpha: 0.08),
                onPressed: () {
                  _handleOptionTap(cubit, o);
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
                color: Colors.black.withValues(alpha: 0.04),
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

  Widget _spareRemoveList(
    BuildContext context,
    List<Map<String, dynamic>> spares,
    JobAssistantCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spares.map((s) {
        final name = (s['part_name'] ?? s['name'] ?? '').toString();
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "Qty ${s['quantity'] ?? '-'} • ₹${s['amount'] ?? '-'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Remove",
                onPressed: () =>
                    _confirmRemoveSpare(context, cubit, s['id'] as int, name),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmRemoveSpare(
    BuildContext context,
    JobAssistantCubit cubit,
    int id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Spare"),
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
              cubit.manageCubit?.removeSpare(id, name);
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_labourSuggestions.isNotEmpty && _isLabourSearch(cubit))
              _labourSuggestionPanel(cubit),
            if (_spareSuggestions.isNotEmpty && _isSpareSearch(cubit))
              _spareSuggestionPanel(cubit),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: !cubit.isSubmitting,
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    textInputAction: TextInputAction.send,
                    onChanged: (value) => _onInputChanged(cubit, value),
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
                    voiceService.isListening
                        ? Icons.mic
                        : Icons.mic_none_rounded,
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
          ],
        ),
      ),
    );
  }

  bool _isLabourSearch(JobAssistantCubit cubit) {
    return cubit.isManaging &&
        cubit.manageCubit?.manageStep == ManageStep.addLabourSearch;
  }

  bool _isSpareSearch(JobAssistantCubit cubit) {
    return cubit.isManaging &&
        cubit.manageCubit?.manageStep == ManageStep.addSpareSearch;
  }

  void _onInputChanged(JobAssistantCubit cubit, String value) {
    if (!_isLabourSearch(cubit) && !_isSpareSearch(cubit)) {
      if (_labourSuggestions.isNotEmpty) {
        setState(() => _labourSuggestions = []);
      }
      if (_spareSuggestions.isNotEmpty) {
        setState(() => _spareSuggestions = []);
      }
      return;
    }

    if (_isLabourSearch(cubit)) {
      _previewLabourSuggestions(cubit, value);
      return;
    }
    _previewSpareSuggestions(cubit, value);
  }

  void _previewLabourSuggestions(JobAssistantCubit cubit, String value) {
    _labourSearchDebounce?.cancel();
    _labourSearchDebounce = Timer(const Duration(milliseconds: 280), () async {
      final query = value.trim();
      if (query.length < 2) {
        if (mounted) setState(() => _labourSuggestions = []);
        return;
      }
      try {
        final results =
            await cubit.manageCubit?.previewLabourSearch(query) ?? [];
        if (!mounted || _ctrl.text.trim() != query) return;
        setState(() => _labourSuggestions = results.take(5).toList());
      } catch (_) {
        if (mounted) setState(() => _labourSuggestions = []);
      }
    });
  }

  void _previewSpareSuggestions(JobAssistantCubit cubit, String value) {
    _spareSearchDebounce?.cancel();
    _spareSearchDebounce = Timer(const Duration(milliseconds: 280), () async {
      final query = value.trim();
      if (query.length < 2) {
        if (mounted) setState(() => _spareSuggestions = []);
        return;
      }
      try {
        final results =
            await cubit.manageCubit?.previewSpareSearch(query) ?? [];
        if (!mounted || _ctrl.text.trim() != query) return;
        setState(() => _spareSuggestions = results.take(5).toList());
      } catch (_) {
        if (mounted) setState(() => _spareSuggestions = []);
      }
    });
  }

  Widget _labourSuggestionPanel(JobAssistantCubit cubit) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8ED)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _labourSuggestions.map((labour) {
          final name = labour['name']?.toString() ?? '';
          final price = labour['suggested_price']?.toString();
          return ListTile(
            dense: true,
            leading: const Icon(Icons.engineering_outlined),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(price == null ? "No price" : "Rs $price"),
            onTap: () {
              _labourSearchDebounce?.cancel();
              _ctrl.clear();
              setState(() => _labourSuggestions = []);
              cubit.manageCubit?.selectLabourFromResults(name);
              _scrollToBottom();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _spareSuggestionPanel(JobAssistantCubit cubit) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8ED)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _spareSuggestions.map((spare) {
          final name = (spare['partname'] ?? spare['name'] ?? '').toString();
          final partNumber = spare['partnumber']?.toString() ?? '';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.build_circle_outlined),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: partNumber.isEmpty ? null : Text(partNumber),
            onTap: () {
              _spareSearchDebounce?.cancel();
              _ctrl.clear();
              setState(() => _spareSuggestions = []);
              cubit.manageCubit?.selectSpareFromResults(name);
              _scrollToBottom();
            },
          );
        }).toList(),
      ),
    );
  }
}
