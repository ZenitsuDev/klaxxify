public class Klaxxify.TierPage : Gtk.Widget {
    public File file { get; set construct; }
    public string tier_name { get; set construct; }
    public Gtk.Box main_box { get; set; }
    private bool is_new { get; set; }

    public TierPage (string name) {
        Object (tier_name: name);
    }

    public TierPage.from_file (File file) {
        Object (file: file);
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
        string[] content;
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
            content += tier_name;
            content += "S";
            content += "A";
            content += "B";
            content += "C";
            is_new = true;
        }

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
            var tier_item = new Klaxxify.TierItem (content[tier_num], tier_num);
            main_box.append (tier_item);
            tier_num++;
        }
    }
}




















// var f = File.new_for_uri ("https://i.ytimg.com/vi/4oBpaBEMBIM/maxresdefault.jpg");
//         var texture = Gdk.Texture.from_file (f);
//         var image = new Gtk.Image.from_paintable (texture) {
//             hexpand = true,
//             vexpand = true
//         };
//         image.set_parent (this);
