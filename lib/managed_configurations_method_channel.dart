import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:managed_configurations/managed_configurations.dart';
import 'package:managed_configurations/managed_configurations_platform_interface.dart';

const String getManagedConfiguration = "getManagedConfigurations";
const String reportKeyedAppState = "reportKeyedAppState";

/// An implementation of [ManagedConfigurationsPlatform] that uses method channels.
class MethodChannelManagedConfigurations extends ManagedConfigurationsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('managed_configurations');

  static const MethodChannel _managedConfigurationMethodChannel =
      MethodChannel('managed_configurations_method');
  static const EventChannel _managedConfigurationEventChannel =
      EventChannel('managed_configurations_event');

  static final StreamController<Map<String, dynamic>?>
      _mangedConfigurationsController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static final Stream<Map<String, dynamic>?> _managedConfigurationsStream =
      _mangedConfigurationsController.stream.asBroadcastStream();

  /// Returns a broadcast stream which calls on managed app configuration changes
  /// Json will be returned
  /// Call [dispose] when stream is not more necessary
  @override
  Stream<Map<String, dynamic>?> get mangedConfigurationsStream {
    _actionApplicationRestrictionsChangedSubscription ??=
        _managedConfigurationEventChannel
            .receiveBroadcastStream()
            .listen((newManagedConfigurations) {
      if (newManagedConfigurations != null) {
        _mangedConfigurationsController
            .add(json.decode(newManagedConfigurations));
      }
    });
    return _managedConfigurationsStream;
  }

  StreamSubscription<dynamic>?
      _actionApplicationRestrictionsChangedSubscription;

  /// Returns managed app configurations as Json
  @override
  Future<Map<String, dynamic>?> get getManagedConfigurations async {
    final String? rawJson = await _managedConfigurationMethodChannel
        .invokeMethod(getManagedConfiguration);
    if (rawJson != null) {
      return json.decode(rawJson);
    } else {
      return null;
    }
  }

  /// This method is only supported on Android Platform
  @override
  Future<void> reportKeyedAppStates(
    String key,
    Severity severity,
    String? message,
    String? data,
  ) async {
    if (Platform.isAndroid) {
      await _managedConfigurationMethodChannel.invokeMethod(
        reportKeyedAppState,
        {
          'key': key,
          'severity': severity.toInteger(),
          'message': message,
          'data': data,
        },
      );
    }
  }

  @override
  void dispose() {
    _actionApplicationRestrictionsChangedSubscription?.cancel();
  }
}
