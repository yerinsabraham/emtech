import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

// Try to import local config (gitignored file with actual credentials)
// This will only work in development when the file exists
import 'agora_config_local.dart' as local;

/// Agora Configuration
/// 
/// This class fetches Agora credentials from:
/// 1. Local config file (development only, gitignored)
/// 2. Firebase Remote Config (production/fallback)
/// 
/// Setup:
/// 1. For local development, credentials are in agora_config_local.dart
/// 2. For production, set up Firebase Remote Config with key: 'agora_app_id'

class AgoraConfig {
  static FirebaseRemoteConfig? _remoteConfig;
  static String? _cachedAppId;
  
  /// Initialize Firebase Remote Config
  static Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      
      // Set default values
      await _remoteConfig!.setDefaults({
        'agora_app_id': '',
        'agora_temp_token': '',
      });
      
      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      debugPrint('✅ Firebase Remote Config initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize Remote Config: $e');
    }
  }
  
  /// Get App ID (tries local config first, then Firebase Remote Config)
  static String get appId {
    if (_cachedAppId != null && _cachedAppId!.isNotEmpty) {
      return _cachedAppId!;
    }
    
    // Try local config first (development)
    try {
      if (local.AgoraConfigLocal.appId.isNotEmpty) {
        _cachedAppId = local.AgoraConfigLocal.appId;
        return _cachedAppId!;
      }
    } catch (e) {
      // Local config doesn't exist, fall back to Remote Config
    }
    
    // Fall back to Firebase Remote Config
    try {
      final remoteAppId = _remoteConfig?.getString('agora_app_id') ?? '';
      if (remoteAppId.isNotEmpty) {
        _cachedAppId = remoteAppId;
        return _cachedAppId!;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get App ID from Remote Config: $e');
    }
    
    return '';
  }
  
  /// Get temporary token (for testing only)
  static String get tempToken {
    // Try local config first
    try {
      if (local.AgoraConfigLocal.tempToken.isNotEmpty) {
        return local.AgoraConfigLocal.tempToken;
      }
    } catch (e) {
      // Local config doesn't exist
    }
    
    // Fall back to Remote Config
    try {
      return _remoteConfig?.getString('agora_temp_token') ?? '';
    } catch (e) {
      return '';
    }
  }
  
  // Channel name prefix for support calls
  static const String supportChannelPrefix = 'support_call_';
  
  /// Check if Agora is configured
  static bool get isConfigured => appId.isNotEmpty;
  
  /// Force refresh from Firebase Remote Config
  static Future<void> refresh() async {
    try {
      await _remoteConfig?.fetchAndActivate();
      _cachedAppId = null; // Clear cache to force re-fetch
      debugPrint('✅ Remote Config refreshed');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh Remote Config: $e');
    }
  }
}
