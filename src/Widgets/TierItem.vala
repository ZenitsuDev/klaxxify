public class Klaxxify.TierItem : Gtk.Widget {
    public Gtk.Box main_child { get; set; }
    public Gtk.FlowBox flowbox { get; set; }
    public string tier { get; set construct; }
    public int index { get; construct; }
    private Gtk.FlowBoxChild child;
    public Klaxxify.TierPage page { get; construct; }

    public TierItem (Klaxxify.TierPage page, string tier, int index) {
        Object (
            page: page,
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

        var drag_source = new Gtk.DragSource () {
            actions = Gdk.DragAction.MOVE
        };
        flowbox.add_controller (drag_source);

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
                tier_items = insert_item (tier_items, file, tier_items.length);
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                fb.insert (image, fbchild.get_index ());
                tier_items = insert_item (tier_items, file, fbchild.get_index ());
            }

            var drag = drop_target.get_current_drop ().get_drag ();
            if (drag.get_data<string> ("class") == tier_items[0]) {
                drag.set_data<string> ("drop_same", "true");
            }

            must_save (tier_items);

            return true;
        });

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
            drag.set_data<string> ("class", tier_items[0]);
            drag.set_data<string> ("drop_same", "false");
        });

        drag_source.drag_end.connect ((source, drag, del) => {
            if (del) {
                if (((Gtk.Image) child.child).file in tier_items && drag.get_data<string> ("drop_same") == "false") {
                    var arr = new GenericArray<string> ();
                    arr.data = tier_items;

                    uint source_index = 0;
                    while (arr.get (source_index) != ((Gtk.Image) child.child).file) {
                        source_index++;
                    }

                    arr.remove (arr.get (source_index));
                    tier_items = arr.data;
                }

                flowbox.remove (child);
                child = null;

                must_save (tier_items);
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
        var klaxx_array = new GenericArray<string> ();
        klaxx_array.data = tier_items;

        if (filename in klaxx_array.data) {
            uint source_index = 0;
            while (klaxx_array.get (source_index) != filename) {
                source_index++;
            }

            // bool is_backward = (source_index < index);
            bool is_backward;
            if (source_index < index) {
                is_backward = true;
            } else if (source_index == index) {
                is_backward = false;
            } else {
                is_backward = false;
            }

            print ("Source: %s Target: %s\n", source_index.to_string (), index.to_string ());

            klaxx_array.remove (klaxx_array.get (source_index));
            klaxx_array.insert (index - (int) is_backward, filename);
        } else {
            klaxx_array.length = klaxx_array.length + 1;
            klaxx_array.insert (index, filename);
            klaxx_array.remove (null);
        }

        return klaxx_array.data;
    }

    public signal void must_save (string[] array) {
        string second_degree_main = "";
        for (int second_degree = 0; second_degree < array.length; second_degree++) {
            second_degree_main = string.join (",", second_degree_main, array[second_degree]);
        }

        second_degree_main = (string) second_degree_main.data[1:];
        page.content[index] = second_degree_main;

        string first_degree_main = "";
        for (int first_degree = 0; first_degree < page.content.length; first_degree++) {
            first_degree_main = string.join ("\n", first_degree_main, page.content[first_degree]);
        }

        first_degree_main = (string) first_degree_main.data[1:];
        try {
            page.file.replace_contents (first_degree_main.data, null, false, GLib.FileCreateFlags.NONE, null, null);
        } catch ( GLib.Error e ) {
            GLib.error (e.message);
        }
    }
}
