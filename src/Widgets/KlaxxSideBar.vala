public class Klaxxify.SideBar : Gtk.Box {
    public Gtk.FlowBox flowbox { get; set; }
    public Klaxxify.Image child { get; set; }
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

        var scrolled = new Gtk.ScrolledWindow () {
            child = flowbox
        };

        var data_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            halign = Gtk.Align.FILL
        };

        data_box.append (label);
        data_box.append (scrolled);

        add_placeholder = new Granite.Placeholder ("Add Items") {
            icon = new ThemedIcon ("insert-image"),
            halign = Gtk.Align.FILL,
            hexpand = false
        };

        hidden_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        hidden_stack.add_named (add_placeholder, "placeholder");
        hidden_stack.add_named (data_box, "images");
        append (hidden_stack);

        var photo_drop_point = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        this.add_controller (photo_drop_point);

        photo_drop_point.on_drop.connect ((val) => {
            if (val.type () == typeof (Gdk.FileList)) {
                ((Gdk.FileList) val).get_files ().foreach ((file) => {
                    bool is_false;
                    var content = ContentType.guess (file.get_path (), null, out is_false);
                    var mime = ContentType.get_mime_type (content);

                    if ("image" in mime) {
                        if (flowbox.get_last_child () == null) {
                            hidden_stack.visible_child_name = "images";
                        }
                        add_item (file.get_path ());
                        unused_files = add_to_unused (file.get_path ());
                        page.save_to_file (unused_files, sidebar_index);
                    } else {
                        print ("%s is not an image file.\n", file.get_path ());
                    }
                });
            } else {
                photo_drop_point.reject ();
            }

            return true;
        });

        var photo_return_point = new Gtk.DropTarget (typeof (Klaxxify.Image), Gdk.DragAction.MOVE);
        this.add_controller (photo_return_point);

        photo_return_point.on_drop.connect ((val, x, y) => {
            if (val.type () == typeof (Klaxxify.Image)) {
                var image_file = ((Klaxxify.Image) val).filename;
                var returned_img = new Klaxxify.Image (((Klaxxify.Image) val).texture, image_file) {
                    margin_start = 10,
                    margin_end = 10,
                    margin_top = 10,
                    margin_bottom = 10,
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                };
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
                child = (Klaxxify.Image) flowbox.get_child_at_pos ((int) x, (int) y).child;
                flowbox.set_data<Klaxxify.Image> ("dragged", child);
                return new Gdk.ContentProvider.for_value (child);
            }
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var fb = (Gtk.FlowBox) source.get_widget ();
            var dragged = fb.get_data<Klaxxify.Image> ("dragged");
            var child = new Gtk.WidgetPaintable (dragged);
            source.set_icon (child, 20, 20);
            drag.set_data<string> ("class", "sidebar");
            drag.set_data<string> ("in_sidebar", "false");
        });

        drag_source.drag_end.connect ((drag, del) => {
            if (del) {
                if (child.filename in unused_files && drag.get_data<string> ("in_sidebar") == "false") {
                    var arr = new GenericArray<string> ();
                    arr.data = unused_files;

                    uint source_index = 0;
                    while (arr.get (source_index) != child.filename) {
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

        var image = new Klaxxify.Image (texture, filename) {
            margin_start = 10,
            margin_end = 10,
            margin_top = 10,
            margin_bottom = 10,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
        };
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
}
