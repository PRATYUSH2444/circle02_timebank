import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final supabase = Supabase.instance.client;

  Uint8List? imageBytes;
  bool isUploading = false;

  /// 🔥 REALTIME USER STREAM
  Stream<Map<String, dynamic>> userStream() {
    final userId = supabase.auth.currentUser!.id;

    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.first);
  }

  /// 🔥 PICK IMAGE
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      imageBytes = await file.readAsBytes();
      await uploadAvatar();
    }
  }

  /// 🔥 UPLOAD AVATAR (OPTIMIZED)
  Future<void> uploadAvatar() async {
    final user = supabase.auth.currentUser;
    if (imageBytes == null || user == null) return;

    setState(() => isUploading = true);

    try {
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        imageBytes!,
        fileOptions: const FileOptions(upsert: true),
      );

      final url =
      supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'avatar_url': url})
          .eq('id', user.id);

    } catch (e) {
      debugPrint("Upload Error: $e");
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: StreamBuilder(
        stream: userStream(),
        builder: (context, snapshot) {

          /// 🔄 LOADING
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error loading profile",
                      style: TextStyle(color: Colors.white)),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;
          final avatarUrl = user['avatar_url'];

          return Stack(
            children: [
              const _GradientBg(),

              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),

                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

                        child: Container(
                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),

                          child: Column(
                            children: [

                              /// 🔥 AVATAR
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: pickImage,
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey.shade800,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? const Icon(Icons.camera_alt,
                                          color: Colors.white)
                                          : null,
                                    ),
                                  ),

                                  if (isUploading)
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              /// NAME
                              Text(
                                user['name'] ?? "User",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              /// EMAIL
                              Text(
                                user['email'] ?? "",
                                style: const TextStyle(
                                    color: Colors.white60),
                              ),

                              const SizedBox(height: 25),

                              /// 🔥 TOKENS (REALTIME)
                              _infoCard("Tokens", "${user['tokens'] ?? 0}"),

                              const SizedBox(height: 10),

                              _infoCard("Role", "Learner + Teacher"),

                              const SizedBox(height: 20),

                              /// 🔥 WALLET
                              ElevatedButton.icon(
                                icon: const Icon(Icons.account_balance_wallet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                ),
                                onPressed: () {
                                  context.push('/wallet');
                                },
                                label: const Text("Open Wallet"),
                              ),

                              const SizedBox(height: 15),

                              /// 🔥 LOGOUT
                              ElevatedButton.icon(
                                icon: const Icon(Icons.logout),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  await supabase.auth.signOut();
                                  context.go('/login');
                                },
                                label: const Text("Logout"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔥 INFO CARD
  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white60)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// 🔥 BACKGROUND
class _GradientBg extends StatelessWidget {
  const _GradientBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Color(0xFF0f2027),
            Color(0xFF2c5364),
          ],
        ),
      ),
    );
  }
}