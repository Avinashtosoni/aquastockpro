import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// A service to monitor network connectivity status.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  StreamController<bool>? _connectionStatusController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  bool get isOnline => _isOnline;

  Stream<bool> get connectionStream {
    _connectionStatusController ??= StreamController<bool>.broadcast();
    return _connectionStatusController!.stream;
  }

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkAndUpdateConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        if (_isOnline != wasOnline) {
          _connectionStatusController?.add(_isOnline);
          debugPrint('ConnectivityService: Connection changed to ${_isOnline ? "Online" : "Offline"}');
        }
      },
    );
    
    debugPrint('ConnectivityService initialized: ${_isOnline ? "Online" : "Offline"}');
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity - $e');
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _connectionStatusController?.add(_isOnline);
      debugPrint('ConnectivityService: Status manually set to ${_isOnline ? "Online" : "Offline"}');
    }
  }

  Future<bool> checkConnectivity() async {
    await _checkAndUpdateConnectivity();
    return _isOnline;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController?.close();
  }
}
