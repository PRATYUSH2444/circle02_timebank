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
  String? avatarUrl;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      imageBytes = await file.readAsBytes();
      setState(() {});
      await uploadAvatar();
    }
  }

  Future<void> uploadAvatar() async {
    final user = supabase.auth.currentUser;

    final fileName = '${user!.id}.png';

    await supabase.storage
        .from('avatars')
        .uploadBinary(
      fileName,
      imageBytes!,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = supabase.storage.from('avatars').getPublicUrl(fileName);

    await supabase
        .from('users')
        .update({'avatar_url': url})
        .eq('id', user.id);

    setState(() => avatarUrl = url);
  }

  Future<Map<String, dynamic>> fetchUser() async {
    final user = supabase.auth.currentUser;

    return await supabase
        .from('users')
        .select()
        .eq('id', user!.id)
        .single();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: FutureBuilder(
        future: fetchUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;
          avatarUrl = user['avatar_url'];

          return Stack(
            children: [
              const _GradientBg(),

              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl!)
                                  : null,
                              child: avatarUrl == null
                                  ? const Icon(Icons.add_a_photo,
                                  color: Colors.white)
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(user['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),

                          const SizedBox(height: 5),

                          Text(user['email'],
                              style: const TextStyle(
                                  color: Colors.white60)),

                          const SizedBox(height: 20),

                          _infoCard("Tokens", "${user['tokens']}"),
                          const SizedBox(height: 10),
                          _infoCard("Role", "Learner + Teacher"),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                            ),
                            onPressed: () async {
                              await supabase.auth.signOut();
                              context.go('/login');
                            },
                            child: const Text("Logout",
                                style: TextStyle(color: Colors.black)),
                          ),
                        ],
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

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white60)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

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