import 'package:flutter/material.dart';
import '../controllers/profile_controller.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileController profileController;

  const ProfileScreen({
    super.key,
    required this.profileController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.profileController;
    _controller.fetchProfile();
  }

  Future<void> _logout() async {
    await _controller.logout();

    if (!mounted) return;

    if (_controller.errorMessage == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    await _controller.deleteAccount();

    if (!mounted) return;

    if (_controller.errorMessage == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading = _controller.isLoading;
        final errorMessage = _controller.errorMessage;
        final profile = _controller.userProfile;

        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),
          body: SafeArea(
            child: Stack(
              children: [
                if (profile == null && !isLoading)
                  Center(
                    child: Text(
                      errorMessage ?? "No profile data",
                      style: TextStyle(
                        color:
                            errorMessage == null ? Colors.black54 : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (profile != null)
                  Column(
                    children: [
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
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF5D9CEC),
                              ),
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _modernInfoCard(
                                "Age",
                                profile['age']?.toString() ?? "",
                              ),
                              _modernInfoCard(
                                "Gender",
                                profile['gender'] ?? "",
                              ),
                              if (profile['sexuality'] != null &&
                                  profile['sexuality']
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                _modernInfoCard(
                                  "Sexuality",
                                  profile['sexuality'],
                                ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5D9CEC),
                                    disabledBackgroundColor:
                                        const Color(0xFF5D9CEC)
                                            .withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => _showEditDialog(profile),
                                  child: const Text(
                                    "Edit Profile",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: isLoading ? null : _logout,
                                  child: const Text("Logout"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed:
                                    isLoading ? null : _showDeleteConfirm,
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
                if (isLoading)
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Please wait...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> profile) {
    final nameController = TextEditingController(
      text: profile['name'] ?? "",
    );
    final ageController = TextEditingController(
      text: profile['age']?.toString() ?? "",
    );
    final genderController = TextEditingController(
      text: profile['gender'] ?? "",
    );
    final sexualityController = TextEditingController(
      text: profile['sexuality'] ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (bottomSheetContext) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final isLoading = _controller.isLoading;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 30,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _inputField(nameController, "Name", enabled: !isLoading),
                    _inputField(
                      ageController,
                      "Age",
                      number: true,
                      enabled: !isLoading,
                    ),
                    _inputField(
                      genderController,
                      "Gender",
                      enabled: !isLoading,
                    ),
                    _inputField(
                      sexualityController,
                      "Sexuality",
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await _controller.updateProfile(
                                  name: nameController.text.trim(),
                                  age: int.tryParse(
                                        ageController.text.trim(),
                                      ) ??
                                      0,
                                  gender: genderController.text.trim(),
                                  sexuality: sexualityController.text.trim(),
                                );

                                if (!mounted) return;

                                if (_controller.errorMessage == null) {
                                  Navigator.pop(bottomSheetContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Profile updated successfully",
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _controller.errorMessage!,
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Save Changes"),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      ageController.dispose();
      genderController.dispose();
      sexualityController.dispose();
    });
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAccount();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
