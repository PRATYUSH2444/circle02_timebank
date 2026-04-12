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

  void openSlots(ListingModel l) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser!.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              child: Column(
                children: [

                  /// HEADER
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.cyan,
                        child: Text(
                          l.skill[0],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.skill,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text("by ${l.mentorName}",
                              style:
                              const TextStyle(color: Colors.white70)),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// SLOT LIST
                  Expanded(
                    child: slots.isEmpty
                        ? const Center(
                      child: Text(
                        "No slots available",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                        : ListView.builder(
                      itemCount: slots.length,
                      itemBuilder: (_, i) {
                        final s = slots[i];
                        final time =
                        DateTime.parse(s['slot_time']);
                        final isBooked =
                            s['is_booked'] ?? false;

                        final isOwner =
                            currentUserId == l.mentorId;

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            title: Text(
                              "${time.day}/${time.month} • ${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                  color: Colors.white),
                            ),

                            subtitle: Text(
                              isOwner
                                  ? "Your listing"
                                  : isBooked
                                  ? "Booked"
                                  : "Available",
                              style: TextStyle(
                                color: isOwner
                                    ? Colors.orange
                                    : isBooked
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),

                            trailing: isOwner
                                ? const Icon(Icons.person,
                                color: Colors.orange)
                                : isBooked
                                ? const Icon(Icons.lock,
                                color: Colors.red)
                                : ElevatedButton(
                              onPressed: () async {
                                await sessionRepo
                                    .bookSession(
                                  listingId: l.id,
                                  teacherId:
                                  l.mentorId,
                                  slotId: s['id'],
                                  slotTime: time,
                                  duration:
                                  l.duration,
                                );

                                if (!mounted) return;

                                Navigator.pop(context);

                                ScaffoldMessenger.of(
                                    context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Session booked 🎉"),
                                  ),
                                );

                                fetch();
                              },
                              style: ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                Colors.cyan,
                              ),
                              child:
                              const Text("Book"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildCard(ListingModel l) {
    return GestureDetector(
      onTap: () => openSlots(l),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.cyan,
              child: Text(
                l.skill[0],
                style: const TextStyle(color: Colors.black),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.skill,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text("👤 ${l.mentorName}",
                      style:
                      const TextStyle(color: Colors.white70)),
                  Text("${l.level} • ${l.duration} mins",
                      style:
                      const TextStyle(color: Colors.white60)),
                  Text("Slots: ${l.totalSlots}",
                      style: const TextStyle(
                          color: Colors.cyanAccent)),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward,
                color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        Supabase.instance.client.auth.currentUser?.id;

    final myListings =
    listings.where((e) => e.mentorId == userId).toList();

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Explore"),
        backgroundColor: Colors.transparent,
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: "explore_fab",          // ✅ FIX — unique heroTag
        backgroundColor: Colors.cyan,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateListingScreen()),
          );

          if (result == true) fetch();
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// SECTION 1
            const Text("🌍 Discover Mentors",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            ...listings.map(buildCard),

            const SizedBox(height: 20),

            /// SECTION 2
            const Divider(color: Colors.white24),

            const SizedBox(height: 10),

            const Text("🧑 Your Listings",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

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
                                EditListingScreen(listing: l),
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