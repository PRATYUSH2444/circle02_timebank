import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/listing_model.dart';

class ListingRepository {
  final supabase = Supabase.instance.client;

  /// 🔥 FETCH (OPTIMIZED)
  Future<List<ListingModel>> fetchAll() async {
    final res = await supabase.rpc('get_listings_with_meta');

    return (res as List)
        .map((e) => ListingModel.fromMap(e))
        .toList();
  }

  /// CREATE
  Future<void> createListing({
    required String skill,
    required String level,
    required String description,
    required int duration,
    required List<DateTime> slots,
  }) async {
    final user = supabase.auth.currentUser;

    final listing = await supabase
        .from('listings')
        .insert({
      'mentor_id': user!.id,
      'skill': skill,
      'level': level,
      'description': description,
      'duration': duration,
    })
        .select()
        .single();

    for (var slot in slots) {
      await supabase.from('listing_slots').insert({
        'listing_id': listing['id'],
        'slot_time': slot.toIso8601String(),
      });
    }
  }

  /// UPDATE
  Future<void> updateListing({
    required String id,
    required String skill,
    required String level,
    required String description,
    required int duration,
  }) async {
    await supabase.from('listings').update({
      'skill': skill,
      'level': level,
      'description': description,
      'duration': duration,
    }).eq('id', id);
  }

  /// DELETE
  Future<void> deleteListing(String id) async {
    await supabase.from('listing_slots').delete().eq('listing_id', id);
    await supabase.from('listings').delete().eq('id', id);
  }

  /// GET SLOTS
  Future<List<Map<String, dynamic>>> getSlots(String listingId) async {
    final res = await supabase
        .from('listing_slots')
        .select()
        .eq('listing_id', listingId)
        .order('slot_time');

    return List<Map<String, dynamic>>.from(res);
  }
}