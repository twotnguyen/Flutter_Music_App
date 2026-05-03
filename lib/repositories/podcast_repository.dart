import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/podcast.dart';
import '../models/podcast_channel.dart';
import '../services/api_client.dart';

class PodcastRepository {
  final ApiClient _api;
  final SupabaseClient _supabase; // Kept for subscription management

  PodcastRepository(this._api, this._supabase);

  Future<List<Podcast>> fetchAllPodcasts() async {
    final data = await _api.fetchPodcasts();
    return data.map((row) => Podcast.fromJson(row)).toList();
  }

  Future<List<PodcastChannel>> fetchSubscribedChannels(String userId) async {
    final response = await _supabase
        .from('channel_subscriptions')
        .select('channel_id, podcast_channels(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((row) => row['podcast_channels'] != null)
        .map((row) => PodcastChannel.fromJson(row['podcast_channels']))
        .toList();
  }

  Future<List<Podcast>> fetchPodcastsByChannel(String channelId) async {
    final data = await _api.fetchPodcastsByChannel(channelId);
    return data.map((row) => Podcast.fromJson(row)).toList();
  }

  Future<PodcastChannel> getChannelDetail(String channelId) async {
    final response = await _supabase
        .from('podcast_channels')
        .select()
        .eq('id', channelId)
        .single();
    return PodcastChannel.fromJson(response);
  }

  Future<bool> checkIsSubscribed(String userId, String channelId) async {
    final response = await _supabase
        .from('channel_subscriptions')
        .select('id')
        .eq('user_id', userId)
        .eq('channel_id', channelId)
        .maybeSingle();
    return response != null;
  }

  Future<void> toggleSubscription(String userId, String channelId, bool isSubscribed) async {
    if (isSubscribed) {
      await _supabase.from('channel_subscriptions').delete().match({
        'user_id': userId,
        'channel_id': channelId,
      });
    } else {
      await _supabase.from('channel_subscriptions').insert({
        'user_id': userId,
        'channel_id': channelId,
      });
    }
  }

  Future<List<Podcast>> fetchLatestPodcastsFromSubscriptions(String userId) async {
    final subs = await _supabase
        .from('channel_subscriptions')
        .select('channel_id')
        .eq('user_id', userId);
    
    final channelIds = (subs as List).map((row) => row['channel_id'] as String).toList();
    if (channelIds.isEmpty) return [];

    final response = await _supabase
        .from('podcasts')
        .select('*, podcast_channels(*)')
        .inFilter('channel_id', channelIds)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(30);

    return (response as List).map((row) => Podcast.fromJson(row)).toList();
  }
}
