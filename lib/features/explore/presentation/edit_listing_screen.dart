import 'package:flutter/material.dart';
import '../repository/listing_repository.dart';
import '../model/listing_model.dart';

class EditListingScreen extends StatefulWidget {
  final ListingModel listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() =>
      _EditListingScreenState();
}

class _EditListingScreenState
    extends State<EditListingScreen> {
  final repo = ListingRepository();

  late TextEditingController skillController;
  late TextEditingController descController;

  late String level;
  late int duration;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    skillController =
        TextEditingController(text: widget.listing.skill);
    descController =
        TextEditingController(text: widget.listing.description);

    level = widget.listing.level;
    duration = widget.listing.duration;
  }

  Future<void> update() async {
    setState(() => isLoading = true);

    try {
      await repo.updateListing(
        id: widget.listing.id,
        skill: skillController.text,
        level: level,
        description: descController.text,
        duration: duration,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Listing")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: skillController,
              decoration:
              const InputDecoration(labelText: "Skill"),
            ),

            TextField(
              controller: descController,
              decoration:
              const InputDecoration(labelText: "Description"),
            ),

            DropdownButton<String>(
              value: level,
              items: ["Beginner", "Intermediate", "Advanced"]
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => level = v!),
            ),

            const SizedBox(height: 10),

            DropdownButton<int>(
              value: duration,
              items: [30, 45, 60]
                  .map((e) => DropdownMenuItem(
                  value: e, child: Text("$e min")))
                  .toList(),
              onChanged: (v) =>
                  setState(() => duration = v!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : update,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}