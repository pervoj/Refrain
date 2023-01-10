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

    public static Author insert (string name) throws DBError {
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

        return new Author.from_name (name);
    }

    public Author (string id) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM author WHERE id = ?";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        string author_id = "";
        string name = "";

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        author_id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        name = stmt.column_text (i) ?? "";
                        break;
                }
            }
        }

        if (author_id == "") {
            throw new DBError.NOT_FOUND ("author %s not found", id);
        }

        Object (
            id: author_id,
            name: name
        );
    }

    public Author.from_name (string name) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM author WHERE name = ?";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, name);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        string id = "";
        string author_name = "";

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        id = stmt.column_text (i) ?? "";
                        break;
                    case "name":
                        author_name = stmt.column_text (i) ?? "";
                        break;
                }
            }
        }

        if (id == "") {
            throw new DBError.NOT_FOUND ("author %s not found", id);
        }

        Object (
            id: id,
            name: author_name
        );
    }

    public Author.create (string id, string name) {
        Object (
            id: id,
            name: name
        );
    }

    public static Author[] list () throws DBError {
        Author[] authors = {};

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM author ORDER BY name ASC";

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

            authors += new Author.create (id, name);
        }

        return authors;
    }

    public Album[] get_albums () throws DBError {
        Album[] albums = {};

        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM album WHERE author = ? ORDER BY name ASC";

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

            albums += new Album.create (id, name);
        }

        return albums;
    }
    public delegate void GetAlbumsCB (Album[] res, DBError? err);
    public void get_albums_async (GetAlbumsCB cb) {
        new Thread<void> ("refrain_audio_author_get_albums_async", () => {
            Album[] res = {};
            DBError? err = null;
            try {
                res = get_albums ();
            } catch (DBError e) {
                err = e;
            }
            cb (res, err);
        });
    }

    public Song[] get_songs () throws DBError {
        Song[] songs = {};

        foreach (Album album in get_albums ()) {
            foreach (Song song in album.get_songs ()) {
                songs += song;
            }
        }

        return songs;
    }
    public delegate void GetSongsCB (Song[] res, DBError? err);
    public void get_songs_async (GetSongsCB cb) {
        new Thread<void> ("refrain_audio_author_get_songs_async", () => {
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
