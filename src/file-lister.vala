/* file-lister.vala
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

public class Refrain.FileLister : Object {

    /** list of all recursively found files in the search dirs */
    private Array<File> found_files = new Array<File> ();

    /** temporary list of all dirs and subdirs to search in
        will be gradually cleaned up */
    private Array<File> dirs_to_list = new Array<File> ();

    /** get array of all recursively found files in the search dirs */
    public File[] get_files () {
        return found_files.data;
    }

    public FileLister (File[] search_dirs) throws Error {
        // run through all the search dirs
        foreach (File dir in search_dirs) {
            // check if the dir exists
            if (!dir.query_exists ()) {
                continue;
            }

            // check if the dir is a dir
            if (dir.query_file_type (FileQueryInfoFlags.NONE) != FileType.DIRECTORY) {
                continue;
            }

            // add the dir to the list
            dirs_to_list.append_val (dir);
        }

        // until the directory list is empty
        while (dirs_to_list.length > 0) {
            // get the first directory and remove it from the list
            // remove_index_fast can reorder the list, but that is not important
            var dir = dirs_to_list.remove_index_fast (0);

            // open the directory
            var opened_dir = Dir.open (dir.get_path (), 0);
            string? name;

            // list the directory
            while ((name = opened_dir.read_name ()) != null) {
                // get the current file and its info
                var file = dir.get_child (name);
                var info = file.query_info ("standard::*", FileQueryInfoFlags.NONE);

                // if the file is a directory
                if (info.get_file_type () == FileType.DIRECTORY) {
                    // add the directory to the dir list to process later
                    dirs_to_list.append_val (file);
                    continue;
                }

                // check if the file is an audio file
                var type = info.get_content_type ();
                if (
                    // credits: G4Music by Nanling Zheng
                    type != null &&
                    ContentType.is_mime_type ((!)type, "audio/*") &&
                    !((!)type).has_suffix ("url")
                ) {
                    // add the file to the file list
                    found_files.append_val (file);
                }
            }
        }
    }
}
