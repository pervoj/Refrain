/* party-view.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/party-view.ui")]
public class Refrain.PartyView : Adw.Bin {
    [GtkChild]
    private unowned Gtk.Button down_btn;

    // [GtkChild]
    // private unowned Adw.Clamp clamp;

    [GtkChild]
    private unowned Gtk.Box info_box;

    [GtkChild]
    private unowned Gtk.Image cover;

    [GtkChild]
    private unowned Gtk.Label title;

    [GtkChild]
    private unowned Gtk.Label author;

    [GtkChild]
    private unowned Gtk.Label album;

    [GtkChild]
    private unowned Gtk.Scale scale;

    construct {
        down_btn.clicked.connect (() => {
            down ();
        });
    }

    public signal void down ();

    public void set_scale_adjustment (Gtk.Adjustment adjustment) {
        scale.adjustment = adjustment;
    }

    public void adapt (int width) {
        if (width < 720) {
            info_box.orientation = Gtk.Orientation.VERTICAL;
            info_box.spacing = 18;
            title.halign = Gtk.Align.CENTER;
            author.halign = Gtk.Align.CENTER;
            album.halign = Gtk.Align.CENTER;
        } else {
            info_box.orientation = Gtk.Orientation.HORIZONTAL;
            info_box.spacing = 30;
            title.halign = Gtk.Align.START;
            author.halign = Gtk.Align.START;
            album.halign = Gtk.Align.START;
        }
    }
}
