import '../models/song.dart';
import '../services/api_client.dart';

class SongRepository {
  final ApiClient _api;

  SongRepository(this._api);

  /// Fetch songs for the "Trending" section, ordered by like count.
  Future<List<Song>> fetchTrendingSongs({int limit = 50}) async {
    final data = await _api.fetchTrendingSongs(limit: limit);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Fetch all songs for a general picker, with optional search query.
  Future<List<Song>> fetchAllSongs({String? query, int limit = 100}) async {
    final data = await _api.fetchAllSongs(query: query, limit: limit);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Get a single song by its ID.
  Future<Song?> getSongById(int songId) async {
    final data = await _api.getSongById(songId);
    if (data == null) return null;
    return Song.fromJson(data);
  }

  /// Fetch all songs associated with an artist.
  Future<List<Song>> fetchSongsByArtist(String artistId, {int limit = 20}) async {
    final data = await _api.getArtistSongs(artistId);
    return data.take(limit).map((e) => Song.fromJson(e)).toList();
  }

  /// Get a single random song from the database.
  Future<Song?> fetchRandomSong() async {
    final data = await _api.fetchTrendingSongs(limit: 50);
    final list = data.map((e) => Song.fromJson(e)).toList();
    if (list.isEmpty) return null;
    list.shuffle();
    return list.first;
  }
}
