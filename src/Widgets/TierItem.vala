public class Klaxxify.TierItem : Gtk.Widget {
    public Gtk.Box main_child { get; set; }
    public Gtk.FlowBox flowbox { get; set; }
    public string tier { get; set construct; }
    public int index { get; construct; }
    private Gtk.Image child;
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
            column_spacing = 5,
            row_spacing = 5,
            max_children_per_line = 20,
            hexpand = true,
            height_request = 100,
            homogeneous = true
        };

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
            var paintable = sidebarimage.get_paintable ();
            var image = new Gtk.Image.from_paintable (paintable) {
                width_request = sidebarimage.width_request,
                height_request = sidebarimage.height_request,
            };

            if (flowbox.get_data<Gtk.FlowBoxChild> ("highlighted") != null) {
                flowbox.get_data<Gtk.FlowBoxChild> ("highlighted").remove_css_class ("highlight_child");
            }

            if (flowbox.get_child_at_pos ((int) x, (int) y) == null) {
                fb.append (image);
            } else {
                var fbchild = flowbox.get_child_at_pos ((int) x, (int) y);
                fb.insert (image, fbchild.get_index ());
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
}
