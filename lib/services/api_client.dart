import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized API client for communicating with the Edge Function backend.
/// Replaces direct Supabase table queries with REST API calls.
class ApiClient {
  late final Dio _dio;
  final SupabaseClient _supabase;

  ApiClient(this._supabase) {
    final baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://znmfjbyvmiumctouolde.supabase.co/functions/v1/api',
    );

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'apikey': const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: '',
        ),
      },
    ));

    // Interceptor to automatically attach auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
    ));
  }

  // ─── Songs ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchTrendingSongs({int limit = 50}) async {
    final res = await _dio.get('/songs/trending', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchAllSongs({String? query, int limit = 100}) async {
    final params = <String, dynamic>{'limit': limit};
    if (query != null && query.isNotEmpty) params['query'] = query;
    final res = await _dio.get('/songs', queryParameters: params);
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>?> getSongById(int songId) async {
    try {
      final res = await _dio.get('/songs/$songId');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ─── Artists ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPopularArtists({int limit = 20}) async {
    final res = await _dio.get('/artists', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> getArtistDetail(String artistId) async {
    final res = await _dio.get('/artists/$artistId');
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getArtistSongs(String artistId) async {
    final res = await _dio.get('/artists/$artistId/songs');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getArtistAlbums(String artistId) async {
    final res = await _dio.get('/artists/$artistId/albums');
    return List<Map<String, dynamic>>.from(res.data);
  }

  // ─── Albums ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchNewAlbums({int limit = 10}) async {
    final res = await _dio.get('/albums/new', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchAlbumSongs(int albumId) async {
    final res = await _dio.get('/albums/$albumId/songs');
    return List<Map<String, dynamic>>.from(res.data);
  }

  // ─── Playlists ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSystemPlaylists() async {
    final res = await _dio.get('/playlists/system');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchUserPlaylists() async {
    final res = await _dio.get('/playlists/user');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchPlaylistSongs(int playlistId) async {
    final res = await _dio.get('/playlists/$playlistId/songs');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    final res = await _dio.post('/playlists', data: {
      'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _dio.delete('/playlists/$playlistId');
  }

  // ─── Favorites ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final res = await _dio.get('/favorites');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<bool> checkFavorite(int songId) async {
    final res = await _dio.get('/favorites/check', queryParameters: {'song_id': songId});
    return res.data['liked'] as bool;
  }

  Future<bool> toggleFavorite(int songId) async {
    final res = await _dio.post('/favorites/toggle', data: {'song_id': songId});
    return res.data['liked'] as bool;
  }

  // ─── Follows ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchFollowedArtists() async {
    final res = await _dio.get('/follows');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<bool> checkFollow(String artistId) async {
    final res = await _dio.get('/follows/check', queryParameters: {'artist_id': artistId});
    return res.data['followed'] as bool;
  }

  Future<bool> toggleFollow(String artistId) async {
    final res = await _dio.post('/follows/toggle', data: {'artist_id': artistId});
    return res.data['followed'] as bool;
  }

  // ─── Search ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> search(String query) async {
    final res = await _dio.get('/search', queryParameters: {'q': query});
    return Map<String, dynamic>.from(res.data);
  }

  // ─── Discover ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> discover() async {
    final res = await _dio.get('/discover');
    return Map<String, dynamic>.from(res.data);
  }

  // ─── Podcasts ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPodcasts() async {
    final res = await _dio.get('/podcasts');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchPodcastsByChannel(String channelId) async {
    final res = await _dio.get('/podcasts/channel/$channelId');
    return List<Map<String, dynamic>>.from(res.data);
  }

  // ─── Player State ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchPlayerState() async {
    final res = await _dio.get('/player/state');
    if (res.data == null) return null;
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updatePlayerState(Map<String, dynamic> state) async {
    await _dio.put('/player/state', data: state);
  }
}
