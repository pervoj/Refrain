/* song.vala
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

public class Refrain.Audio.Song : Object {
    public string id { get; construct; }
    public string album_id { get; construct; }
    public string path { get; construct; }
    public string name { get; construct; }
    public int track { get; construct; }

    private Song (
        string id, string album_id, string path, string name, int track
    ) {
        Object (
            id: id,
            album_id: album_id,
            path: path,
            name: name,
            track: track
        );
    }

    private static bool initialized = false;
    public static void init () throws DBError {
        if (initialized) return;
        load ();
    }

    private static HashTable<string, Song> _cache;
    public static void load (bool clear_cache = true) throws DBError {
        initialized = true;
        if (_cache == null) {
            _cache = new HashTable<string, Song> (str_hash, str_equal);
        }

        if (clear_cache) _cache.remove_all ();

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM song";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            string id = "";
            string album_id = "";
            string path = "";
            string name = "";
            int track = -1;
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
                        break;
                    case "album":
                        album_id = stmt.column_text (i) ?? "";
                        break;
                    case "path":
                        path = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        name = stmt.column_text (i) ?? "";
                        break;
                    case "track":
                        string? val = stmt.column_text (i);
                        if (val != null && val.length > 0) {
                            track = int.parse (val);
                        }
                        break;
                }
            }
            if (id == "") continue;
            if (_cache.contains (id)) continue;

            _cache.set (id, new Song (id, album_id, path, name, track));
        }
    }

    public static void insert (
        Album album, File file, string name, int? track = null
    ) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = """
            INSERT
            INTO song (album, path, name, track)
            VALUES (?, ?, ?, ?)
        """;

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, album.id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        result = stmt.bind_text (2, file.get_path ());
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        result = stmt.bind_text (3, name);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        result = stmt.bind_int (4, track == null ? -1 : track);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        stmt.step ();

        load (false);
    }

    public static Song? get_one (string id) throws DBError {
        init ();
        return _cache.get (id);
    }

    public static Song? get_one_for_file (File file) throws DBError {
        init ();
        string path = file.get_path ();
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            if (val.path != path) continue;
            return val;
        }
        return null;
    }

    public static Song[] get_all () throws DBError {
        init ();
        Song[] res = {};
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            res += val;
        }
        return res;
    }

    public static Song[] get_all_for_album (string album_id) throws DBError {
        init ();
        Song[] res = {};
        var vals = _cache.get_values ();
        foreach (var val in vals) {
            if (val.album_id != album_id) continue;
            res += val;
        }
        return res;
    }
}
