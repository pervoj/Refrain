/* page.vala
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

public class Refrain.Page : Adw.Bin {
    public string page_name { get; construct; }
    public string title { get; protected set; }
    public string? icon { get; protected set; }
    public PageItem menu_item { get; construct; }

    public Page (string name, string title, string? icon = null) {
        Object (
            page_name: name,
            title: title,
            icon: icon,
            menu_item: new PageItem (name, title, icon)
        );
    }
}
