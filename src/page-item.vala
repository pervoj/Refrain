/* page-item.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/page-item.ui")]
public class Refrain.PageItem : Gtk.Box {
    public string name { get; construct; }

    [GtkChild]
    private unowned Gtk.Image icon;

    [GtkChild]
    private unowned Gtk.Label title;

    public PageItem (string name, string title, string? icon = null) {
        Object (name: name);
        this.title.label = title;

        if (icon == null) {
            this.icon.visible = false;
        } else {
            this.icon.icon_name = icon;
        }
    }
}
