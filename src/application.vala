/* application.vala
 *
 * Copyright 2022 Zagura
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

namespace Paper {
	public class Application : Adw.Application {
		private ActionEntry[] APP_ACTIONS = {
			{ "new-note", on_new_note },
			{ "edit-note", on_edit_note },
			{ "delete-note", on_delete_note },
			{ "new-notebook", on_new_notebook },
			{ "edit-notebook", on_edit_notebook },
			{ "delete-notebook", on_delete_notebook },
			{ "format-bold", on_format_bold },
			{ "format-italic", on_format_italic },
			{ "format-strikethough", on_format_strikethough },
			{ "markdown-cheatsheet", on_markdown_cheatsheet },
			{ "about", on_about_action },
			{ "preferences", on_preferences_action },
			{ "quit", quit }
		};

		public Provider notebook_provider;

		private Notebook? active_notebook = null;
        private Note? current_note = null;

		public Application () {
			Object (application_id: Config.APP_ID, flags: ApplicationFlags.FLAGS_NONE);

		    var settings = new Settings (Config.APP_ID);
			var notes_dir = settings.get_string ("notes-dir");

			notebook_provider = new LocalProvider.from_directory (notes_dir);

			add_action_entries (APP_ACTIONS, this);

			set_accels_for_action ("app.quit", {"<primary>q"});
			set_accels_for_action ("app.preferences", {"<primary>comma"});

			set_accels_for_action ("app.new-note", {"<primary>n"});
			set_accels_for_action ("app.new-notebook", {"<primary><shift>n"});

			set_accels_for_action ("app.edit-note", {"<primary>e"});
			set_accels_for_action ("app.edit-notebook", {"<primary><shift>e"});

			set_accels_for_action ("app.format-bold", {"<primary>b"});
			set_accels_for_action ("app.format-italic", {"<primary>i"});
			set_accels_for_action ("app.format-strikethough", {"<primary>s"});
		}

		public override void activate () {
			base.activate ();
			var win = this.active_window;
			if (win == null) {
				win = new Window (this);
			}
			win.present ();
		}

		private void on_about_action () {
			string[] authors = {"Zagura"};
			Gtk.show_about_dialog(this.active_window,
				                  "program-name", "Notebook",
				                  "authors", authors,
				                  "version", "2022.0.0");
		}

		private void on_preferences_action () {
            var w = new PreferencesWindow (this);
			w.transient_for = active_window;
            w.destroy_with_parent = true;
            w.modal = true;
            w.present ();
		}

		private void on_format_bold () {
		    window.format_selection_bold ();
		}

		private void on_format_italic () {
		    window.format_selection_italic ();
		}

		private void on_format_strikethough () {
		    window.format_selection_strikethough ();
		}

		private void on_markdown_cheatsheet () {
            var w = new MarkdownCheatsheet ();
            w.destroy_with_parent = true;
			w.transient_for = active_window;
            w.modal = true;
            w.present ();
		}

		private void on_new_note () {
			if (active_notebook != null) {
			    var popup = new NoteCreatePopup (this);
			    popup.transient_for = active_window;
			    popup.title = "New note";
			    popup.present ();
			} else {
	            window.toast ("Create/choose a notebook before creating a note");
			}
		}

		private void on_edit_note () {
			if (current_note != null) {
			    request_edit_note (current_note);
			} else {
	            window.toast ("Select a note to edit it");
			}
		}

		private void on_delete_note () {
		    if (current_note != null) {
			    request_delete_note (current_note);
			} else {
	            window.toast ("Select a note to delete it");
			}
		}

		private void on_new_notebook () {
			var popup = new CreatePopup (this);
			popup.transient_for = active_window;
			popup.title = "New notebook";
			popup.present ();
		}

		private void on_edit_notebook () {
		    if (active_notebook == null) return;
			request_edit_notebook (active_notebook);
		}

		private void on_delete_notebook () {
		    if (active_notebook == null) return;
			request_delete_notebook (active_notebook);
		}

		public void request_edit_note (Note note) {
		    var popup = new NoteCreatePopup (this, note);
		    popup.transient_for = active_window;
		    popup.title = "Edit note";
		    popup.present ();
		}

		public void request_delete_note (Note note) {
			var popup = new ConfirmationPopup (
			    @"Are you sure you want to delete the note $(note.name)?",
			    "Delete Note",
			    () => try_delete_note (note)
		    );
			popup.transient_for = active_window;
			popup.present ();
		}

		public void request_edit_notebook (Notebook notebook) {
			var popup = new CreatePopup (this, notebook);
			popup.transient_for = active_window;
			popup.title = "Edit notebook";
			popup.present ();
		}

		public void request_delete_notebook (Notebook notebook) {
			var popup = new ConfirmationPopup (
			    @"Are you sure you want to delete the notebook $(notebook.name)?",
			    "Delete Notebook",
			    () => try_delete_notebook (notebook)
		    );
			popup.transient_for = active_window;
			popup.present ();
		}

		public void try_create_note (string name) {
		    if (name.contains (".") || name.contains ("/")) {
	            window.toast (@"Note name shouldn't contain '.' or '/'");
	            return;
		    }
			try {
			    active_notebook.new_note (name);
		        window.select_note (0);
		    } catch (ProviderError e) {
		        if (e is ProviderError.ALREADY_EXISTS) {
		            window.toast (@"Note '$(name)' already exists");
		        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
		            window.toast ("Couldn't create note");
		        } else {
		            window.toast ("Unknown error");
		        }
		    }
		}

		public void try_change_note (Note note, string name) {
		    if (name.contains (".") || name.contains ("/")) {
	            window.toast (@"Note name shouldn't contain '.' or '/'");
	            return;
		    }
			try {
		        note.notebook.change_note (note, name);
	            window.set_note (note);
		    } catch (ProviderError e) {
		        if (e is ProviderError.ALREADY_EXISTS) {
		            window.toast (@"Note '$(name)' already exists");
		        } else if (e is ProviderError.COULDNT_CREATE_FILE) {
		            window.toast ("Couldn't change note");
		        } else {
		            window.toast ("Unknown error");
		        }
		        println (e.message);
		    }
		}

		public void try_delete_note (Note note) {
			try {
		        note.notebook.delete_note (note);
		    } catch (ProviderError e) {
		        if (e is ProviderError.COULDNT_DELETE) {
		            window.toast (@"Couldn't delete note");
		        } else {
		            window.toast ("Unknown error");
		        }
		    }
		}

		public void try_create_notebook (string name, Gdk.RGBA color) {
		    if (name.contains (".") || name.contains ("/")) {
	            window.toast (@"Notebook name shouldn't contain '.' or '/'");
	            return;
		    }
			try {
		        var notebook = notebook_provider.new_notebook (name, color);
		        select_notebook (notebook);
		    } catch (ProviderError e) {
		        if (e is ProviderError.ALREADY_EXISTS) {
		            window.toast (@"Notebook '$(name)' already exists");
		        }
		        if (e is ProviderError.COULDNT_CREATE_FILE) {
		            window.toast ("Couldn't create notebook");
                    stderr.printf ("Couldn't create notebook: %s\n", e.message);
		        }
		    }
		}

		public void try_change_notebook (Notebook notebook, string name, Gdk.RGBA color) {
		    if (name.contains (".") || name.contains ("/")) {
	            window.toast (@"Notebook name shouldn't contain '.' or '/'");
	            return;
		    }
			try {
		        notebook_provider.change_notebook (notebook, name, color);
	            window.set_notebook (notebook);
		    } catch (ProviderError e) {
		        if (e is ProviderError.ALREADY_EXISTS) {
		            window.toast (@"Notebook '$(name)' already exists");
		        }
		        if (e is ProviderError.COULDNT_CREATE_FILE) {
		            window.toast ("Couldn't change notebook");
                    stderr.printf ("Couldn't change notebook: %s\n", e.message);
		        }
		    }
		}

		public void try_delete_notebook (Notebook notebook) {
			try {
		        notebook_provider.delete_notebook (notebook);
		    } catch (ProviderError e) {
		        if (e is ProviderError.COULDNT_DELETE) {
		            window.toast (@"Couldn't delete notebook");
		        } else {
		            window.toast ("Unknown error");
		        }
		    }
		}

		public void set_active_notebook (Notebook? notebook) {
		    if (active_notebook == notebook) return;
		    set_active_note (null);
		    active_notebook = notebook;
	        window.set_notebook (notebook);
		}

		public void select_notebook (Notebook notebook) {
	        int i = notebook_provider.notebooks.index_of (notebook);
	        window.select_notebook (i);
		}

		public void set_active_note (Note? note) {
		    if (current_note == note) return;
		    if (current_note != null) {
		        current_note.save ();
		        current_note.unload ();
		    }
	        current_note = note;
	        if (note != null) note.load ();
	        window.set_note (note);
		}

		public Window window {
		    get { return ((!) this.active_window) as Window; }
		}

		public override void shutdown () {
		    set_active_notebook (null);
		    base.shutdown ();
		}
	}
}
