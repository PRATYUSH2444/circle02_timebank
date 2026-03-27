import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/feed_provider.dart';
import '../repository/feed_repository.dart';

class CreatePostDialog extends ConsumerStatefulWidget {
  const CreatePostDialog({super.key});

  @override
  ConsumerState<CreatePostDialog> createState() =>
      _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<CreatePostDialog> {
  final controller = TextEditingController();
  String selectedType = "learning";

  Uint8List? imageBytes; // ✅ ADDED

  // ✅ IMAGE PICKER
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      imageBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Create Post",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "What are you doing?",
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "learning", child: Text("Learning")),
                DropdownMenuItem(value: "teaching", child: Text("Teaching")),
                DropdownMenuItem(value: "availability", child: Text("Available")),
              ],
              onChanged: (val) {
                setState(() {
                  selectedType = val!;
                });
              },
            ),

            const SizedBox(height: 10),

            // ✅ ADD IMAGE BUTTON
            TextButton(
              onPressed: pickImage,
              child: const Text("Add Image"),
            ),

            // ✅ PREVIEW (optional but useful)
            if (imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(imageBytes!, height: 100),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;

                  await ref.read(feedRepositoryProvider).createPost(
                    content: controller.text.trim(),
                    type: selectedType,
                    imageBytes: imageBytes, // ✅ UPDATED
                  );

                  if (!context.mounted) return;

                  Navigator.pop(context);
                  ref.invalidate(feedProvider);
                },
                child: const Text("Post"),
              ),
            )
          ],
        ),
      ),
    );
  }
}