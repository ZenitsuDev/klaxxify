public class Klaxxify.Image : Gtk.Widget {
    private Gtk.Image main_widget;
    public Gdk.Texture texture { get; construct; }
    public string filename { get; construct; }

    public Image (Gdk.Texture texture, string filename) {
        Object (
            texture: texture,
            filename: filename
        );
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        main_widget = new Gtk.Image.from_paintable (texture) {
            width_request = 100,
            height_request = 100
        };

        main_widget.set_parent (this);
    }

    ~Image () {
        main_widget.unparent ();
    }
}
