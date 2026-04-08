import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_controller.dart';

class EmergencyLogsScreen extends StatelessWidget {
  final String userId;

  const EmergencyLogsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EmergencyController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Logs"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔴 Error Message
          if (controller.errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(10),
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // ⏳ Loading Indicator
          if (controller.isLoading) const LinearProgressIndicator(),

          // 📋 Logs List
          Expanded(
            child: StreamBuilder(
              stream: controller.getEmergencyLogs(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(
                    child: Text("No emergency logs yet"),
                  );
                }

                final logs = snapshot.data.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data();

                    final timestamp = log['createdAt'];
                    final contacts = log['contactsNotified'] ?? 0;
                    final keywords = log['keywordsFound'] ?? [];

                    return _buildLogCard(
                      context,
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
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context, {
    required dynamic timestamp,
    required int contacts,
    required List keywords,
  }) {
    String formattedTime = "Unknown time";

    if (timestamp != null) {
      final date = timestamp.toDate();
      formattedTime =
          "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 Title
          const Text(
            "🚨 Emergency Triggered",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // ⏰ Time
          Text(
            "Time: $formattedTime",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 6),

          // 📞 Contacts notified
          Text(
            "Contacts Notified: $contacts",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 6),

          // 🔍 Keywords
          if (keywords.isNotEmpty)
            Wrap(
              spacing: 6,
              children: keywords.map<Widget>((k) {
                return Chip(
                  label: Text(k),
                  backgroundColor: Colors.orange.shade100,
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // ✅ Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: contacts > 0
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              contacts > 0 ? "Sent" : "No Contacts Notified",
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
