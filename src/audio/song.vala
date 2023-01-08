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
    public string path { get; construct; }
    public string name { get; construct; }
    public int track { get; construct; }

    public Song (string id) throws DBError {
        unowned var db = DB.get_default ().get_db ();
        string query = "SELECT * FROM song WHERE id = ?";

        Sqlite.Statement stmt;
        int result = db.prepare_v2 (query, -1, out stmt);
        if (result != Sqlite.OK) {
            throw new DBError.PREPARATION_FAILED ("%d", result);
        }

        result = stmt.bind_text (1, id);
        if (result != Sqlite.OK) {
            throw new DBError.PROPERTIES_BINDING_FAILED ("%d", result);
        }

        string song_id = "";
        string path = "";
        string name = "";
        int track = -1;

        int cols = stmt.column_count ();
        while (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < cols; i++) {
                string col_name = stmt.column_name (i) ?? "<none>";
                switch (col_name) {
                    case "id":
                        song_id = stmt.column_text (i) ?? "";
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
        }

        if (song_id == "") {
            throw new DBError.NOT_FOUND ("song %s not found", id);
        }

        Object (
            id: song_id,
            path: path,
            name: name,
            track: track
        );
    }

    public Song.create (string id, string path, string name, int track) {
        Object (
            id: id,
            path: path,
            name: name,
            track: track
        );
    }
}
