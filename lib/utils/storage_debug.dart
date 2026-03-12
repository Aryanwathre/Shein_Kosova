import 'package:flutter/foundation.dart';
import 'package:shein_kosova/services/storage_service.dart';

/// Storage debugging and diagnostic utilities
class StorageDebug {
  static final StorageService _storage = StorageService();

  /// Print comprehensive storage diagnostics
  static void printDiagnostics() {
    final diagnostics = _storage.getDiagnostics();

    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║           STORAGE SYSTEM DIAGNOSTICS                   ║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('');
    debugPrint('📊 Status:');
    debugPrint('  Initialized: ${diagnostics['initialized']}');
    debugPrint('  Persistence Available: ${diagnostics['persistenceAvailable']}');
    debugPrint('  Platform: ${diagnostics['platform']}');
    debugPrint('');

    if (!diagnostics['persistenceAvailable']) {
      debugPrint('⚠️ Persistence Issue:');
      debugPrint('  Reason: ${diagnostics['failureReason']}');
      debugPrint('');
      debugPrint('💡 Troubleshooting:');
      debugPrint('  1. Check browser console for errors (F12)');
      debugPrint('  2. Disable private/incognito mode');
      debugPrint('  3. Check browser storage settings');
      debugPrint('  4. Try a different browser');
      debugPrint('  5. Clear browser cache and cookies');
      debugPrint('');
    }

    debugPrint('💾 Memory Cache:');
    debugPrint('  Size: ${diagnostics['memoryCacheSize']} items');
    if (diagnostics['memoryCacheSize'] > 0) {
      debugPrint('  Keys: ${diagnostics['memoryCacheKeys']}');
    } else {
      debugPrint('  (empty)');
    }
    debugPrint('');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Check if storage is working properly
  static Future<StorageHealthStatus> checkStorageHealth() async {
    try {
      // Test write
      const testKey = '__storage_health_test__';
      final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';

      await _storage.setString(testKey, testValue);

      // Test read
      final retrieved = await _storage.getString(testKey);

      // Cleanup
      await _storage.remove(testKey);

      if (retrieved == testValue) {
        return StorageHealthStatus.healthy;
      } else {
        return StorageHealthStatus.degraded;
      }
    } catch (e) {
      debugPrint('Storage health check error: $e');
      return StorageHealthStatus.failed;
    }
  }

  /// Print storage health report
  static Future<void> printHealthReport() async {
    final health = await checkStorageHealth();

    debugPrint('');
    debugPrint('🏥 Storage Health Report:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    switch (health) {
      case StorageHealthStatus.healthy:
        debugPrint('✅ HEALTHY - Storage working correctly');
        debugPrint('   Read/Write operations: FUNCTIONAL');
        debugPrint('   Data persistence: FUNCTIONAL');
        break;
      case StorageHealthStatus.degraded:
        debugPrint('⚠️  DEGRADED - Storage partially working');
        debugPrint('   Read/Write operations: FUNCTIONAL');
        debugPrint('   Data persistence: UNRELIABLE (may not survive page refresh)');
        break;
      case StorageHealthStatus.failed:
        debugPrint('❌ FAILED - Storage not working');
        debugPrint('   Using in-memory cache only (data lost on refresh)');
        debugPrint('   See diagnostics above for troubleshooting');
        break;
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');
  }

  /// Print recommended actions based on platform and storage status
  static Future<void> printRecommendations() async {
    final persistence = _storage.isPersistenceAvailable();

    debugPrint('');
    debugPrint('📋 Recommendations:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (kIsWeb) {
      if (persistence) {
        debugPrint('✅ Web: Storage is persistent');
        debugPrint('   - Tokens will be saved across sessions');
        debugPrint('   - User data will persist');
      } else {
        debugPrint('⚠️  Web: Storage is in-memory only');
        debugPrint('   - Data will be lost on page refresh');
        debugPrint('   - Users will be logged out after refresh');
        debugPrint('');
        debugPrint('   Recommended actions:');
        debugPrint('   1. Check if running in private/incognito mode');
        debugPrint('   2. Check browser storage settings');
        debugPrint('   3. Ensure cookies are enabled');
        debugPrint('   4. Try disabling browser extensions');
        debugPrint('   5. Check browser console (F12) for errors');
      }
    } else {
      debugPrint('✅ Mobile: Storage should work normally');
      debugPrint('   - Native SharedPreferences available');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');
  }

  /// Run complete diagnostic suite
  static Future<void> runFullDiagnostics() async {
    debugPrint('');
    debugPrint('🔍 Running Full Storage Diagnostics...');
    debugPrint('');

    printDiagnostics();
    await printHealthReport();
    await printRecommendations();
  }
}

enum StorageHealthStatus {
  healthy,
  degraded,
  failed,
}

