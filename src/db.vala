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

public class Refrain.DB : Object {
    private static Sqlite.Database db;

    /**
     * initialize the database connection
     *
     * @param reinit if reinitialize the connection
     */
    public static bool init (bool reinit = false) {
        // DB file path
        var db_path = Path.build_filename (Constants.DATA_DIR, "db.sqlite3");

        // init only if not inited before or if we want to reinit
        if (db == null || reinit) {
            // init the DB
            int ec = Sqlite.Database.open (db_path, out db);
            // check the error code, return false if fail
            if (ec != Sqlite.OK) return false;
        }

        // nothing failed, return true
        return true;
    }
}
