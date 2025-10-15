import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../auth_screens/login_screen.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:appwrite/appwrite.dart' show AppwriteException;
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _email;
  String? _companyName;
  String? _profilePhotoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final appwrite_models.User? user = await AuthService.getUser();

      if (user == null) {
        _forceLogout();
        return;
      }

      setState(() {
        _name = user.name;
        _email = user.email;
        _companyName = user.prefs.data['companyName'] as String? ?? "No company added";
        _profilePhotoUrl = user.prefs.data['photoUrl'] as String?;
        _loading = false;
      });
    } on AppwriteException catch (e) {
      debugPrint("❌ Appwrite Error in Profile: ${e.message}, Code: ${e.code}");
      if (e.code == 401) {
        _forceLogout();
      } else {
        setState(() => _loading = false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (e) {
      debugPrint("❌ Other Error in Profile: $e");
      setState(() => _loading = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: $e")),
      );
    }
  }

  Future<void> _forceLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _logout() async {
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _name);
    final companyController = TextEditingController(text: _companyName);
    String? newPhotoUrl = _profilePhotoUrl;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: (newPhotoUrl?.isNotEmpty ?? false)
                          ? ((newPhotoUrl?.startsWith("http") ?? false)
                              ? NetworkImage(newPhotoUrl!)
                              : FileImage(File(newPhotoUrl!)) as ImageProvider)
                          : null,
                      child: (newPhotoUrl?.isEmpty ?? true)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setDialogState(() {
                            newPhotoUrl = picked.path;
                          });
                        }
                      },
                      child: const Text("Change Photo"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(labelText: "Company Name"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedName = nameController.text.trim();
                    final updatedCompany = companyController.text.trim();
                    String? uploadedPhotoUrl = newPhotoUrl;

                    if (newPhotoUrl != null && File(newPhotoUrl!).existsSync()) {
                      try {
                        // Placeholder for upload logic (e.g. Cloudinary)
                        uploadedPhotoUrl = newPhotoUrl;
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Image upload failed: $e")),
                        );
                        return;
                      }
                    }

                    try {
                      // Update name
                      if (updatedName.isNotEmpty) {
                        await AuthService.updateUserName(updatedName);
                      }

                      // Update company & photo in prefs
                      await AuthService.updateUserPrefs({
                        'companyName': updatedCompany,
                        'photoUrl': uploadedPhotoUrl ?? "",
                      });

                      if (!mounted) return;
                      setState(() {
                        _name = updatedName;
                        _companyName = updatedCompany;
                        _profilePhotoUrl = uploadedPhotoUrl;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile updated")),
                      );
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to update profile: $e")),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (_profilePhotoUrl?.isNotEmpty ?? false)
                  ? ((_profilePhotoUrl?.startsWith("http") ?? false)
                      ? NetworkImage(_profilePhotoUrl!)
                      : FileImage(File(_profilePhotoUrl!)) as ImageProvider)
                  : null,
              child: (_profilePhotoUrl?.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _editProfile,
              child: const Text(
                "Edit Profile",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  children: [
                    _buildInfoRow("Name", _name ?? "Unknown"),
                    const Divider(),
                    _buildInfoRow("Email", _email ?? "Unknown"),
                    const Divider(),
                    _buildInfoRow("Company", _companyName ?? "None"),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
