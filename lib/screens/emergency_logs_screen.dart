import 'package:flutter/material.dart';
import '../controllers/emergency_controller.dart';

class EmergencyLogsScreen extends StatelessWidget {
  final String userId;
  final EmergencyController emergencyController;

  const EmergencyLogsScreen({
    super.key,
    required this.userId,
    required this.emergencyController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Emergency Logs"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: emergencyController,
        builder: (context, _) {
          return Column(
            children: [
              if (emergencyController.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    emergencyController.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (emergencyController.isLoading)
                const LinearProgressIndicator(),
              Expanded(
                child: StreamBuilder(
                  stream: emergencyController.getEmergencyLogs(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No emergency logs yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    final logs = snapshot.data.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index].data() as Map<String, dynamic>;

                        final timestamp = log['createdAt'];

                        final contacts = (log['contactsNotified'] ?? 0) as int;

                        final keywords = (log['keywordsFound'] ?? []) as List;

                        return _buildLogCard(
                          timestamp: timestamp,
                          contacts: contacts,
                          keywords: keywords,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogCard({
    required dynamic timestamp,
    required int contacts,
    required List keywords,
  }) {
    String formattedTime = "Unknown time";

    try {
      if (timestamp != null) {
        final date = timestamp.toDate();

        formattedTime =
            "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                "Emergency Triggered",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Time: $formattedTime",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Contacts Notified: $contacts",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords.map<Widget>((k) {
                return Chip(
                  label: Text(k.toString()),
                  backgroundColor: Colors.orange.withOpacity(0.15),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: contacts > 0
                  ? Colors.green.withOpacity(0.14)
                  : Colors.grey.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              contacts > 0 ? "Alert Sent Successfully" : "No Contacts Notified",
              style: TextStyle(
                color: contacts > 0 ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
