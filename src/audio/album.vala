/* album.vala
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

public class Refrain.Audio.Album : Object {
    public string id { get; construct; }
    public string author_id { get; construct; }
    public string name { get; construct; }

    private string[] _song_ids;
    private Song[] _songs = {};

    public Song[] get_songs () throws DBError {
        if (_song_ids.length > _songs.length) {
            _songs = {};
            foreach (var song in _song_ids) {
                _songs += Song.get_one (song);
            }
        }
        return _songs;
    }

    private Album (
        string id, string author_id, string name, string[] song_ids = {}
    ) {
        Object (
            id: id,
            author_id: author_id,
            name: name
        );
        this._song_ids = song_ids;
    }

    private static bool initialized = false;
    public static void init () throws DBError {
        if (initialized) return;
        load ();
    }

    private static HashTable<string, Album> _cache;
    public static void load (bool clear_cache = true) throws DBError {
        initialized = true;
        if (_cache == null) {
            _cache = new HashTable<string, Album> (str_hash, str_equal);
        }

        if (clear_cache) _cache.remove_all ();

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM album";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            string id = "";
            string author_id = "";
            string name = "";
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
                        break;
                    case "author":
                        author_id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        name = stmt.column_text (i) ?? "";
                        break;
                }
            }
            if (id == "") continue;
            if (_cache.contains (id)) continue;

            var song_instances = Song.get_all_for_album (id);
            string[] song_ids = {};
            foreach (var song in song_instances) {
                song_ids += song.id;
            }

            _cache.set (id, new Album (id, author_id, name, song_ids));
        }
    }

    public static void insert (Author author, string name) throws DBError {
        init ();
        if (get_one_for_name (author.id, name) != null) return;

        unowned var db = DB.get_default ().get_db ();
        string query = """
            INSERT
            INTO album (author, name)
            VALUES (?, ?)
        """;

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, author.id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        result = stmt.bind_text (2, name);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        stmt.step ();

        load (false);
    }

    public static Album? get_one (string id) throws DBError {
        init ();
        return _cache.get (id);
    }

    public static Album? get_one_for_name (
        string author_id, string name
    ) throws DBError {
        init ();
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            if (val.author_id != author_id) continue;
            if (val.name != name) continue;
            return val;
        }
        return null;
    }

    public static Album[] get_all () throws DBError {
        init ();
        Album[] res = {};
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            res += val;
        }
        return res;
    }

    public static Album[] get_all_for_author (string author_id) throws DBError {
        init ();
        Album[] res = {};
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            if (val.author_id != author_id) continue;
            res += val;
        }
        return res;
    }
}
