#ifndef FLUTTER_PLUGIN_DESKTOP_SCREEN_RECORDER_PLUGIN_H_
#define FLUTTER_PLUGIN_DESKTOP_SCREEN_RECORDER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace desktop_screen_recorder {

class DesktopScreenRecorderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DesktopScreenRecorderPlugin();

  virtual ~DesktopScreenRecorderPlugin();

  // Disallow copy and assign.
  DesktopScreenRecorderPlugin(const DesktopScreenRecorderPlugin&) = delete;
  DesktopScreenRecorderPlugin& operator=(const DesktopScreenRecorderPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace desktop_screen_recorder

#endif  // FLUTTER_PLUGIN_DESKTOP_SCREEN_RECORDER_PLUGIN_H_
