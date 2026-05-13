import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'desktop_screen_recorder_method_channel.dart';

abstract class DesktopScreenRecorderPlatform extends PlatformInterface {
  /// Constructs a DesktopScreenRecorderPlatform.
  DesktopScreenRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static DesktopScreenRecorderPlatform _instance = MethodChannelDesktopScreenRecorder();

  /// The default instance of [DesktopScreenRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelDesktopScreenRecorder].
  static DesktopScreenRecorderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DesktopScreenRecorderPlatform] when
  /// they register themselves.
  static set instance(DesktopScreenRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
