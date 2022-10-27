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
    private unowned Adw.Leaflet main_leaflet;

    [GtkChild]
    private unowned Gtk.Button navigate_back;

    [GtkChild]
    private unowned Gtk.ListBox sidebar_main;

    [GtkChild]
    private unowned Gtk.ListBox sidebar_playlists;

    [GtkChild]
    private unowned PlaybackControls playback_controls;

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        #if DEVEL
            add_css_class ("devel");
        #endif

        // navigate back button
        navigate_back.clicked.connect (() => {
            main_leaflet.navigate (Adw.NavigationDirection.BACK);
        });

        // sidebar rows activate action
        sidebar_main.row_activated.connect ((row) => {
            sidebar_change_active (true);
        });
        sidebar_playlists.row_activated.connect ((row) => {
            sidebar_change_active (false);
        });

        // adaptable window
        adapt ();
        notify["default-width"].connect (adapt);
    }

    private void sidebar_change_active (bool main_list) {
        if (main_list) {
            sidebar_playlists.unselect_all ();
        } else {
            sidebar_main.unselect_all ();
        }
        main_leaflet.navigate (Adw.NavigationDirection.FORWARD);
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
