public class Klaxxify.TierPage : Gtk.Widget {
    public File file { get; set construct; }
    public string tier_name { get; set construct; }
    public Klaxxify.Window window { get; construct; }
    public Gtk.Box main_box { get; set; }
    private bool is_new { get; set; }
    public string[] content { get; set; }

    public TierPage (Klaxxify.Window window, string name) {
        Object (
            window: window,
            tier_name: name
        );
    }

    public TierPage.from_file (Klaxxify.Window window, File file) {
        Object (
            window: window,
            file: file
        );
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    ~TierPage () {
        while (this.get_last_child () != null) {
            this.get_last_child ().unparent ();
        }
    }

    construct {
        if (file != null) {
            try {
		        uint8[] contents;
		        string etag_out;

		        file.load_contents (null, out contents, out etag_out);

		        content = ((string) contents).split ("\n");
		        tier_name = content[0];
		        is_new = false;
	        } catch (Error e) {
		        print ("Error: %s\n", e.message);
	        }
        } else {
            content = (string[]) string.join ("\n", tier_name, "S", "A", "B", "C").split ("\n");
            is_new = true;
        }

        window.title_changed.connect ((new_title) => {
            content[0] = new_title;
        });

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            vexpand = true,
            width_request = 600
        };
        main_box.set_parent (this);

        load_tier (content);
    }

    public void load_tier (string[] content) {
        var tier_num = 1;
        while (tier_num < (content.length - (int) !is_new) && content[tier_num] != "&&&&&UnusedFiles&&&&&") {
            var tier_item = new Klaxxify.TierItem (this, content[tier_num], tier_num);

            main_box.append (tier_item);
            tier_num++;
        }
    }
}
