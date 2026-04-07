import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/listing_repository.dart';
import '../model/listing_model.dart';
import 'create_listing_screen.dart';
import 'edit_listing_screen.dart';
import '../../sessions/repository/session_repository.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final repo = ListingRepository();
  final sessionRepo = SessionRepository();

  List<ListingModel> listings = [];
  bool isLoading = true;

  late RealtimeChannel slotChannel;

  @override
  void initState() {
    super.initState();
    fetch();

    slotChannel = Supabase.instance.client.channel('slots_changes');

    slotChannel
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'listing_slots',
      callback: (_) => fetch(),
    )
        .subscribe();
  }

  @override
  void dispose() {
    slotChannel.unsubscribe();
    super.dispose();
  }

  Future<void> fetch() async {
    final data = await repo.fetchAll();

    if (!mounted) return;

    setState(() {
      listings = data;
      isLoading = false;
    });
  }

  // 🔥 OPEN SLOTS
  void openSlots(ListingModel l) async {
    final slots = await repo.getSlots(l.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.skill,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${l.level} • ${l.duration} mins",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 20),

                  if (slots.isEmpty)
                    const Text("No slots available",
                        style: TextStyle(color: Colors.white)),

                  ...slots.map((s) {
                    final time = DateTime.parse(s['slot_time']);
                    final isBooked = s['is_booked'] ?? false;

                    return Card(
                      color: isBooked ? Colors.grey[800] : null,
                      child: ListTile(
                        title: Text(
                          "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                        ),
                        subtitle: Text(
                          isBooked ? "Already booked" : "Available",
                        ),
                        trailing: isBooked
                            ? const Icon(Icons.lock, color: Colors.red)
                            : const Icon(Icons.lock_open,
                            color: Colors.green),

                        onTap: isBooked
                            ? null
                            : () async {
                          final messenger =
                          ScaffoldMessenger.of(context);

                          try {
                            // 🔥 LOADING
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                  child:
                                  CircularProgressIndicator()),
                            );

                            await sessionRepo.bookSession(
                              listingId: l.id,
                              teacherId: l.mentorId,
                              slotId: s['id'],
                              slotTime: time,
                              duration: l.duration,
                            );

                            if (!mounted) return;

                            Navigator.pop(context); // loading
                            Navigator.pop(context); // sheet

                            messenger.showSnackBar(
                              const SnackBar(
                                content:
                                Text("Session booked 🎉"),
                              ),
                            );

                            fetch();
                          } catch (e) {
                            Navigator.pop(context);

                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(e.toString())),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final myListings =
    listings.where((e) => e.mentorId == userId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Explore")),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateListingScreen()),
          );

          if (result == true) fetch();
        },
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetch,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text("🌍 All Mentors",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            ...listings.map((l) => GestureDetector(
              onTap: () => openSlots(l),
              child: Card(
                child: ListTile(
                  title: Text(l.skill),
                  subtitle: Text(
                      "${l.level} • ${l.duration} mins"),
                  trailing:
                  const Icon(Icons.arrow_forward),
                ),
              ),
            )),

            const SizedBox(height: 20),
            const Divider(),

            const Text("🧑 My Listings",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            ...myListings.map((l) => Card(
              child: ListTile(
                title: Text(l.skill),
                subtitle: Text(
                    "${l.level} • ${l.duration} mins"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.blue),
                      onPressed: () async {
                        final result =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditListingScreen(
                                    listing: l),
                          ),
                        );

                        if (result == true) fetch();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () async {
                        await repo.deleteListing(l.id);
                        fetch();
                      },
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}