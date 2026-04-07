import 'package:flutter/material.dart';
import '../repository/listing_repository.dart';
import '../model/listing_model.dart';

class EditListingScreen extends StatefulWidget {
  final ListingModel listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late TextEditingController skill;
  late TextEditingController desc;

  String level = "Beginner";
  int duration = 60;

  @override
  void initState() {
    skill = TextEditingController(text: widget.listing.skill);
    desc = TextEditingController(text: widget.listing.description);
    level = widget.listing.level;
    duration = widget.listing.duration;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Listing")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: skill,
              decoration: const InputDecoration(labelText: "Skill"),
            ),

            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            DropdownButton<String>(
              value: level,
              items: ["Beginner", "Intermediate", "Advanced"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (val) => setState(() => level = val!),
            ),

            DropdownButton<int>(
              value: duration,
              items: [30, 60, 90]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text("$e min"),
              ))
                  .toList(),
              onChanged: (val) => setState(() => duration = val!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await ListingRepository().updateListing(
                  id: widget.listing.id,
                  skill: skill.text,
                  level: level,
                  description: desc.text,
                  duration: duration,
                );

                Navigator.pop(context);
              },
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}