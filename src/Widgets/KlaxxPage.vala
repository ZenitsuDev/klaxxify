public class Klaxxify.KlaxxPage : Gtk.Widget {
    public File file { get; set construct; }
    public string klaxx_name { get; set construct; }
    public Klaxxify.Window window { get; construct; }
    public Gtk.Box main_box { get; set; }
    private bool is_new { get; set; }
    public string[] content { get; set; }

    public KlaxxPage (Klaxxify.Window window, string name) {
        Object (
            window: window,
            klaxx_name: name
        );
    }

    public KlaxxPage.from_file (Klaxxify.Window window, File file) {
        Object (
            window: window,
            file: file
        );
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    ~KlaxxPage () {
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
                klaxx_name = content[0];
                is_new = false;
	        } catch (Error e) {
		        print ("Error: %s\n", e.message);
	        }
        } else {
            var template = klaxx_name + "\nS\nA\nB\nC\n&&&&&UnusedFiles&&&&&\n";
            content = template.split ("\n");
            var date_time = new DateTime.now_local ();
            var documents_folder = Environment.get_variable ("HOME") + "/Documents/";
            file = File.new_for_path ("%sklaxxifile-%s.tlrank".printf (documents_folder, date_time.format ("%d-%m-%y %T")));
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

        var klaxx_num = 1;
        while (klaxx_num < (content.length - (int) !is_new) && content[klaxx_num] != "&&&&&UnusedFiles&&&&&") {
            var klaxx_item = new Klaxxify.KlaxxItem (this, content[klaxx_num], klaxx_num);
            main_box.append (klaxx_item);
            klaxx_num++;
        }

        if (is_new) {
            window.draggables_sidebar.unused_files = {};
            window.draggables_sidebar.sidebar_index = klaxx_num + 1;
            window.draggables_sidebar.hidden_stack.visible_child_name = "placeholder";
        } else {
            window.draggables_sidebar.load_unused_files (content[klaxx_num + 1], klaxx_num + 1);
        }
    }

    public void save_to_file (string[] array, int index) {
        string second_degree_main = "";
        for (int second_degree = 0; second_degree < array.length; second_degree++) {
            second_degree_main = string.join (",", second_degree_main, array[second_degree]);
        }

        second_degree_main = (string) second_degree_main.data[1:];
        content[index] = second_degree_main;

        string first_degree_main = "";
        for (int first_degree = 0; first_degree < content.length; first_degree++) {
            first_degree_main = string.join ("\n", first_degree_main, content[first_degree]);
        }

        first_degree_main = (string) first_degree_main.data[1:];
        try {
            file.replace_contents (first_degree_main.data, null, false, GLib.FileCreateFlags.NONE, null, null);
        } catch ( GLib.Error e ) {
            GLib.error (e.message);
        }
    }
}
