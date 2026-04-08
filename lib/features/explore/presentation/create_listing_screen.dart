import 'package:flutter/material.dart';
import '../repository/listing_repository.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState
    extends State<CreateListingScreen> {
  final repo = ListingRepository();

  final skillController = TextEditingController();
  final descController = TextEditingController();

  String level = "Beginner";
  int duration = 30;

  List<DateTime> slots = [];
  bool isLoading = false;

  Future<void> pickSlot() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final slot = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      slots.add(slot);
    });
  }

  Future<void> submit() async {
    if (skillController.text.isEmpty ||
        descController.text.isEmpty ||
        slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await repo.createListing(
        skill: skillController.text,
        level: level,
        description: descController.text,
        duration: duration,
        slots: slots,
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
      appBar: AppBar(title: const Text("Create Listing")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: skillController,
              decoration: const InputDecoration(
                  labelText: "Skill"),
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

            Row(
              children: [
                const Text("Duration: "),
                DropdownButton<int>(
                  value: duration,
                  items: [30, 45, 60]
                      .map((e) => DropdownMenuItem(
                      value: e, child: Text("$e min")))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => duration = v!),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickSlot,
              child: const Text("Add Slot"),
            ),

            ...slots.map((s) => ListTile(
              title: Text(
                  "${s.day}/${s.month} ${s.hour}:${s.minute}"),
            )),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : submit,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}