/* author.vala
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

public class Refrain.Audio.Author : Object {
    public string id { get; construct; }
    public string name { get; construct; }

    private string[] _album_ids;
    private Album[] _albums = {};

    public Album[] get_albums () throws DBError {
        if (_album_ids.length > _albums.length) {
            _albums = {};
            foreach (var album in _album_ids) {
                _albums += Album.get_one (album);
            }
        }
        return _albums;
    }

    private Author (string id, string name, string[] album_ids = {}) {
        Object (
            id: id,
            name: name
        );
        this._album_ids = album_ids;
    }

    private static bool initialized = false;
    public static void init () throws DBError {
        if (initialized) return;
        load ();
    }

    private static HashTable<string, Author> _cache;
    public static void load (bool clear_cache = true) throws DBError {
        initialized = true;
        if (_cache == null) {
            _cache = new HashTable<string, Author> (str_hash, str_equal);
        }

        if (clear_cache) _cache.remove_all ();

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM author";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            string id = "";
            string name = "";
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        name = stmt.column_text (i) ?? "";
                        break;
                }
            }
            if (id == "") continue;
            if (_cache.contains (id)) continue;

            var album_instances = Album.get_all_for_author (id);
            string[] album_ids = {};
            foreach (var album in album_instances) {
                album_ids += album.id;
            }

            _cache.set (id, new Author (id, name, album_ids));
        }
    }

    public static void insert (string name) throws DBError {
        init ();
        if (get_one_for_name (name) != null) return;

        unowned var db = DB.get_default ().get_db ();
        string query = """
            INSERT
            INTO author (name)
            VALUES (?)
        """;

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, name);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        stmt.step ();

        load (false);
    }

    public static Author? get_one (string id) throws DBError {
        init ();
        return _cache.get (id);
    }

    public static Author? get_one_for_name (string name) throws DBError {
        init ();
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            if (val.name != name) continue;
            return val;
        }
        return null;
    }

    public static Author[] get_all () throws DBError {
        init ();
        Author[] res = {};
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            res += val;
        }
        return res;
    }
}
