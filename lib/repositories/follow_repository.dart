import '../models/artist.dart';
import '../services/api_client.dart';

class FollowRepository {
  final ApiClient _api;

  FollowRepository(this._api);

  /// Check if an artist is followed by the current user.
  Future<bool> isArtistFollowed(String userId, String artistId) async {
    return await _api.checkFollow(artistId);
  }

  /// Toggle following status for an artist.
  Future<void> toggleFollow(String userId, String artistId, bool isAlreadyFollowing) async {
    await _api.toggleFollow(artistId);
  }

  /// Fetch all artists followed by the current user.
  Future<List<Artist>> fetchFollowedArtists(String userId) async {
    final data = await _api.fetchFollowedArtists();
    return data.map((e) => Artist.fromJson(e)).toList();
  }
}
