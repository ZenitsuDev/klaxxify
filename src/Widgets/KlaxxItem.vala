public class Klaxxify.KlaxxItem : Gtk.Widget {
    public Gtk.Box main_child { get; set; }
    public Gtk.FlowBox flowbox { get; set; }
    public string klaxx { get; set construct; }
    public int index { get; construct; }
    private Gtk.FlowBoxChild child;
    public Klaxxify.KlaxxPage page { get; construct; }
    private Gtk.FlowBoxChild highlighted_child;

    public KlaxxItem (Klaxxify.KlaxxPage page, string klaxx, int index) {
        Object (
            page: page,
            klaxx: klaxx,
            index: index
        );
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    ~KlaxxItem () {
        while (this.get_last_child () != null) {
            this.get_last_child ().unparent ();
        }
    }

    construct {
        var klaxx_items = klaxx.split (",");

        var klaxx_title = new Gtk.FlowBoxChild () { 
            child = new Gtk.Label (klaxx_items[0]),
            can_focus = false, 
            can_target = false,
            width_request = 100,
            vexpand = true
        };
        klaxx_title.add_css_class ("klaxx_no%s".printf (index.to_string ()));

        flowbox = new Gtk.FlowBox () {
            max_children_per_line = 20,
            hexpand = true,
            height_request = 100,
            homogeneous = true
        };

        for (var item_num = 0; item_num < klaxx_items.length - 1; item_num++) {
            Gdk.Texture? texture = null;
            try {
                texture = Gdk.Texture.from_filename (klaxx_items[item_num + 1]);
            } catch (Error e) {
                critical ("%s\n", e.message);
            }

            var image = new Klaxxify.Image (texture, klaxx_items[item_num + 1]);

            flowbox.append (image);
        }

        var drop_target = new Gtk.DropTarget (typeof (Klaxxify.Image), Gdk.DragAction.MOVE);
        flowbox.add_controller (drop_target);

        var drag_source = new Gtk.DragSource () {
            actions = Gdk.DragAction.MOVE
        };
        flowbox.add_controller (drag_source);

        drop_target.motion.connect ((x, y) => {
            if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                if (highlighted_child != null) {
                    highlighted_child.remove_css_class ("highlight_child");
                    highlighted_child = null;
                }
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                if (highlighted_child == null) {
                    highlighted_child = fbchild;
                    fbchild.add_css_class ("highlight_child");
                } else if (fbchild != highlighted_child) {
                    highlighted_child.remove_css_class ("highlight_child");
                    fbchild.add_css_class ("highlight_child");
                    highlighted_child = fbchild;
                }
            }

            return Gdk.DragAction.MOVE;
        });

        drop_target.enter.connect (() => {
            if (highlighted_child != null) {
                highlighted_child.add_css_class ("highlight_child");
            }
        });

        drop_target.leave.connect (() => {
            if (highlighted_child != null) {
                highlighted_child.remove_css_class ("highlight_child");
            }
        });

        drop_target.on_drop.connect ((source, val, x, y) => {
            var fb = (Gtk.FlowBox) source.get_widget ();
            var source_image = (Klaxxify.Image) val;
            var image = new Klaxxify.Image (source_image.texture, source_image.filename);

            if (highlighted_child != null) {
                highlighted_child.remove_css_class ("highlight_child");
            }

            if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                fb.append (image);
                klaxx_items = insert_item (klaxx_items, source_image.filename, klaxx_items.length);
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                fb.insert (image, fbchild.get_index ());
                klaxx_items = insert_item (klaxx_items, source_image.filename, fbchild.get_index ());
            }

            var drag = drop_target.get_current_drop ().get_drag ();
            if (drag.get_data<string> ("class") == klaxx_items[0]) {
                drag.set_data<bool> ("drop_same", true);
            }

            page.save_to_file (klaxx_items, index);

            return true;
        });

        drag_source.prepare.connect ((x, y) => {
            if (flowbox.get_child_at_pos ((int) x, (int) y) != null) {
                child = flowbox.get_child_at_pos ((int) x, (int) y);
                flowbox.set_data<Klaxxify.Image> ("dragged", (Klaxxify.Image) child.child);
                return new Gdk.ContentProvider.for_value ((Klaxxify.Image) child.child);
            }
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var fb = (Gtk.FlowBox) source.get_widget ();
            var dragged = fb.get_data<Klaxxify.Image> ("dragged");
            var child = new Gtk.WidgetPaintable (dragged);
            source.set_icon (child, 20, 20);
            drag.set_data<string> ("class", klaxx_items[0]);
            drag.set_data<bool> ("drop_same", false);
        });

        drag_source.drag_end.connect ((source, drag, del) => {
            if (del) {
                if (((Klaxxify.Image) child.child).filename in klaxx_items && !(drag.get_data<bool> ("drop_same"))) {
                    var arr = new GenericArray<string> ();
                    arr.data = klaxx_items;

                    uint source_index = 0;
                    while (arr.get (source_index) != ((Klaxxify.Image) child.child).filename) {
                        source_index++;
                    }

                    arr.remove (arr.get (source_index));
                    klaxx_items = arr.data;
                }

                flowbox.remove (child);
                child = null;

                page.save_to_file (klaxx_items, index);
            }
        });

        main_child = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 20,
            margin_end = 20,
            margin_top = 20
        };
        main_child.append (klaxx_title);
        main_child.append (flowbox);
        main_child.add_css_class (Granite.STYLE_CLASS_CARD);
        main_child.set_parent (this);
    }

    public string[] insert_item (string[] klaxx_items, string filename, int index) {
        var klaxx_array = new GenericArray<string> ();
        klaxx_array.data = klaxx_items;

        if (filename in klaxx_array.data) {
            uint source_index = 0;
            while (klaxx_array.get (source_index) != filename) {
                source_index++;
            }

            bool is_backward = (source_index < index);

            klaxx_array.remove (klaxx_array.get (source_index));
            klaxx_array.insert (index - (int) is_backward, filename);
        } else {
            klaxx_array.length = klaxx_array.length + 1;
            klaxx_array.insert (index, filename);

            for (var iter = 0; iter < klaxx_array.length; iter++) {
                if (klaxx_array.get (iter) == null) {
                    klaxx_array.remove_index (iter);
                }
            }
        }

        return klaxx_array.data;
    }
}
