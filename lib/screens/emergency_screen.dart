import 'package:flutter/material.dart';
import '../controllers/emergency_controller.dart';
import 'emergency_logs_screen.dart';

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

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  List<Color> getEmergencyGradient() {
    return [
      const Color(0xFF870000),
      const Color(0xFF190A05),
      const Color(0xFFFF512F),
    ];
  }

  Future<void> _addContact() async {
    FocusScope.of(context).unfocus();

    await widget.emergencyController.addContact(
      userId: widget.userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relation: _relationController.text.trim(),
    );

    if (!mounted) return;

    final error = widget.emergencyController.errorMessage;

    if (error == null) {
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact added successfully"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    }
  }

  Future<void> _deleteContact(String contactId) async {
    final confirm = await _showDeleteConfirmation();

    if (confirm != true) return;

    await widget.emergencyController.deleteContact(
      contactId,
      widget.userId,
    );

    if (!mounted) return;

    final error = widget.emergencyController.errorMessage;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact deleted successfully"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    }
  }

  Widget _emptyContactsState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
              child: const Icon(
                Icons.contact_emergency_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No contacts added yet.",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Add someone trusted for emergencies.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactsErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
          ),
        ),
        child: Text(
          "Unable to load contacts right now.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.12),
          centerTitle: true,
          title: const Text(
            "Emergency Contacts 🚨",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    -1 + (_bgController.value * 2),
                    -1,
                  ),
                  end: Alignment(
                    1,
                    1 - (_bgController.value * 2),
                  ),
                  colors: getEmergencyGradient(),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -60,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.30),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orangeAccent.withOpacity(0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: AnimatedBuilder(
                      animation: widget.emergencyController,
                      builder: (context, _) {
                        final isLoading = widget.emergencyController.isLoading;
                        final errorMessage =
                            widget.emergencyController.errorMessage;

                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _nameController,
                                      enabled: !isLoading,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration("Name"),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _phoneController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration("Phone"),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _relationController,
                                      enabled: !isLoading,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration("Relation"),
                                    ),
                                    if (errorMessage != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.16),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.18),
                                          ),
                                        ),
                                        child: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed:
                                            isLoading ? null : _addContact,
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.white.withOpacity(0.45),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.red,
                                                ),
                                              )
                                            : const Text(
                                                "Add Contact",
                                                style: TextStyle(
                                                  color: Color(0xFF870000),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Saved Contacts",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.history,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "View Emergency Logs",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.35),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmergencyLogsScreen(
                                          userId: widget.userId,
                                          emergencyController:
                                              widget.emergencyController,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: StreamBuilder(
                                  stream: widget.emergencyController
                                      .getEmergencyContacts(widget.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _contactsErrorState();
                                    }

                                    final docs = snapshot.data?.docs ?? [];

                                    if (docs.isEmpty) {
                                      return _emptyContactsState();
                                    }

                                    return ListView.builder(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final contact = docs[index].data()
                                            as Map<String, dynamic>;

                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.16),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.22,
                                              ),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.12),
                                                blurRadius: 16,
                                                offset: const Offset(0, 7),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.white.withOpacity(
                                                0.20,
                                              ),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              contact['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "📞 ${contact['phone'] ?? ''}",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.82),
                                                    ),
                                                  ),
                                                  Text(
                                                    "Relation: ${contact['relation'] ?? ''}",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.82),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.delete_rounded,
                                                color: Colors.white,
                                              ),
                                              onPressed: isLoading
                                                  ? null
                                                  : () => _deleteContact(
                                                        docs[index].id,
                                                      ),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text("Delete Contact"),
        content: const Text(
          "Are you sure you want to delete this contact?",
        ),
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
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.65),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.55),
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
