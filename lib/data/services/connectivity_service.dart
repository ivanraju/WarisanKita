import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service that monitors device connectivity status and broadcasts changes.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;
  ConnectivityResult _primaryResult = ConnectivityResult.wifi;

  /// Whether the device currently has an active network connection.
  bool get isOnline => _isOnline;

  /// Whether the device is currently offline.
  bool get isOffline => !_isOnline;

  /// Whether the device was previously offline in this session (useful for "Back online" transition).
  bool get wasOffline => _wasOffline;

  /// Primary connectivity type (wifi, mobile, ethernet, none, etc.)
  ConnectivityResult get primaryResult => _primaryResult;

  ConnectivityService({Connectivity? connectivity, bool initialOnline = true})
      : _connectivity = connectivity ?? Connectivity(),
        _isOnline = initialOnline {
    _initConnectivity();
  }

  void _initConnectivity() {
    try {
      _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      checkConnectivity();
    } catch (e) {
      debugPrint('ConnectivityService: Failed to attach connectivity listener ($e). Defaulting to online.');
    }
  }

  /// Manually checks and updates the connectivity status.
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: checkConnectivity error ($e). Keeping current state ($_isOnline).');
      return _isOnline;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    final primary = results.isNotEmpty ? results.first : ConnectivityResult.none;

    if (hasConnection != _isOnline) {
      if (!hasConnection) {
        _wasOffline = true;
      }
      _isOnline = hasConnection;
      _primaryResult = primary;
      notifyListeners();
    } else if (primary != _primaryResult) {
      _primaryResult = primary;
      notifyListeners();
    }
  }

  /// Manually override connectivity state (primarily for automated testing).
  @visibleForTesting
  void setOnlineForTesting(bool online) {
    if (_isOnline != online) {
      if (!online) {
        _wasOffline = true;
      }
      _isOnline = online;
      _primaryResult = online ? ConnectivityResult.wifi : ConnectivityResult.none;
      notifyListeners();
    }
  }

  /// Resets the `wasOffline` flag once the online recovery alert has been consumed.
  void clearWasOffline() {
    if (_wasOffline) {
      _wasOffline = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
