//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <image_compress_plus_linux/image_compress_plus_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) image_compress_plus_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ImageCompressPlusLinuxPlugin");
  image_compress_plus_linux_plugin_register_with_registrar(image_compress_plus_linux_registrar);
}
