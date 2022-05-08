public class Klaxxify.Application : Gtk.Application {

    public Application () {
        Object (
            application_id: "com.github.zenitsudev.klaxxify",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var window = new Klaxxify.Window (this);
        window.present ();
    }

    public static int main (string[] args) {
        var app = new Klaxxify.Application ();

        return app.run (args);
    }
}
