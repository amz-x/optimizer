/* HeaderBar.vala
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
using Optimizer.Utils;

namespace Optimizer.Widgets {

    /**
     * The {@code HeaderBar} class is responsible for displaying top bar. Similar to a horizontal box.
     *
     * @see Gtk.HeaderBar
     * @since 1.0.0
     */
    public class HeaderBar : Granite.Bin {
        // Gtk.HeaderBar is sealed in GTK 4, so it is wrapped instead of subclassed
        private Gtk.HeaderBar    headerbar;

        public Gtk.StackSwitcher stack_switcher { get; set; }
        public Gtk.MenuButton    menu_button { get; set; }
        public Gtk.PopoverMenu   menu { get; set; }
        public GLib.Menu         partition_menu;

        /**
         * Constructs a new {@code HeaderBar} object.
         */
        public HeaderBar (Gtk.Application app) {
            SimpleAction partition_action = new SimpleAction.stateful ("partition-action",
                new GLib.VariantType ("s"),
                new Variant.string (Configs.Settings.get_instance ().monitored_partition));
            partition_action.activate.connect ((parameter) => {
                partition_action.set_state (parameter);
                Resources.get_instance ().mount_path = parameter.get_string ();
                Configs.Settings.get_instance ().monitored_partition = parameter.get_string ();
            });
            app.add_action (partition_action);

            headerbar = new Gtk.HeaderBar ();
            child = headerbar;

            stack_switcher = new Gtk.StackSwitcher ();
            headerbar.title_widget = stack_switcher;

            var main_menu = new GLib.Menu ();
            partition_menu = new GLib.Menu ();
            main_menu.append_submenu (_("Monitored partition"), partition_menu);
            main_menu.append (_("Quit"), "app.quit");

            menu = new Gtk.PopoverMenu.from_model (main_menu);

            menu_button = new Gtk.MenuButton () {
                icon_name = "open-menu",
                popover = menu,
                primary = true
            };
            menu_button.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);
            headerbar.pack_end (menu_button);

            var style_manager = Granite.StyleManager.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic") {
                primary_icon_tooltip_text = _("Light background"),
                secondary_icon_tooltip_text = _("Dark background"),
                valign = Gtk.Align.CENTER,
                margin_end = 6
            };

            // Reflect the effective style, which may come from the system preference
            mode_switch.active = style_manager.color_scheme == Gtk.InterfaceColorScheme.DARK || (
                style_manager.color_scheme == Gtk.InterfaceColorScheme.DEFAULT &&
                gtk_settings.gtk_interface_color_scheme == Gtk.InterfaceColorScheme.DARK
            );

            mode_switch.notify["active"].connect (() => {
                style_manager.color_scheme = mode_switch.active ?
                    Gtk.InterfaceColorScheme.DARK : Gtk.InterfaceColorScheme.LIGHT;
                Configs.Settings.get_instance ().dark_theme = mode_switch.active;
            });
            headerbar.pack_end (mode_switch);
        }

        public void add_partition (string partition_path) {
            var menu_item = new GLib.MenuItem (partition_path, "app.partition-action");
            menu_item.set_attribute_value ("target", new Variant.string (partition_path));
            partition_menu.append_item (menu_item);
        }
    }
}
