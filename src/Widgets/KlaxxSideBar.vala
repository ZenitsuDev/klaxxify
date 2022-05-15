public class Klaxxify.SideBar : Gtk.Box {
    public Gtk.FlowBox flowbox { get; set; }
    public Gtk.Image child { get; set; }
    public Gtk.Stack hidden_stack;
    private Granite.Placeholder add_placeholder;
    public string[] unused_files { get; set; }
    public int sidebar_index { get; set; }
    public Klaxxify.KlaxxPage page { get; set; }
    public Klaxxify.Window window { get; construct; }
    public SideBar (Klaxxify.Window window) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0,
            window: window
        );
    }

    public void connect_to_page (Klaxxify.KlaxxPage page) {
        this.page = page;
    }

    construct {
        var label = new Gtk.Label ("Klaxxify") {
            halign = Gtk.Align.START
        };
        label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);

        flowbox = new Gtk.FlowBox () {
            homogeneous = true,
            vexpand = true,
            valign = Gtk.Align.START,
            halign = Gtk.Align.FILL
        };

        var add_more_images = new Gtk.Button () {
            halign = Gtk.Align.END,
            can_focus = false,
            child = new Gtk.Image () {
                gicon = new ThemedIcon ("list-add-symbolic")
            }
        };
        add_more_images.add_css_class (Granite.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            width_request = 250,
            halign = Gtk.Align.END
        };
        top_box.append (label);
        top_box.append (add_more_images);

        var scrolled = new Gtk.ScrolledWindow () {
            child = flowbox
        };

        var data_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            halign = Gtk.Align.FILL
        };

        data_box.append (top_box);
        data_box.append (scrolled);

        add_placeholder = new Granite.Placeholder ("Add Items") {
            icon = new ThemedIcon ("insert-image"),
            halign = Gtk.Align.FILL,
            hexpand = false
        };

        var open_images = add_placeholder.append_button (
            new ThemedIcon ("document-import"),
            "Insert Images",
            "Insert images to be klaxxified"
        );

        hidden_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        hidden_stack.add_named (add_placeholder, "placeholder");
        hidden_stack.add_named (data_box, "images");
        append (hidden_stack);

        open_images.clicked.connect (add_to_sidebar);
        add_more_images.clicked.connect (add_to_sidebar);

        var photo_return_point = new Gtk.DropTarget (typeof (Gtk.Image), Gdk.DragAction.MOVE);
        this.add_controller (photo_return_point);

        photo_return_point.on_drop.connect ((val, x, y) => {
            if (val.type () == typeof (Gtk.Image)) {
                var image_file = ((Gtk.Image) val).get_data<string> ("filename");
                var returned_img = new Gtk.Image.from_paintable (((Gtk.Image) val).paintable) {
                    width_request = 100,
                    height_request = 100,
                    margin_start = 10,
                    margin_end = 10,
                    margin_top = 10,
                    margin_bottom = 10,
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                };
                returned_img.set_data<string> ("filename", image_file);
                returned_img.add_css_class (Granite.STYLE_CLASS_CARD);

                var fbcontainer = new Gtk.FlowBoxChild () {
                    child = returned_img,
                    width_request = 100,
                    height_request = 100,
                };

                if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                    flowbox.append (fbcontainer);
                    unused_files = add_to_unused (image_file);
                } else {
                    var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                    flowbox.insert (fbcontainer, fbchild.get_index ());
                    unused_files = add_to_unused (image_file, fbchild.get_index ());
                }
                page.save_to_file (unused_files, sidebar_index);
            } else {
                photo_return_point.reject ();
            }

            var drag = photo_return_point.get_current_drop ().get_drag ();
            if (drag.get_data<string> ("class") == "sidebar") {
                drag.set_data<string> ("in_sidebar", "true");
            }

            return true;
        });

        var drag_source = new Gtk.DragSource () {
            actions = Gdk.DragAction.MOVE
        };
        flowbox.add_controller (drag_source);

        drag_source.prepare.connect ((x, y) => {
            if (flowbox.get_child_at_pos ((int) x, (int) y) != null) {
                child = (Gtk.Image) flowbox.get_child_at_pos ((int) x, (int) y).child;
                flowbox.set_data<Gtk.Image> ("dragged", child);
                return new Gdk.ContentProvider.for_value (child);
            }
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var fb = (Gtk.FlowBox) source.get_widget ();
            var dragged = fb.get_data<Gtk.Image> ("dragged");
            dragged.width_request = 100;
            dragged.height_request = 100;
            var child = new Gtk.WidgetPaintable (dragged);
            source.set_icon (child, 20, 20);
            drag.set_data<string> ("class", "sidebar");
            drag.set_data<string> ("in_sidebar", "false");
        });

        drag_source.drag_end.connect ((drag, del) => {
            if (del) {
                if (child.get_data<string> ("filename") in unused_files && drag.get_data<string> ("in_sidebar") == "false") {
                    var arr = new GenericArray<string> ();
                    arr.data = unused_files;

                    uint source_index = 0;
                    while (arr.get (source_index) != child.get_data<string> ("filename")) {
                        source_index++;
                    }

                    arr.remove (arr.get (source_index));
                    unused_files = arr.data;
                }
                page.save_to_file (unused_files, sidebar_index);

                flowbox.remove (child);
                child = null;
            }
        });

    }

    public void load_unused_files (string unused, int index) {
        this.sidebar_index = index;
        unused_files = unused.split (",");
        foreach (var unused_file in unused_files) {
            add_item (unused_file);
        }
        hidden_stack.visible_child_name = "images";
    }

    public void add_item (string filename) {
        Gdk.Texture? texture = null;
        try {
            texture = Gdk.Texture.from_filename (filename);
        } catch (Error e) {
            critical ("%s\n", e.message);
        }

        var image = new Gtk.Image.from_paintable (texture) {
            width_request = 100,
            height_request = 100,
            margin_start = 10,
            margin_end = 10,
            margin_top = 10,
            margin_bottom = 10,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
        };
        image.set_data<string> ("filename", filename);
        image.add_css_class (Granite.STYLE_CLASS_CARD);

        var fbcontainer = new Gtk.FlowBoxChild () {
            child = image,
            width_request = 100,
            height_request = 100,
        };

        flowbox.append (fbcontainer);
    }

    public void clear_draggables () {
        while (flowbox.get_last_child () != null) {
            flowbox.remove (flowbox.get_last_child ());
        }
        hidden_stack.visible_child_name = "placeholder";
    }

    public string[] add_to_unused (string path, int index = -1) {
        var unused_array = new GenericArray<string> ();
        unused_array.data = unused_files;

        if (path in unused_array.data) {
            uint source_index = 0;
            while (unused_array.get (source_index) != path) {
                source_index++;
            }

            bool is_backward = (source_index < index);

            unused_array.remove (unused_array.get (source_index));
            if (index - (int) is_backward - 1 <= -1) {
                unused_array.add (path);
            } else {
                unused_array.insert (index - (int) is_backward - 1, path);
            }
        } else {
            unused_array.add (path);
        }

        return unused_array.data;
    }

    private void add_to_sidebar () {
        ListModel? image_files = null;
        var filter = new Gtk.FileFilter () {
            name = "Image files"
        };
        filter.add_mime_type ("image/*");

        var dialog = new Gtk.FileChooserNative ("Open Recent Klaxxify File", window, Gtk.FileChooserAction.OPEN, "Open", "Cancel") {
            select_multiple = true
        };

        dialog.add_filter (filter);
        dialog.show ();

        dialog.response.connect ((id) => {
            switch (id) {
                case Gtk.ResponseType.ACCEPT:
                    image_files = dialog.get_files ();
                    for (var file_index = 0; file_index < image_files.get_n_items (); file_index++) {
                        var image_file = (File) image_files.get_item (file_index);
                        if (image_files.get_item (file_index) != null) {
                            add_item (image_file.get_path ());
                            unused_files = add_to_unused (image_file.get_path ());
                            page.save_to_file (unused_files, sidebar_index);
                        } else {
                            critical ("%s cannot be processed.", image_file.get_basename ());
                        }
                    }
                    hidden_stack.visible_child_name = "images";
                    dialog.hide ();
                    break;
                case Gtk.ResponseType.CANCEL:
                    dialog.hide ();
                    break;
            }
            dialog.destroy ();
        });
    }
}
