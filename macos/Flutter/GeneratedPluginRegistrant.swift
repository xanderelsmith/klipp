//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import desktop_drop
import desktop_screen_recorder
import file_picker
import path_provider_foundation
import record_macos
import screen_retriever_macos
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DesktopDropPlugin.register(with: registry.registrar(forPlugin: "DesktopDropPlugin"))
  DesktopScreenRecorderPlugin.register(with: registry.registrar(forPlugin: "DesktopScreenRecorderPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  RecordMacOsPlugin.register(with: registry.registrar(forPlugin: "RecordMacOsPlugin"))
  ScreenRetrieverMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
