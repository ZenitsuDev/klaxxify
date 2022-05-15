public class Klaxxify.ImageObject : Gtk.Widget {

    private Gtk.Image main_widget { get; set; }
    public Gdk.Paintable paintable { get; set; }
    public string filename { get; construct; }

    public ImageObject (string filename) {
        Object (filename: filename);
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    ~ImageObject () {
        while (get_last_child () != null) {
            get_last_child ().unparent ();
        }
    }

    construct {
        try {
            paintable = Gdk.Texture.from_filename (filename);
        } catch (Error e) {
            critical ("%s\n", e.message);
        }

        main_widget = new Gtk.Image.from_paintable (paintable) {
            width_request = 100,
            height_request = 100
        };

        main_widget.set_parent (this);
    }
}
