project(
    'com.github.zenitsudev.klaxxify',
    'vala', 'c',
    version: '1.0'
)

subdir('data')

meson.add_install_script('meson/post_install.py')

executable(
    meson.project_name(),

    gresource,

    'src/Application.vala',
    'src/Window.vala',
    'src/Widgets/KlaxxPage.vala',
    'src/Widgets/KlaxxItem.vala',
    'src/Widgets/KlaxxSideBar.vala',

    dependencies : [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('libadwaita-1')
    ],
    install: true
)
