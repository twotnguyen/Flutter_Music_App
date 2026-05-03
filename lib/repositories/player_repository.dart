import '../models/song.dart';
import '../models/podcast.dart';
import '../services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerRepository {
  final ApiClient _api;
  final SupabaseClient _supabase; // Kept for logListen (direct insert)

  PlayerRepository(this._api, this._supabase);

  Future<Map<String, dynamic>?> fetchPlayerState(String userId) async {
    return await _api.fetchPlayerState();
  }

  Future<void> updatePlayerState({
    required String userId,
    required String? currentSongId,
    required String? currentPlaylistId,
    required int positionSeconds,
    required String repeatMode,
    required bool shuffleEnabled,
  }) async {
    await _api.updatePlayerState({
      'current_song_id': currentSongId,
      'current_playlist_id': currentPlaylistId,
      'position_seconds': positionSeconds,
      'repeat_mode': repeatMode,
      'shuffle_enabled': shuffleEnabled,
    });
  }

  Future<void> logListen({
    required String userId,
    String? songId,
    String? podcastId,
  }) async {
    await _supabase.from('listens').insert({
      'user_id': userId,
      'song_id': songId,
      'podcast_id': podcastId,
      'listened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<dynamic>> fetchRecentPlays(String userId) async {
    final response = await _supabase
        .from('listens')
        .select('song_id, podcast_id, listened_at, songs:songs!listens_song_id_fkey(*), podcasts:podcasts!listens_podcast_id_fkey(*)')
        .eq('user_id', userId)
        .order('listened_at', ascending: false)
        .limit(30);

    final List<dynamic> result = [];
    final Set<String> seenIds = {};

    for (var row in response as List) {
      if (row['song_id'] != null && row['songs'] != null) {
        final songId = 'song_${row['song_id']}';
        if (!seenIds.contains(songId)) {
          seenIds.add(songId);
          result.add(Song.fromJson(row['songs'] as Map<String, dynamic>));
        }
      } else if (row['podcast_id'] != null && row['podcasts'] != null) {
        final podcastId = 'podcast_${row['podcast_id']}';
        if (!seenIds.contains(podcastId)) {
          seenIds.add(podcastId);
          result.add(Podcast.fromJson(row['podcasts'] as Map<String, dynamic>));
        }
      }
      if (result.length >= 6) break;
    }

    return result;
  }
}
