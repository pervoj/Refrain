/* application.vala
 *
 * Copyright 2022 Vojtěch Perník
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Refrain.Application : Adw.Application {
    public Application () {
        Object (
            application_id: Constants.APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public override void activate () {
        this.resource_base_path = Constants.RESOURCE_PATH_PREFIX;
        base.activate ();

        Gdk.Display? display = Gdk.Display.get_default ();
        assert (display != null);

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (Constants.RESOURCE_PATH_PREFIX + "/style.css");
        Gtk.StyleContext.add_provider_for_display (display, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var win = this.active_window;
        if (win == null) {
            win = new Refrain.Window (this);
        }
        win.present ();
    }

    public static int main (string[] args) {
        // enable gettext
        // https://docs.gtk.org/glib/i18n.html
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALE_DIR);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);

        var app = new Application ();
        return app.run (args);
    }

    private void on_about_action () {
        var dialog = new Adw.AboutWindow () {
            transient_for = this.active_window,
            application_icon = Constants.APP_ID,
            application_name = _("Refrain"),
            version = Constants.VERSION,
            developers = { "Vojtěch Perník <develop@pervoj.cz>" },
            developer_name = "Vojtěch Perník",
            // Translators: Here write your names, or leave it empty. Each name on new line. You can also add email (John Doe <j.doe@example.com>). Do not translate literally!
            translator_credits = _("translator-credits"),
            copyright = _("Copyright \xc2\xa9 2022 Vojtěch Perník"),
            license_type = Gtk.License.GPL_3_0,
            website = "https://gitlab.gnome.org/pervoj/Refrain",
            issue_url = "https://gitlab.gnome.org/pervoj/Refrain/-/issues"
        };
        dialog.present ();
    }

    private void on_preferences_action () {
        message ("app.preferences action activated");
    }
}
