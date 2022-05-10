public class Klaxxify.Window : Gtk.ApplicationWindow {
    public signal void title_changed (string title);
    public Granite.HeaderLabel title_label { get; set; }
    private bool is_in_klaxx = false;
    public Window (Klaxxify.Application app) {
        Object (application: app);
    }

    construct {
        var titlebar = new Gtk.Label ("") {
            visible = false
        };
        set_titlebar (titlebar);

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        var return_to_main = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            halign = Gtk.Align.START,
            visible = false
        };

        title_label = new Granite.HeaderLabel ("") {
            halign = Gtk.Align.CENTER,
            hexpand = true
        };

        var title_entry = new Gtk.Entry () {
            width_request = 250,
            halign = Gtk.Align.CENTER
        };

        var title_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        title_stack.add_named (title_label, "title");
        title_stack.add_named (title_entry, "entry");

        var edit_title_controller = new Gtk.GestureClick ();
        title_stack.add_controller (edit_title_controller);

        edit_title_controller.pressed.connect (() => {
            if (is_in_klaxx) {
                title_stack.visible_child_name = "entry";
            }
        });

        title_entry.activate.connect (() => {
            title_stack.visible_child_name = "title";
            title_changed (title_entry.get_text ());
        });

        title_entry.buffer.inserted_text.connect (() => {
            title_label.label = title_entry.get_text ();
            title_changed (title_entry.get_text ());
        });

        var tier_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tier_header.add_css_class ("titlebar");
        tier_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        tier_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        tier_header.append (start_window_controls);
        tier_header.append (return_to_main);
        tier_header.append (title_stack);

        var placeholder = new Granite.Placeholder ("Create Klaxxify List") {
            description = "Create a new blank klaxxify list.",
            icon = new ThemedIcon ("com.github.zenitsudev.klaxxify")
        };

        var open_last = placeholder.append_button (
            new ThemedIcon ("document-import"),
            "Open Recent",
            "Open recently created tier list."
        );

        var create_new = placeholder.append_button (
            new ThemedIcon ("document-new"),
            "Create New Tier List",
            "Create a new Rank tier list."
        );

        var stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN
        };
        stack.add_named (placeholder, "main");

        var scrolled = new Gtk.ScrolledWindow () {
            child = stack,
            vexpand = true
        };

        var tier_handle = new Gtk.WindowHandle () {
            child = tier_header
        };

        var main_page = new Gtk.Grid () {
            hexpand = true
        };
        main_page.add_css_class (Granite.STYLE_CLASS_VIEW);
        main_page.attach (tier_handle, 0, 0);
        main_page.attach (scrolled, 0, 1);

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END) {
            halign = Gtk.Align.END
        };
        end_window_controls.add_css_class ("titlebar");
        end_window_controls.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_window_controls.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        var draggables_sidebar = new Klaxxify.SideBar () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true,
            halign = Gtk.Align.FILL,
            width_request = 250
        };

        var sidebar_handle = new Gtk.WindowHandle () {
            child = end_window_controls
        };

        var draggables = new Gtk.Grid () {
            width_request = 250
        };
        draggables.attach (sidebar_handle, 0, 0);
        draggables.attach (draggables_sidebar, 0, 1);

        var flap = new Adw.Flap () {
            content = main_page,
            flap = draggables,
            separator = new Gtk.Separator (Gtk.Orientation.VERTICAL),
            flap_position = Gtk.PackType.END,
            reveal_flap = false
        };

        child = flap;

        default_width = 960;
        default_height = 640;

        open_last.clicked.connect (() => {
            File? file = null;
            var filter = new Gtk.FileFilter () {
                name = "TLRank files"
            };
            filter.add_suffix ("tlrank");

            var dialog = new Gtk.FileChooserDialog ("Open Recent Rank File", this, Gtk.FileChooserAction.OPEN, "Open", Gtk.ResponseType.ACCEPT, "Cancel", Gtk.ResponseType.CANCEL);

            dialog.add_filter (filter);
            dialog.show ();
            dialog.response.connect ((id) => {
                switch (id) {
                    case Gtk.ResponseType.ACCEPT:
                        file = dialog.get_file ();
                        if (file != null) {
                            var tier_page = new Klaxxify.TierPage.from_file (this, file);
                            stack.add_named (tier_page, "tier");
                            stack.visible_child_name = "tier";
                            flap.reveal_flap = true;
                            title_label.label = tier_page.tier_name;
                            title_entry.buffer.set_text ((uint8[]) title_label.label);
                            is_in_klaxx = true;
                            return_to_main.visible = true;
                        } else {
                            critical ("%s cannot be processed.", file.get_basename ());
                        }
                        dialog.hide ();
                        break;
                    case Gtk.ResponseType.CANCEL:
                        dialog.hide ();
                        break;
                }
                dialog.destroy ();
            });
        });

        create_new.clicked.connect (() => {
            var tier_page = new Klaxxify.TierPage (this, "New Tier List");
            stack.add_named (tier_page, "tier");
            stack.visible_child_name = "tier";
            flap.reveal_flap = true;
            title_label.label = tier_page.tier_name;
            title_entry.buffer.set_text ((uint8[]) title_label.label);
            is_in_klaxx = true;
            return_to_main.visible = true;
        });

        return_to_main.clicked.connect (() => {
            stack.visible_child_name = "main";
            if (stack.get_last_child () is Klaxxify.TierPage) {
                stack.remove (stack.get_last_child ());
                draggables_sidebar.clear_draggables ();
            }
            flap.reveal_flap = false;
            title_label.label = "";
            title_stack.visible_child_name = "title";
            is_in_klaxx = false;
            return_to_main.visible = false;
        });

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_path ("/home/owendavid/rank/app.css");
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
