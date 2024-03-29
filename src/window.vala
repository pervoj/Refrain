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
    public string content_title { get; private set; }

    [GtkChild]
    private unowned Adw.Leaflet controls_leaflet;

    [GtkChild]
    private unowned Adw.Leaflet main_leaflet;

    [GtkChild]
    private unowned Gtk.Button navigate_back;

    [GtkChild]
    private unowned Gtk.ListBox sidebar_main;

    [GtkChild]
    private unowned Gtk.ListBox sidebar_playlists;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned PlaybackControls playback_controls;

    [GtkChild]
    private unowned PartyView party_view;

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

        // content headerbar title
        stack.notify["visible-child"].connect (() => {
            content_title = ((Page) stack.visible_child).title;
        });

        // add pages
        add_page (new QueuePage ());
        add_page (new Page ("interprets", "Interprets", "avatar-default-symbolic"));
        add_page (new Page ("albums", "Albums", "media-optical-cd-audio-symbolic"));

        // sidebar rows activate action
        sidebar_main.row_activated.connect ((row) => {
            sidebar_change_active (true);
            stack.visible_child_name = ((PageItem) row.child).page_name;
        });
        sidebar_playlists.row_activated.connect ((row) => {
            sidebar_change_active (false);
        });

        // automatically switch to the first page
        sidebar_main.select_row (sidebar_main.get_row_at_index (0));

        // adaptable window
        adapt ();
        notify["default-width"].connect (adapt);

        playback_controls.cover_button_clicked.connect (() => {
            controls_leaflet.navigate (Adw.NavigationDirection.FORWARD);
        });
        party_view.down.connect (() => {
            controls_leaflet.navigate (Adw.NavigationDirection.BACK);
        });

        party_view.set_scale_adjustment (playback_controls.get_scale_adjustment ());
    }

    private void add_page (Page page) {
        stack.add_named (page, page.page_name);
        sidebar_main.append (page.menu_item);
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
        playback_controls.adapt (default_width);
        party_view.adapt (default_width);
    }
}
