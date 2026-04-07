import 'package:flutter/material.dart';
import '../repository/listing_repository.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final skillController = TextEditingController();
  final descController = TextEditingController();

  String level = "Beginner";
  int duration = 60;

  List<DateTime> slots = [];

  bool isLoading = false;

  // ✅ DISPOSE (VERY IMPORTANT)
  @override
  void dispose() {
    skillController.dispose();
    descController.dispose();
    super.dispose();
  }

  // ✅ DATE + TIME PICKER (SAFE)
  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final fullDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() => slots.add(fullDateTime));
  }

  // ✅ SUCCESS POPUP (SAFE CONTEXT)
  void showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });

        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 15),
                Text(
                  "Listing Created!",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ CREATE LISTING (MAIN FIXED LOGIC)
  Future<void> createListing() async {
    final messenger = ScaffoldMessenger.of(context);

    if (skillController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        slots.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Fill all fields + add slot"),
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await ListingRepository().createListing(
        skill: skillController.text.trim(),
        level: level,
        description: descController.text.trim(),
        duration: duration,
        slots: slots,
      );

      if (!mounted) return;

      showSuccessPopup();

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pop(context, true); // 🔥 triggers refresh
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teach a Skill")),

      // ✅ FIXED: keyboard overflow
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 SKILL
                TextField(
                  controller: skillController,
                  decoration: const InputDecoration(labelText: "Skill"),
                ),

                const SizedBox(height: 10),

                // 🔹 DESCRIPTION
                TextField(
                  controller: descController,
                  decoration:
                  const InputDecoration(labelText: "Description"),
                ),

                const SizedBox(height: 10),

                // 🔹 LEVEL
                DropdownButtonFormField<String>(
                  value: level,
                  items: ["Beginner", "Intermediate", "Advanced"]
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (val) => setState(() => level = val!),
                  decoration: const InputDecoration(labelText: "Level"),
                ),

                const SizedBox(height: 10),

                // 🔹 DURATION
                Row(
                  children: [
                    const Text("Duration: "),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: duration,
                      items: [30, 60, 90]
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("$e min"),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => duration = val!),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 ADD SLOT
                ElevatedButton.icon(
                  onPressed: pickDateTime,
                  icon: const Icon(Icons.schedule),
                  label: const Text("Add Time Slot"),
                ),

                const SizedBox(height: 10),

                // 🔹 SLOT LIST
                if (slots.isEmpty)
                  const Text("No slots added")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final s = slots[index];

                      return ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(
                          "${s.day}/${s.month}/${s.year}",
                        ),
                        subtitle: Text(
                          "${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () {
                            setState(() => slots.removeAt(index));
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // 🔹 PUBLISH BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createListing,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Publish"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}