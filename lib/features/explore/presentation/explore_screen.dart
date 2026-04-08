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

  /// 🔥 SLOT UI (UPGRADED)
  void openSlots(ListingModel l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return FutureBuilder(
          future: repo.getSlots(l.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final slots = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                shrinkWrap: true,
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
                      color: isBooked ? Colors.grey[800] : Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          isBooked ? "Booked" : "Available",
                          style: TextStyle(
                            color: isBooked
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        trailing: Icon(
                          isBooked
                              ? Icons.lock
                              : Icons.lock_open,
                          color: isBooked
                              ? Colors.red
                              : Colors.green,
                        ),

                        onTap: isBooked
                            ? null
                            : () async {
                          await sessionRepo.bookSession(
                            listingId: l.id,
                            teacherId: l.mentorId,
                            slotId: s['id'],
                            slotTime: time,
                            duration: l.duration,
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Session booked 🎉")),
                          );

                          fetch();
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
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.all(12),
                  title: Text(
                    l.skill,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text("👤 ${l.mentorName}",
                          style: const TextStyle(
                              color: Colors.white70)),
                      Text(
                          "${l.level} • ${l.duration} mins",
                          style: const TextStyle(
                              color: Colors.white60)),
                      Text(
                          "Slots: ${l.totalSlots}",
                          style: const TextStyle(
                              color: Colors.cyanAccent)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward,
                      color: Colors.white),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
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
                      icon: const Icon(Icons.delete),
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