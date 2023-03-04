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

        // init the entire library management
        try {
            Gee.task<void> (() => {
                try {
                    Author.init (); // this will init Album and Song as well
                } catch (Audio.DBError e) {
                    error ("%s\n", e.message);
                }
            });
        } catch (ThreadError e) {
            error ("%s\n", e.message);
        }
    }

    /**
     * scan directories and load the files into database
     */
    public bool scan_dirs () {
        int result = db.exec ("DELETE FROM song");
        if (result != Sqlite.OK) return false;

        result = db.exec ("DELETE FROM album");
        if (result != Sqlite.OK) return false;

        result = db.exec ("DELETE FROM author");
        if (result != Sqlite.OK) return false;

        File[] files;
        try {
            files = FileLister.from_settings ().get_files ();
        } catch {
            return false;
        }

        foreach (var file in files) {
            try {
                insert_song_from_file (file);
            } catch {
                return false;
            }
        }

        return true;
    }
    public delegate void ScanDirsCB (bool res);
    public void scan_dirs_async (ScanDirsCB cb) {
        new Thread<void> ("refrain_audio_db_scan_dirs_async", () => {
            cb (scan_dirs ());
        });
    }

    private Gst.PbUtils.Discoverer discoverer;
    public Song insert_song_from_file (File file) throws Error, DBError {
        if (discoverer == null) {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
        }

        // discover the file
        var info = discoverer.discover_uri (file.get_uri ());
        var sinfo = info.get_audio_streams ().nth_data (0);
        var tags = sinfo.get_tags ();

        // prepare variables
        string _title;
        string _author;
        string _album;
        int _track;

        // get title
        tags.get_string (Gst.Tags.TITLE, out _title);
        if (_title == null) {
            _title = "";
        }

        // get author
        tags.get_string (Gst.Tags.ARTIST, out _author);
        if (_author == null) {
            _author = "";
        }

        // get album
        tags.get_string (Gst.Tags.ALBUM, out _album);
        if (_album == null) {
            _album = "";
        }

        // get track number
        uint _track_num;
        if (tags.get_uint (Gst.Tags.TRACK_NUMBER, out _track_num)) {
            _track = (int) _track_num;
        } else {
            _track = -1;
        }

        // get author instance
        var author = Author.get_one_for_name (_author);
        if (author == null) {
            Author.insert (_author);
            author = Author.get_one_for_name (_author);
        }

        // get album instance
        var album = Album.get_one_for_name (author.id, _album);
        if (album == null) {
            Album.insert (author, _album);
            album = Album.get_one_for_name (author.id, _album);
        }

        // get song instance
        var song = Song.get_one_for_file (file);
        if (song == null) {
            Song.insert (album, file, _title, _track);
            song = Song.get_one_for_file (file);
        }

        return song;
    }

    // credits: Music by elementary OS
    private Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
        Gst.Sample cover_sample = null;
        Gst.Sample sample;
        for (int i = 0; tag_list.get_sample_index (Gst.Tags.IMAGE, i, out sample); i++) {
            var caps = sample.get_caps ();
            unowned Gst.Structure caps_struct = caps.get_structure (0);
            int image_type = Gst.Tag.ImageType.UNDEFINED;
            caps_struct.get_enum ("image-type", typeof (Gst.Tag.ImageType), out image_type);
            if (image_type == Gst.Tag.ImageType.UNDEFINED && cover_sample == null) {
                cover_sample = sample;
            } else if (image_type == Gst.Tag.ImageType.FRONT_COVER) {
                return sample;
            }
        }

        return cover_sample;
    }

    private Bytes? get_image_bytes_from_buffer (Gst.Buffer buffer) {
        Gst.MapInfo map_info;

        if (!buffer.map (out map_info, Gst.MapFlags.READ)) {
            warning ("Could not map memory buffer");
            return null;
        }

        Bytes bytes = new Bytes (map_info.data);

        buffer.unmap (map_info);

        return bytes;
    }
}
