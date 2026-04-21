import 'package:digiauto/screens/job_assistant.dart';
import 'package:flutter/material.dart';

class AssistantButton extends StatelessWidget {
  const AssistantButton({
    super.key,
    required this.hasExistingJobs,
    this.onJobCreated,
  });

  final bool hasExistingJobs;
  final VoidCallback? onJobCreated;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => JobAssistantScreen(
              hasExistingJobs: hasExistingJobs,
            ),
          ),
        );

        if (created == true) {
          onJobCreated?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              const Color.fromARGB(255, 46, 81, 119),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_comment_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Digi Assistant",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
