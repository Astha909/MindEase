import 'package:flutter/material.dart';
import '../controllers/emergency_controller.dart';

class EmergencyScreen extends StatefulWidget {
  final String userId;
  final EmergencyController emergencyController;

  const EmergencyScreen({
    super.key,
    required this.userId,
    required this.emergencyController,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();

    /// Prevent empty fields
    if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    await widget.emergencyController.addContact(
      userId: widget.userId,
      name: name,
      phone: phone,
      relation: relation,
    );

    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact Added Successfully"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// dismiss keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Emergency Contacts 🚨"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: _inputDecoration("Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Phone"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _relationController,
                decoration: _inputDecoration("Relation"),
              ),
              const SizedBox(height: 20),

              /// ADD CONTACT BUTTON
              AnimatedBuilder(
                animation: widget.emergencyController,
                builder: (context, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.emergencyController.isLoading
                          ? null
                          : _addContact,
                      child: widget.emergencyController.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Add Contact"),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Saved Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder(
                  stream: widget.emergencyController
                      .getEmergencyContacts(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text("No contacts found."),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("No contacts added yet."),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final contact =
                            docs[index].data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(contact['name'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📞 ${contact['phone']}"),
                                Text("Relation: ${contact['relation']}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation();

                                if (confirm == true) {
                                  await widget.emergencyController
                                      .deleteContact(docs[index].id);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Contact Deleted"),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contact"),
        content: const Text("Are you sure you want to delete this contact?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
