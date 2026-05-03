import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/podcast.dart';
import '../helpers/local_recent_search_helper.dart';
import '../services/api_client.dart';

class SearchRepository {
  final ApiClient _api;

  SearchRepository(this._api);

  // ─── Multi-Entity Search (Unified — single API call) ──────────────────────
  
  Future<List<Song>> searchSongs(String query) async {
    final result = await _api.search(query);
    final songs = result['songs'] as List? ?? [];
    return songs.map((e) => Song.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Artist>> searchArtists(String query) async {
    final result = await _api.search(query);
    final artists = result['artists'] as List? ?? [];
    return artists.map((e) => Artist.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Album>> searchAlbums(String query) async {
    final result = await _api.search(query);
    final albums = result['albums'] as List? ?? [];
    return albums.map((e) => Album.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Playlist>> searchPlaylists(String query) async {
    final result = await _api.search(query);
    final playlists = result['playlists'] as List? ?? [];
    return playlists.map((e) => Playlist.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Podcast>> searchPodcasts(String query) async {
    final result = await _api.search(query);
    final podcasts = result['podcasts'] as List? ?? [];
    return podcasts.map((e) => Podcast.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Map<String, dynamic>>> searchGenres(String query) async {
    final result = await _api.discover();
    final genres = result['genres'] as List? ?? [];
    return List<Map<String, dynamic>>.from(genres)
        .where((g) => (g['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchMoods(String query) async {
    try {
      final result = await _api.discover();
      final moods = result['moods'] as List? ?? [];
      return List<Map<String, dynamic>>.from(moods)
          .where((m) => (m['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchHashtags(String query) async {
    final result = await _api.discover();
    final hashtags = result['hashtags'] as List? ?? [];
    return List<Map<String, dynamic>>.from(hashtags)
        .where((h) => (h['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ─── Search History ────────────────────────────────────────────────────────

  final LocalRecentSearchHelper _localHelper = LocalRecentSearchHelper();

  Future<List<Map<String, dynamic>>> getRecentSearches(String? userId) async {
    return await _localHelper.getRecentSearches();
  }

  Future<void> saveSearchItem({
    String? userId,
    required String keyword,
    required String contentType,
    String? contentId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    final item = {
      'keyword': keyword,
      'content_type': contentType,
      'content_id': contentId,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _localHelper.saveSearch(item);
  }

  Future<void> clearRecentSearches(String? userId) async {
    await _localHelper.clearAll();
  }

  Future<void> removeSearchItem({
    String? userId,
    required String contentType,
    String? contentId,
    String? keyword,
  }) async {
    await _localHelper.removeSearch({
      'content_type': contentType,
      'content_id': contentId,
      'keyword': keyword,
    });
  }

  // ─── Discovery Data ────────────────────────────────────────────────────────

  Future<List<String>> getTrendingKeywords() async {
    final result = await _api.discover();
    final keywords = result['trending_keywords'] as List? ?? [];
    return keywords.map((e) => e.toString()).toList();
  }

  Future<List<Map<String, dynamic>>> getHashtags() async {
    final result = await _api.discover();
    return List<Map<String, dynamic>>.from(result['hashtags'] as List? ?? []);
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final result = await _api.discover();
    return List<Map<String, dynamic>>.from(result['genres'] as List? ?? []);
  }

  Future<List<Map<String, dynamic>>> getMoods() async {
    try {
      final result = await _api.discover();
      return List<Map<String, dynamic>>.from(result['moods'] as List? ?? []);
    } catch (e) {
      return [];
    }
  }
}
