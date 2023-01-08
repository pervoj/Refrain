/* db.vala
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

public errordomain Refrain.Audio.DBError {
    INITIALIZATION_FAILED,
    PREPARATION_FAILED,
    PROPERTIES_BINDING_FAILED,
    NOT_FOUND
}

public class Refrain.Audio.DB : Object {
    private const string FILE_NAME = "db.sqlite3";

    private static DB instance;
    public static DB get_default () {
        if (instance == null) instance = new DB ();
        return instance;
    }

    private Sqlite.Database db;

    public unowned Sqlite.Database get_db () {
        return db;
    }

    /**
     * initialize the database connection
     *
     * @param reinit if reinitialize the connection
     */
    public void init (bool reinit = false) throws DBError {
        // DB file path
        // var db_file = File.new_build_filename (Constants.DATA_DIR, FILE_NAME);
        var db_file = File.new_build_filename ("/home/pervoj/Temp", FILE_NAME);

        if (!db_file.query_exists ()) {
            throw new DBError.INITIALIZATION_FAILED ("%s doesn't exist", db_file.get_path ());
        }

        // init only if not inited before or if we want to reinit
        if (db == null || reinit) {
            // init the DB
            int ec = Sqlite.Database.open (db_file.get_path (), out db);

            if (ec != Sqlite.OK) {
                throw new DBError.INITIALIZATION_FAILED ("%d", ec);
            }
        }
    }

    /**
     * scan directories and load the files into database
     */
    public bool scan_dirs () {

        int result;
        Sqlite.Statement stmt;

        result = db.exec ("DELETE FROM song");
        if (result != Sqlite.OK) return false;

        File[] files;
        try {
            files = FileLister.from_settings ().get_files ();
        } catch {
            return false;
        }

        foreach (var file in files) {
            string query = """
                INSERT
                INTO song (path, name, album)
                VALUES (?, ?, ?)
            """;

            result = db.prepare_v2 (query, -1, out stmt);
            if (result != Sqlite.OK) return false;

            result = stmt.bind_text (1, file.get_path ());
            if (result != Sqlite.OK) return false;

            result = stmt.bind_text (2, "test name");
            if (result != Sqlite.OK) return false;

            result = stmt.bind_int (3, 1);
            if (result != Sqlite.OK) return false;

            stmt.step ();
        }

        return true;
    }
    public delegate void ScanDirsCB (bool res);
    public void scan_dirs_async (ScanDirsCB cb) {
        new Thread<void> ("refrain_audio_db_scan_dirs_async", () => {
            cb (scan_dirs ());
        });
    }
}
