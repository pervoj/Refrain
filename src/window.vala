/* window.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/window.ui")]
public class Refrain.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned PlaybackControls playback_controls;

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        #if DEVEL
            add_css_class ("devel");
        #endif

        adapt ();
        notify["default-width"].connect (adapt);
    }

    private void adapt () {
        if (default_width < 420) {
            remove_css_class ("desktop");
            add_css_class ("mobile");
            playback_controls.adapt_mobile ();
        } else {
            add_css_class ("desktop");
            remove_css_class ("mobile");
            playback_controls.adapt_desktop ();
        }
    }
}
