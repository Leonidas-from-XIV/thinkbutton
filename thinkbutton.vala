/**
 *  thinkbutton - Plays one sound file and terminate on second call
 *  Copyright (C) 2011, 2013  Marek Kubica
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Compile it with:
// valac thinkbutton.vala --pkg gtk+-3.0 --pkg libcanberra --pkg libcanberra-gtk3

// define our possible commands
enum Command {
	// ZERO is reserved, never used
	ZERO,
	QUIT
}

void exit_program() {
	Idle.add(() => {
		Gtk.main_quit();
		return false;
	});
}

int main(string[] args) {
	// initialize GTK+, so it does not complain on runtime
	// (canberra) or just segfault (unique)

	var app = new Gtk.Application("net.xivilization.thinkbutton", 0);
	app.activate.connect((app) => {
		string filename = null;

		var oc = new GLib.OptionContext(" - thinkvantage");
		GLib.OptionEntry[] options = {
			OptionEntry() { long_name = "filename", short_name = 'f', flags=0, arg=GLib.OptionArg.FILENAME, arg_data=&filename, description="Bla", arg_description=null },
			OptionEntry() { long_name = null, short_name = 0, flags=0, arg=0, arg_data=null, description=null, arg_description=null }
		};

		Intl.setlocale(GLib.LocaleCategory.ALL, "");

		oc.add_main_entries(options, null);
		oc.add_group(Gtk.get_option_group(true));
		oc.set_help_enabled(true);
		try {
			oc.parse(ref args);
		} catch (GLib.OptionError e) {
			stderr.printf("Error parsing argument: %s\n",
				e.message);
		}

		if (filename == null) {
			stderr.printf("No file specified\n");
		}
		stderr.printf("Filename = %s\n", filename);
		// now we can configure canberra
		CanberraGtk.context_get().change_props(
			Canberra.PROP_APPLICATION_NAME, "thinkvantage",
			Canberra.PROP_APPLICATION_VERSION, "0.1.0",
			Canberra.PROP_APPLICATION_ID, "net.xivilization.thinkbutton",
			null);
		Canberra.Proplist proplist;
		Canberra.Proplist.create(out proplist);

		// select the file to play
		proplist.sets(Canberra.PROP_MEDIA_FILENAME, filename);

		// let Canberra play the file, calling the cb when done
		var result = CanberraGtk.context_get().play_full(1, proplist, (c, id, code) => {
			stderr.printf("played\n");
			// playing done, we can close the program
			exit_program();
		});

		// check whether we can play it
		if (result < 0) {
			stderr.printf("Failed to play the file: %s\n",
				Canberra.strerror(result));
		}
	});
	app.run();
	for (;;) {}


	return 0;
}
