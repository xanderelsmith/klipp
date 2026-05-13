import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder_platform_interface.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDesktopScreenRecorderPlatform
    with MockPlatformInterfaceMixin
    implements DesktopScreenRecorderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DesktopScreenRecorderPlatform initialPlatform = DesktopScreenRecorderPlatform.instance;

  test('$MethodChannelDesktopScreenRecorder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDesktopScreenRecorder>());
  });

  test('getPlatformVersion', () async {
    DesktopScreenRecorder desktopScreenRecorderPlugin = DesktopScreenRecorder();
    MockDesktopScreenRecorderPlatform fakePlatform = MockDesktopScreenRecorderPlatform();
    DesktopScreenRecorderPlatform.instance = fakePlatform;

    expect(await desktopScreenRecorderPlugin.getPlatformVersion(), '42');
  });
}
