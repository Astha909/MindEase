import 'package:flutter/material.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.fetchProfile();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _controller.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final profile = _controller.userProfile;

    return Scaffold(
      body: SafeArea(
        child: profile == null
            ? const Center(child: Text("No profile data"))
            : Column(
                children: [
                  /// 🌈 MODERN HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5D9CEC),
                          Color(0xFFA0D995),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              size: 50, color: Color(0xFF5D9CEC)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile['name'] ?? "",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 📋 INFO CARD
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _modernInfoCard("Age", profile['age'].toString()),
                          _modernInfoCard("Gender", profile['gender']),
                          if (profile['sexuality'] != null)
                            _modernInfoCard("Sexuality", profile['sexuality']),

                          const Spacer(),

                          /// ✏ EDIT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D9CEC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _showEditDialog(profile),
                              child: const Text("Edit Profile"),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// 🚪 LOGOUT
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                await _controller.logout();
                                if (mounted) Navigator.pop(context);
                              },
                              child: const Text("Logout"),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// ❌ DELETE
                          TextButton(
                            onPressed: _showDeleteConfirm,
                            child: const Text(
                              "Delete Account",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _modernInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  void _showEditDialog(Map profile) {
    final name = TextEditingController(text: profile['name']);
    final age = TextEditingController(text: profile['age'].toString());
    final gender = TextEditingController(text: profile['gender']);
    final sexuality = TextEditingController(text: profile['sexuality']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField(name, "Name"),
            _inputField(age, "Age", number: true),
            _inputField(gender, "Gender"),
            _inputField(sexuality, "Sexuality"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _controller.updateProfile(
                  name: name.text,
                  age: int.tryParse(age.text) ?? 0,
                  gender: gender.text,
                  sexuality: sexuality.text,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _controller.deleteAccount();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }
}
