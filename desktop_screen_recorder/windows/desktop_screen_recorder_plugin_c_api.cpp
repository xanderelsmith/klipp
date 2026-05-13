#include "include/desktop_screen_recorder/desktop_screen_recorder_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "desktop_screen_recorder_plugin.h"

void DesktopScreenRecorderPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  desktop_screen_recorder::DesktopScreenRecorderPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
