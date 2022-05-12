public class Klaxxify.SideBar : Gtk.Box {
    public Gtk.FlowBox flowbox { get; set; }
    public Gtk.Image child { get; set; }
    private Gtk.Stack hidden_stack;
    private Granite.Placeholder add_placeholder;
    public SideBar () {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );
    }

    construct {
        var label = new Gtk.Label ("Klaxxify") {
            halign = Gtk.Align.START
        };
        label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);

        flowbox = new Gtk.FlowBox () {
            homogeneous = true,
            vexpand = true,
            row_spacing = 10,
            column_spacing = 10,
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

        add_placeholder = new Granite.Placeholder ("Add Images") {
            description = "Drag image files here",
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
                    } else {
                        print ("%s is not an image file.\n", file.get_path ());
                    }
                });
            } else {
                photo_drop_point.reject ();
            }

            return true;
        });

        var photo_return_point = new Gtk.DropTarget (typeof (Gtk.Image), Gdk.DragAction.MOVE);
        this.add_controller (photo_return_point);

        photo_return_point.on_drop.connect ((val, x, y) => {
            if (val.type () == typeof (Gtk.Image)) {
                var paintable = ((Gtk.Image) val).file;
                var returned_img = new Gtk.Image.from_file (paintable) {
                    width_request = 100,
                    height_request = 100
                };
                returned_img.add_css_class (Granite.STYLE_CLASS_CARD);

                if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                    flowbox.append (returned_img);
                } else {
                    var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                    flowbox.insert (returned_img, fbchild.get_index ());
                }
            } else {
                photo_drop_point.reject ();
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
                flowbox.set_data<string> ("from_tier", "sidebar");
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
        });

        drag_source.drag_end.connect ((drag, del) => {
            if (del) {
                flowbox.remove (child);
                child = null;
            }
        });

    }

    public void add_item (string filename) {
        // var file = File.new_for_path (filename);
        // Gdk.Texture texture = null;
        // try {
        //     texture = Gdk.Texture.from_file (file);
        // } catch (Error e) {
        //     print ("%s\n", e.message);
        // }

        var image = new Gtk.Image.from_file (filename) {
            width_request = 100,
            height_request = 100
        };
        image.add_css_class (Granite.STYLE_CLASS_CARD);

        flowbox.append (image);
    }

    public void clear_draggables () {
        while (flowbox.get_last_child () != null) {
            flowbox.remove (flowbox.get_last_child ());
        }
        hidden_stack.visible_child_name = "placeholder";
    }
}
