//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_screen_recorder/desktop_screen_recorder_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) desktop_screen_recorder_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopScreenRecorderPlugin");
  desktop_screen_recorder_plugin_register_with_registrar(desktop_screen_recorder_registrar);
}
