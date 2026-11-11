project('car', 'c',
  version: '4.0',
  default_options: ['warning_level=3', 'c_std=c23'])

add_project_arguments(
  '-DCAR_VERSION="@0@"'.format(meson.project_version()),
  language : 'c',
)

fun_proj = subproject('func', default_options: ['default_library=shared'])
fun_dep = fun_proj.get_variable('func_dep')

rac_inc = include_directories('src/rac/include')

rac_lib = shared_library('rac',
  'src/rac/handle.c',
  include_directories: rac_inc,
  dependencies: fun_dep,
  version: meson.project_version(),
  soversion: '4',
  install: true)

rac_dep = declare_dependency(
  link_with: rac_lib,
  include_directories: rac_inc)

executable('car',
  'src/main.c',
  dependencies: [fun_dep, rac_dep],
  install: true)
