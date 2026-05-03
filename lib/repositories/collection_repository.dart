import '../models/playlist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionRepository {
  final ApiClient _api;
  final SupabaseClient _supabase; // Kept for save/unsave (direct RPC calls)

  CollectionRepository(this._api, this._supabase);

  /// Fetch system curated playlists.
  Future<List<Playlist>> fetchSystemPlaylists() async {
    final data = await _api.fetchSystemPlaylists();
    return data.map((e) => Playlist.fromJson(e)).toList();
  }

  /// Fetch new albums.
  Future<List<Album>> fetchNewAlbums() async {
    final data = await _api.fetchNewAlbums();
    return data.map((e) => Album.fromJson(e)).toList();
  }

  /// Get details and songs of a playlist.
  Future<List<Song>> fetchPlaylistSongs(int playlistId) async {
    final data = await _api.fetchPlaylistSongs(playlistId);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Get details and songs of an album.
  Future<List<Song>> fetchAlbumSongs(int albumId) async {
    final data = await _api.fetchAlbumSongs(albumId);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Check if a playlist is saved/bookmarked by a user.
  Future<bool> isPlaylistSaved(String userId, int playlistId) async {
    final response = await _supabase
        .from('user_saved_playlists')
        .select('id')
        .eq('user_id', userId)
        .eq('playlist_id', playlistId)
        .maybeSingle();
    return response != null;
  }

  /// Toggle saving/bookmarking status for a playlist.
  Future<void> toggleSavePlaylist(String userId, int playlistId, bool isAlreadySaved) async {
    if (isAlreadySaved) {
      await _supabase.from('user_saved_playlists').delete().match({
        'user_id': userId,
        'playlist_id': playlistId,
      });
    } else {
      await _supabase.from('user_saved_playlists').insert({
        'user_id': userId,
        'playlist_id': playlistId,
      });
    }
  }

  /// Fetch all playlists saved (bookmarked) by a user.
  Future<List<Playlist>> fetchSavedPlaylists(String userId) async {
    final response = await _supabase
        .from('user_saved_playlists')
        .select('playlist_id, playlists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['playlists'] != null)
        .map((row) => Playlist.fromJson(row['playlists'] as Map<String, dynamic>))
        .toList();
  }
}
