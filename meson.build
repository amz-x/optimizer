project(
  'com.github.hannesschulze.optimizer',
  'c', 'vala',
  version: '1.2.1',
  meson_version: '>= 0.59.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

use_fallback_theme = get_option('use_fallback_theme')

subdir('src')

optimizer_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('granite-9', default_options: ['demo=false', 'introspection=false']),
  dependency('gtk4', version: '>= 4.22'),
  dependency('libgtop-2.0'),
  meson.get_compiler('c').find_library('m'),
  meson.get_compiler('vala').find_library('posix'),
]

optimizer_sources += gnome.compile_resources(
  'optimizer-resources',
  join_paths('data', meson.project_name() + '.gresource.xml'),
  source_dir: 'data',
  c_name: 'optimizer'
)

executable(
  meson.project_name(),
  optimizer_sources,
  dependencies: optimizer_deps,
  install: true,
  vala_args: [
    '--vapidir=' + meson.project_source_root() / 'vapi',
    '--target-glib=2.74'
  ]
)

subdir('data')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)
