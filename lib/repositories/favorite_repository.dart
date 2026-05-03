import '../models/song.dart';
import '../services/api_client.dart';

class FavoriteRepository {
  final ApiClient _api;

  FavoriteRepository(this._api);

  /// Check if a song is liked by the current user.
  Future<bool> isSongLiked(String userId, int songId) async {
    return await _api.checkFavorite(songId);
  }

  /// Toggle like status for a song.
  Future<void> toggleLike(String userId, int songId, bool isAlreadyLiked) async {
    await _api.toggleFavorite(songId);
  }

  /// Fetch all songs liked by the current user.
  Future<List<Song>> fetchLikedSongs(String userId) async {
    final data = await _api.fetchFavorites();
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Get the total count of liked songs for a user.
  Future<int> getLikedSongsCount(String userId) async {
    final data = await _api.fetchFavorites();
    return data.length;
  }
}
