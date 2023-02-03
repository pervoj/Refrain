/* library-item.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/library-item.ui")]
public class Refrain.LibraryItem : Gtk.Box {
    public string title { get; set; default = ""; }
    public string icon_name { get; set; default = ""; }
    public Gdk.Paintable paintable { get; set; default = null;  }
    public Gtk.Orientation oriented {
        get; set; default = Gtk.Orientation.VERTICAL;
    }

    [GtkChild]
    private unowned Gtk.Label label;

    [GtkChild]
    private unowned Gtk.Image image;

    construct {
        notify["title"].connect (() => { sync_title (); });
        notify["icon-name"].connect (() => { sync_image (); });
        notify["paintable"].connect (() => { sync_image (); });

        sync_title ();
        sync_image ();
    }

    private void sync_title () {
        label.visible = (title != "");
    }

    private void sync_image () {
        image.visible = (icon_name != "" || paintable != null);
    }
}
