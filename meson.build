project(
    'com.github.zenitsudev.klaxxify',
    'vala', 'c',
    version: '1.0'
)

subdir('data')

meson.add_install_script('meson/post_install.py')

executable(
    meson.project_name(),

    'Application.vala',
    'Window.vala',
    'src/Widgets/TierPage.vala',
    'src/Widgets/TierItem.vala',
    'src/Widgets/SideBar.vala',

    dependencies : [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('libadwaita-1')
    ],
    install: true
)
