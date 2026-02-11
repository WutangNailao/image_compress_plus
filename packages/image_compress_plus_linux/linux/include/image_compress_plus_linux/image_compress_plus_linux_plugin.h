#ifndef IMAGE_COMPRESS_PLUS_LINUX_PLUGIN_H_
#define IMAGE_COMPRESS_PLUS_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#define IMAGE_COMPRESS_PLUS_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), image_compress_plus_linux_plugin_get_type(), \
                              ImageCompressPlusLinuxPlugin))

typedef struct _ImageCompressPlusLinuxPlugin ImageCompressPlusLinuxPlugin;
typedef struct _ImageCompressPlusLinuxPluginClass ImageCompressPlusLinuxPluginClass;

GType image_compress_plus_linux_plugin_get_type();

void image_compress_plus_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // IMAGE_COMPRESS_PLUS_LINUX_PLUGIN_H_
