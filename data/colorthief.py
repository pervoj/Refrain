#!/usr/bin/env python3

# colorthief.py
#
# Copyright 2022 Vojtěch Perník
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script takes the path to the audio file as an argument and prints
# the color palette from its title image. If something fails, it prints nothing.

# import GObject libraries
import gi
try:
    gi.require_version('Gio', '2.0')
    gi.require_version('Gst', '1.0')
    gi.require_version('GstPbutils', '1.0')
    gi.require_version('GstTag', '1.0')

    from gi.repository import Gio, Gst, GstPbutils, GstTag
except ImportError or ValueError:
    pass

# import Python libraries
import sys
import io
from colorthief import ColorThief

# exit if the argument wasn't specified
if not len(sys.argv) > 1: exit()

# init GStreamer
Gst.init()

# init file object from the path, exit if it doesn't exist
file = Gio.File.new_for_path(sys.argv[1])
if not file.query_exists(): exit()

# exit if the file is a directory
file_info = file.query_info("standard::*", Gio.FileQueryInfoFlags.NONE)
if file_info.get_file_type() == Gio.FileType.DIRECTORY: exit()

# exit if the file is not an audio file
# credits: G4Music by Nanling Zheng
file_type = file_info.get_content_type()
if file_type == None \
    or not Gio.content_type_is_mime_type(file_type, "audio/*") \
    or file_type.endswith("url"): exit()

# init discoverer, discover the file and get its tags
discoverer = GstPbutils.Discoverer(timeout = 5 * Gst.SECOND)
info = discoverer.discover_uri(file.get_uri())
sinfo = info.get_streams(GstPbutils.DiscovererAudioInfo)[0]
tags = sinfo.get_tags()

# get the cover sample from the tags
# https://github.com/elementary/music/blob/main/src/PlaybackManager.vala#L370
cover_sample = None
i = 0
cont = True
while cont:
    index = tags.get_sample_index("image", i)
    cont = index[0]
    sample = index[1]
    if sample == None: continue
    caps_struct = sample.get_caps().get_structure(0);
    image_type = GstTag.TagImageType.UNDEFINED
    enum = caps_struct.get_enum("image-type", GstTag.TagImageType)
    if enum[0]: image_type = enum[1]
    if image_type == GstTag.TagImageType.UNDEFINED and cover_sample == None:
        cover_sample = sample
    else:
        cover_sample = sample
        break
    i += 1

# get pixel data from the cover sample
# https://github.com/elementary/music/blob/main/src/PlaybackManager.vala#L388
if cover_sample == None: exit()
buffer = cover_sample.get_buffer()
if buffer == None: exit()
bmap = buffer.map(Gst.MapFlags.READ)
if not bmap[0]: exit()
data = io.BytesIO(bmap[1].data)

# get color palette from the pixel data
color_thief = ColorThief(data)
palette = color_thief.get_palette(2, 5)

# print the palette
print(palette)
