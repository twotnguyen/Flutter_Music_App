import '../models/artist.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../services/api_client.dart';

class ArtistRepository {
  final ApiClient _api;

  ArtistRepository(this._api);

  /// Fetch public popular artists.
  Future<List<Artist>> fetchPopularArtists({int limit = 20}) async {
    final data = await _api.fetchPopularArtists(limit: limit);
    return data.map((e) => Artist.fromJson(e)).toList();
  }

  /// Get detailed metadata for a single artist.
  Future<Artist> getArtistDetail(String artistId) async {
    final data = await _api.getArtistDetail(artistId);
    return Artist.fromJson(data);
  }

  /// Fetch all songs where this artist is a primary or featured artist.
  Future<List<Song>> getArtistSongs(String artistId) async {
    final data = await _api.getArtistSongs(artistId);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  /// Fetch all albums associated with this artist.
  Future<List<Album>> getArtistAlbums(String artistId) async {
    final data = await _api.getArtistAlbums(artistId);
    return data.map((e) => Album.fromJson(e)).toList();
  }
}
