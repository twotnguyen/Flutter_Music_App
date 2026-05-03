import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/podcast_repository.dart';
import '../repositories/search_repository.dart';
import '../repositories/artist_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/collection_repository.dart';
import '../repositories/song_repository.dart';
import '../repositories/follow_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Centralized API client — all repositories use this instead of direct Supabase calls.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref.watch(apiClientProvider), ref.watch(supabaseClientProvider));
});

final podcastRepositoryProvider = Provider<PodcastRepository>((ref) {
  return PodcastRepository(ref.watch(apiClientProvider), ref.watch(supabaseClientProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository(ref.watch(apiClientProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(apiClientProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(ref.watch(apiClientProvider), ref.watch(supabaseClientProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository(ref.watch(apiClientProvider), ref.watch(supabaseClientProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.watch(apiClientProvider));
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(apiClientProvider));
});
