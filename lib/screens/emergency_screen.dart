import 'package:flutter/material.dart';
import '../controllers/emergency_controller.dart';

class EmergencyScreen extends StatefulWidget {
  final EmergencyController emergencyController;

  const EmergencyScreen({super.key, required this.emergencyController});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    final userId = "user-id-placeholder"; // Replace with actual user ID
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();

    if (name.isEmpty || phone.isEmpty || relation.isEmpty) return;

    await widget.emergencyController.addContact(
      userId: userId,
      name: name,
      phone: phone,
      relation: relation,
    );

    if (widget.emergencyController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.emergencyController.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact added successfully")),
      );
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();
    }
  }

  Future<void> _triggerEmergency() async {
    final userId = "user-id-placeholder"; // Replace with actual user ID
    final message = _messageController.text.trim();

    if (message.isEmpty) return;

    final keywordsFound =
        widget.emergencyController.checkEmergencyKeywords(message);

    if (keywordsFound.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency keywords found")),
      );
      return;
    }

    await widget.emergencyController.triggerEmergency(
      userId: userId,
      message: message,
      keywordsFound: keywordsFound,
    );

    if (widget.emergencyController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.emergencyController.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency triggered successfully")),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.emergencyController.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Emergency Contact",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _relationController,
                decoration: const InputDecoration(labelText: "Relation"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isLoading ? null : _addContact,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : const Text("Add Contact"),
              ),
              const Divider(height: 32, thickness: 1),
              const Text("Trigger Emergency",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: "Message",
                  hintText: "Describe your emergency",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isLoading ? null : _triggerEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : const Text("Trigger Emergency"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
