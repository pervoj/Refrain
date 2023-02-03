/* authors-page.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/library-page.ui")]
public class Refrain.AuthorsPage : Refrain.Page {

    [GtkChild]
    private unowned Gtk.GridView grid;

    private Gtk.SortListModel sort_model = new Gtk.SortListModel (null, null);

    public AuthorsPage () {
        base ("interprets", "Interprets", "avatar-default-symbolic");
    }

    construct {
        CompareDataFunc<LibraryItem> compare_func = (a, b) => {
            return strcmp (a.title, b.title);
        };
        sort_model.sorter = new Gtk.CustomSorter (compare_func);

        var factory = new Gtk.SignalListItemFactory ();
        factory.bind.connect ((_item) => {
            var item = (Gtk.ListItem) _item;
            item.child = (LibraryItem) item.item;
        });

        grid.factory = factory;
        grid.model = new Gtk.NoSelection (sort_model);
        grid.remove_css_class ("view");

        get_authors_model ();
    }

    private void get_authors_model () {
        Audio.Author.ListCB cb = (authors, err) => {
            var model = new ListStore (typeof (LibraryItem));
            foreach (var author in authors) {
                model.append (new LibraryItem () {
                    icon_name = "avatar-default-symbolic",
                    title = author.name,
                    oriented = Gtk.Orientation.HORIZONTAL
                });
            }
            sort_model.model = model;
        };
        Audio.Author.list_async (cb);
    }
}
