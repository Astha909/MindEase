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

  bool _isEditingProfile = false;
  bool _isDeletingAccount = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.profileController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.fetchProfile();
      }
    });
  }

  bool get _isBusy {
    return _controller.isLoading ||
        _isEditingProfile ||
        _isDeletingAccount ||
        _isLoggingOut;
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isBusy) return;

    setState(() {
      _isLoggingOut = true;
    });

    await _controller.logout();

    if (!mounted) return;

    setState(() {
      _isLoggingOut = false;
    });

    if (_controller.errorMessage == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      _showSnack(_controller.errorMessage!);
    }
  }

  Future<void> _deleteAccount() async {
    if (_isBusy) return;

    setState(() {
      _isDeletingAccount = true;
    });

    await _controller.deleteAccount();

    if (!mounted) return;

    setState(() {
      _isDeletingAccount = false;
    });

    if (_controller.errorMessage == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      _showSnack(_controller.errorMessage!);
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> profile) async {
    if (_isBusy) return;

    final nameController = TextEditingController(
      text: profile['name']?.toString() ?? "",
    );
    final ageController = TextEditingController(
      text: profile['age']?.toString() ?? "",
    );
    final genderController = TextEditingController(
      text: profile['gender']?.toString() ?? "",
    );
    final sexualityController = TextEditingController(
      text: profile['sexuality']?.toString() ?? "",
    );

    bool localSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveProfile() async {
              if (localSaving) return;

              final name = nameController.text.trim();
              final ageText = ageController.text.trim();
              final gender = genderController.text.trim();
              final sexuality = sexualityController.text.trim();

              final age = int.tryParse(ageText);

              if (name.isEmpty) {
                _showSnack("Name cannot be empty");
                return;
              }

              if (age == null || age <= 0) {
                _showSnack("Enter a valid age");
                return;
              }

              if (gender.isEmpty) {
                _showSnack("Gender required");
                return;
              }

              setSheetState(() {
                localSaving = true;
              });

              if (mounted) {
                setState(() {
                  _isEditingProfile = true;
                });
              }

              await _controller.updateProfile(
                name: name,
                age: age,
                gender: gender,
                sexuality: sexuality,
              );

              if (!mounted) return;

              if (_controller.errorMessage == null) {
                setState(() {
                  _isEditingProfile = false;
                });

                if (Navigator.canPop(sheetContext)) {
                  Navigator.pop(sheetContext);
                }

                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) {
                    _showSnack("Profile updated successfully");
                  }
                });

                return;
              }

              if (mounted) {
                setState(() {
                  _isEditingProfile = false;
                });
              }

              if (sheetContext.mounted) {
                setSheetState(() {
                  localSaving = false;
                });
              }

              _showSnack(_controller.errorMessage!);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _inputField(
                      controller: nameController,
                      label: "Name",
                      enabled: !localSaving,
                    ),
                    _inputField(
                      controller: ageController,
                      label: "Age",
                      number: true,
                      enabled: !localSaving,
                    ),
                    _inputField(
                      controller: genderController,
                      label: "Gender",
                      enabled: !localSaving,
                    ),
                    _inputField(
                      controller: sexualityController,
                      label: "Sexuality",
                      enabled: !localSaving,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: localSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D9CEC),
                          disabledBackgroundColor:
                              const Color(0xFF5D9CEC).withOpacity(0.45),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: localSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
    genderController.dispose();
    sexualityController.dispose();

    if (mounted) {
      setState(() {
        _isEditingProfile = false;
      });
    }
  }

  void _showDeleteConfirm() {
    if (_isBusy) return;

    showDialog(
      context: context,
      barrierDismissible: !_isDeletingAccount,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure? This cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: _isDeletingAccount
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                    },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _isDeletingAccount
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _deleteAccount();
                    },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    bool number = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingPill(String text) {
    return Positioned(
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _controller.isLoading
                  ? null
                  : () {
                      _controller.fetchProfile();
                    },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileContent(Map<String, dynamic> profile) {
    final name = profile['name']?.toString() ?? "";
    final age = profile['age']?.toString() ?? "";
    final gender = profile['gender']?.toString() ?? "";
    final sexuality = profile['sexuality']?.toString() ?? "";

    return Column(
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
                name.isEmpty ? "User" : name,
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
                _modernInfoCard("Age", age),
                _modernInfoCard("Gender", gender),
                if (sexuality.trim().isNotEmpty)
                  _modernInfoCard("Sexuality", sexuality),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D9CEC),
                      disabledBackgroundColor:
                          const Color(0xFF5D9CEC).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isBusy
                        ? null
                        : () {
                            _showEditDialog(profile);
                          },
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                      ),
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
                    onPressed: _isBusy ? null : _logout,
                    child: Text(
                      _isLoggingOut ? "Logging out..." : "Logout",
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isBusy ? null : _showDeleteConfirm,
                  child: Text(
                    _isDeletingAccount ? "Deleting..." : "Delete Account",
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final profile = _controller.userProfile;
        final errorMessage = _controller.errorMessage;

        final isLoadingProfile = _controller.isLoading && profile == null;

        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),
          body: SafeArea(
            child: Stack(
              children: [
                if (isLoadingProfile)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (profile == null)
                  _errorState(errorMessage ?? "No profile data")
                else
                  _profileContent(profile),
                if (_isLoggingOut)
                  _loadingPill("Logging out...")
                else if (_isDeletingAccount)
                  _loadingPill("Deleting account...")
                else if (_isEditingProfile)
                  _loadingPill("Saving profile..."),
              ],
            ),
          ),
        );
      },
    );
  }
}
