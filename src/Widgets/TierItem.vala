public class Klaxxify.TierItem : Gtk.Widget {
    public Gtk.Box main_child { get; set; }
    public Gtk.FlowBox flowbox { get; set; }
    public string tier { get; set construct; }
    public int index { get; construct; }
    private Gtk.FlowBoxChild child;
    public TierItem (string tier, int index) {
        Object (
            tier: tier,
            index: index
        );
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    ~TierItem () {
        while (this.get_last_child () != null) {
            this.get_last_child ().unparent ();
        }
    }

    construct {
        var tier_items = tier.split (",");

        var tier_title = new Gtk.FlowBoxChild () { 
            child = new Gtk.Label (tier_items[0]),
            can_focus = false, 
            can_target = false,
            width_request = 100,
            vexpand = true
        };
        tier_title.add_css_class ("tier_no%s".printf (index.to_string ()));

        flowbox = new Gtk.FlowBox () {
            max_children_per_line = 20,
            hexpand = true,
            height_request = 100,
            homogeneous = true
        };

        for (var item_num = 0; item_num < tier_items.length - 1; item_num++) {
            var image = new Gtk.Image.from_file (tier_items[item_num + 1]) {
                width_request = 100,
                height_request = 100
            };

            flowbox.append (image);
        }

        var drop_target = new Gtk.DropTarget (typeof (Gtk.Image), Gdk.DragAction.MOVE);
        flowbox.add_controller (drop_target);

        drop_target.motion.connect ((x, y) => {
            if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") != null) {
                    flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").remove_css_class ("highlight_child");
                    flowbox.set_data<Gtk.FlowBoxChild> ("highlighted", null);
                }
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") == null) {
                    flowbox.set_data<Gtk.FlowBoxChild> ("highlighted", fbchild);
                    fbchild.add_css_class ("highlight_child");
                } else if (fbchild != flowbox.get_data<Gtk.FlowBoxChild> ("highlighted")) {
                    flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").remove_css_class ("highlight_child");
                    fbchild.add_css_class ("highlight_child");
                    flowbox.set_data<Gtk.FlowBoxChild> ("highlighted", fbchild);
                }
            }

            return Gdk.DragAction.MOVE;
        });

        drop_target.enter.connect (() => {
            if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") != null) {
                flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").add_css_class ("highlight_child");
            }
        });

        drop_target.leave.connect (() => {
            if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") != null) {
                flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").remove_css_class ("highlight_child");
            }
        });

        drop_target.on_drop.connect ((source, val, x, y) => {
            var fb = (Gtk.FlowBox) source.get_widget ();
            var sidebarimage = (Gtk.Image) val;
            var file = sidebarimage.file;
            var image = new Gtk.Image.from_file (file) {
                width_request = sidebarimage.width_request,
                height_request = sidebarimage.height_request,
            };

            if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") != null) {
                flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").remove_css_class ("highlight_child");
            }

            if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                fb.append (image);
                tier_items = insert_item (tier_items, file, tier_items.length + 1);
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                fb.insert (image, fbchild.get_index ());
                tier_items = insert_item (tier_items, file, fbchild.get_index () + 1);
            }

            foreach (var item in tier_items) {
                print ("%s\n", item);
            }

            return true;
        });

        var drag_source = new Gtk.DragSource () {
            actions = Gdk.DragAction.MOVE
        };
        flowbox.add_controller (drag_source);

        drag_source.prepare.connect ((x, y) => {
            if (flowbox.get_child_at_pos ((int) x, (int) y) != null) {
                child = flowbox.get_child_at_pos ((int) x, (int) y);
                flowbox.set_data<Gtk.Image> ("dragged", (Gtk.Image) child.child);
                return new Gdk.ContentProvider.for_value ((Gtk.Image) child.child);
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

        main_child = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 20,
            margin_end = 20,
            margin_top = 20
        };

        main_child.append (tier_title);
        main_child.append (flowbox);
        main_child.add_css_class (Granite.STYLE_CLASS_CARD);
        main_child.set_parent (this);
    }

    public string[] insert_item (string[] tier_items, string filename, int index) {
        var klaxx_array = tier_items;

        print ("ITO YON: %s\n", filename);

        if (!(filename in tier_items)) {
            klaxx_array.resize (tier_items.length + 1);

            for (var i = klaxx_array.length - 1; i >= index; i--) {
                klaxx_array[i] = klaxx_array[i - 1];
            }

            klaxx_array[index - 1] = filename;
        } else {
            for (var source_index = 0; source_index < klaxx_array.length; source_index++) {
                if (klaxx_array[source_index] == filename) {
                    var array = new GenericArray <string> ();
                    array.data = klaxx_array;
                    array.remove_index (source_index);
                    array.insert (index, filename);

                    klaxx_array = array.data;
                }
            }
        }

        return klaxx_array;
    }
}
