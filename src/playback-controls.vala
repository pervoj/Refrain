/* playback-controls.vala
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

[GtkTemplate (ui = "/app/drey/Refrain/playback-controls.ui")]
public class Refrain.PlaybackControls : Adw.Bin {
    [GtkChild]
    private unowned Gtk.ProgressBar progress_bar;

    [GtkChild]
    private unowned Gtk.Box desktop_controls;

    [GtkChild]
    private unowned Gtk.Box mobile_controls;

    [GtkChild]
    private unowned Gtk.Scale scale;

    [GtkChild]
    private unowned Gtk.Button cover_button;

    construct {
        scale.adjustment.upper = 5;
        scale.adjustment.value = 2;

        // bind scale and progress bar values
        scale.adjustment.bind_property (
            "value", progress_bar, "fraction",
            BindingFlags.BIDIRECTIONAL|BindingFlags.SYNC_CREATE,
            (binding, from, ref to) => {
                to.set_double (from.get_double () / scale.adjustment.upper);
            },
            (binding, from, ref to) => {
                to.set_double (scale.adjustment.upper * from.get_double ());
            }
        );

        // connect cover button click action
        cover_button.clicked.connect (() => {
            cover_button_clicked ();
        });
    }

    public signal void cover_button_clicked ();

    public Gtk.Adjustment get_scale_adjustment () {
        return scale.adjustment;
    }

    public void adapt (int width) {
        remove_css_class ("mobile");
        remove_css_class ("desktop");
        if (width < 420) {
            add_css_class ("mobile");
            progress_bar.visible = true;
            desktop_controls.visible = false;
            mobile_controls.visible = true;
        } else {
            add_css_class ("desktop");
            progress_bar.visible = false;
            desktop_controls.visible = true;
            mobile_controls.visible = false;
        }
    }
}
