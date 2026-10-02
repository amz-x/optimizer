/* ProcessesView.vala
 *
 * Copyright 2019 Hannes Schulze
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

using Optimizer.Configs;
using Optimizer.Widgets;
using Optimizer.Utils;

namespace Optimizer.Views {

    /**
     * The {@code ProcessesView} class.
     *
     * @since 1.0.0
     */
    public class ProcessesView : Gtk.Box {
        private delegate string FormatFunc (Optimizer.Utils.Process process);

        private Gtk.ScrolledWindow  scrolled_window;
        private Gtk.ColumnView      column_view;
        private GLib.ListStore      list_model;
        private Gtk.CustomFilter    search_filter;
        private Gtk.SingleSelection selection_model;
        private Gtk.ActionBar       action_bar;
        private Gtk.SearchEntry     search_field;
        private Gtk.Button          end_process_button;
        private Gee.HashMap<int, Optimizer.Utils.Process> processes_list;

        /**
         * Constructs a new {@code ProcessesView} object.
         */
        public ProcessesView () {
            Object (
                orientation: Gtk.Orientation.VERTICAL
            );

            add_css_class ("processes_view");

            // Model: ListStore -> FilterListModel (search) -> SortListModel (columns) -> SingleSelection
            list_model = new GLib.ListStore (typeof (Optimizer.Utils.Process));

            search_filter = new Gtk.CustomFilter ((item) => {
                var search_text = search_field.text;
                if (search_text == "") {
                    return true;
                }

                var process = (Optimizer.Utils.Process) item;
                return search_text.down () in process.command.down ();
            });
            var filter_model = new Gtk.FilterListModel (list_model, search_filter);

            column_view = new Gtk.ColumnView (null) {
                hexpand = true,
                vexpand = true
            };

            var sort_model = new Gtk.SortListModel (filter_model, column_view.sorter);
            selection_model = new Gtk.SingleSelection (sort_model) {
                autoselect = false,
                can_unselect = true
            };
            column_view.model = selection_model;

            // Process List
            scrolled_window = new Gtk.ScrolledWindow () {
                child = column_view,
                hexpand = true,
                vexpand = true
            };
            append (scrolled_window);

            // Action bar with SearchEntry and End-Process-button
            action_bar = new Gtk.ActionBar ();
            append (action_bar);

            search_field = new Gtk.SearchEntry ();
            action_bar.pack_start (search_field);

            end_process_button = new Gtk.Button.with_label (_("End Process"));
            end_process_button.add_css_class (Granite.CssClass.DESTRUCTIVE);
            action_bar.pack_end (end_process_button);

            // PID column
            add_column (_("PID"), "pid", (p) => p.pid.to_string (),
                        new Gtk.NumericSorter (property_expression ("pid")), 1.0f, 60);

            // Memory usage column
            add_column (_("Total Memory"), "mem-usage",
                        (p) => GLib.format_size (p.mem_usage, GLib.FormatSizeFlags.IEC_UNITS),
                        new Gtk.NumericSorter (property_expression ("mem-usage")), 1.0f, 90);

            // % Memory column
            GTop.Memory memory;
            GTop.get_mem (out memory);
            float total_memory = (float) (memory.total / 1024 / 1024) / 1000;

            add_column (_("% Memory"), "mem-usage", (p) => {
                float used_memory = (float) (p.mem_usage / 1024 / 1024) / 1000;
                return "%.1f%%".printf ((used_memory / total_memory) * 100);
            }, new Gtk.NumericSorter (property_expression ("mem-usage")), 1.0f, 80);

            // User column
            add_column (_("User"), "user", (p) => p.user ?? "",
                        new Gtk.StringSorter (property_expression ("user")), 0.0f, 80);

            // CPU usage column
            add_column (_("% CPU"), "cpu-usage", (p) => "%.1f%%".printf (p.cpu_usage * 100),
                        new Gtk.NumericSorter (property_expression ("cpu-usage")), 1.0f, 70);

            // Process column
            var process_column = add_column (_("Process"), "command", (p) => p.command ?? "",
                                             new Gtk.StringSorter (property_expression ("command")), 0.0f, 90, true);
            process_column.expand = true;

            // Searching
            search_field.search_changed.connect (() => {
                search_filter.changed (Gtk.FilterChange.DIFFERENT);
            });

            // Populate the list
            processes_list = new Gee.HashMap<int, Optimizer.Utils.Process> ();

            var process_manager = ProcessManager.get_instance ();
            process_manager.process_added.connect ((p) => {
                if (!processes_list.has_key (p.pid)) {
                    processes_list[p.pid] = p;
                    list_model.append (p);
                }
            });

            process_manager.updated.connect (() => {
                // Rows update themselves through property bindings, but the
                // sort order has to be recalculated with the new values.
                column_view.sorter.changed (Gtk.SorterChange.DIFFERENT);
            });

            process_manager.process_removed.connect ((pid) => {
                if (processes_list.has_key (pid)) {
                    uint position;
                    if (list_model.find (processes_list[pid], out position)) {
                        list_model.remove (position);
                    }
                    processes_list.unset (pid);
                }
            });

            // End Process button
            end_process_button.clicked.connect (() => {
                var process = selection_model.selected_item as Optimizer.Utils.Process;
                if (process == null) {
                    return;
                }

                Gee.Map<int, Optimizer.Utils.Process> processes = process_manager.get_process_list ();
                if (!processes.has_key (process.pid)) {
                    return;
                }

                processes[process.pid].kill ();
            });
        }

        private static Gtk.Expression property_expression (string property) {
            return new Gtk.PropertyExpression (typeof (Optimizer.Utils.Process), null, property);
        }

        /**
         * Adds a column that displays one property of the process, formatted
         * by {@code format}, and keeps it up to date while the row is shown.
         */
        private Gtk.ColumnViewColumn add_column (string title, string property, owned FormatFunc format,
                                                 Gtk.Sorter sorter, float xalign, int min_width,
                                                 bool ellipsize = false) {
            var factory = new Gtk.SignalListItemFactory ();

            factory.setup.connect ((obj) => {
                var list_item = (Gtk.ListItem) obj;
                var label = new Gtk.Label (null) {
                    xalign = xalign,
                    width_request = min_width,
                    margin_start = 6,
                    margin_end = 6
                };
                if (ellipsize) {
                    label.ellipsize = Pango.EllipsizeMode.END;
                }
                if (xalign > 0.5f) {
                    label.add_css_class (Granite.CssClass.NUMERIC);
                }
                list_item.child = label;
            });

            factory.bind.connect ((obj) => {
                var list_item = (Gtk.ListItem) obj;
                var label = (Gtk.Label) list_item.child;
                var process = (Optimizer.Utils.Process) list_item.item;

                var binding = process.bind_property (property, label, "label", BindingFlags.SYNC_CREATE,
                    (binding, from_value, ref to_value) => {
                        to_value.set_string (format ((Optimizer.Utils.Process) binding.dup_source ()));
                        return true;
                    }
                );
                list_item.set_data<Binding> ("optimizer-binding", binding);
            });

            factory.unbind.connect ((obj) => {
                var list_item = (Gtk.ListItem) obj;
                var binding = list_item.steal_data<Binding> ("optimizer-binding");
                if (binding != null) {
                    binding.unbind ();
                }
            });

            var column = new Gtk.ColumnViewColumn (title, factory) {
                resizable = true,
                sorter = sorter
            };
            column_view.append_column (column);

            return column;
        }
    }
}
