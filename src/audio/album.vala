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
    public string name { get; construct; }
    public Bytes? cover { get; construct; }

    public static Album insert (Author author, string name, Bytes? cover) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        // compose the query
        string query = """
            INSERT
            INTO album (author, name""";
        if (cover != null) query += ", cover";
        query += """)
            VALUES (?, ?""";
        if (cover != null) query += ", ?";
        query += ")";

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

        if (cover != null) {
            result = stmt.bind_blob (3, Bytes.unref_to_data (cover), cover.length);
            if (result != Sqlite.OK) {
                throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
            }
        }

        stmt.step ();

        return new Album.from_name (author, name);
    }

    public Album (string id) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM album WHERE id = ?";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        string album_id = "";
        string name = "";
        Bytes? cover = null;

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        album_id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        name = stmt.column_text (i) ?? "";
                        break;
                    case "cover":
                        unowned uint8[] data = (uint8[]) stmt.column_blob (i);
                        data.length = stmt.column_bytes (i);
                        cover = new Bytes (data);
                        break;
                }
            }
        }

        if (album_id == "") {
            throw new DBError.NOT_FOUND ("album %s not found", id);
        }

        Object (
            id: album_id,
            name: name,
            cover: cover
        );
    }

    public Album.from_name (Author author, string name) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM album WHERE author = ? AND name = ?";

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

        string id = "";
        string album_name = "";
        Bytes? cover = null;

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        album_name = stmt.column_text (i) ?? "";
                        break;
                    case "cover":
                        unowned uint8[] data = (uint8[]) stmt.column_blob (i);
                        data.length = stmt.column_bytes (i);
                        cover = new Bytes (data);
                        break;
                }
            }
        }

        if (id == "") {
            throw new DBError.NOT_FOUND ("album %s not found", id);
        }

        Object (
            id: id,
            name: album_name,
            cover: cover
        );
    }

    public Album.create (string id, string name, Bytes? cover = null) {
        Object (
            id: id,
            name: name,
            cover: cover
        );
    }

    public Song[] get_songs () throws DBError {
        Song[] songs = {};

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM song WHERE album = ? ORDER BY track ASC";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, this.id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            string id = "";
            string path = "";
            string name = "";
            int track = -1;
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
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

            songs += new Song.create (id, path, name, track);
        }

        return songs;
    }
    public delegate void GetSongsCB (Song[] res, DBError? err);
    public void get_songs_async (GetSongsCB cb) {
        new Thread<void> ("refrain_audio_album_get_songs_async", () => {
            Song[] res = {};
            DBError? err = null;
            try {
                res = get_songs ();
            } catch (DBError e) {
                err = e;
            }
            cb (res, err);
        });
    }
}
