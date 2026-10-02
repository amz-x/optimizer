/* Application.vala
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
using Optimizer.Controllers;

namespace Optimizer {

    /**
     * The {@code Application} class is a foundation for all GTK-based applications.
     *
     * @see Gtk.Application
     * @since 1.0.0
     */
    public class Application : Gtk.Application {

        public AppController controller;

        /**
         * Constructs a new {@code Application} object.
         */
        public Application () {
            Object (
                application_id: Constants.ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
            );

            var quit_action = new SimpleAction ("quit", null);
            quit_action.activate.connect (() => {
                controller.quit ();
            });

            add_action (quit_action);
            set_accels_for_action ("app.quit", { "<Control>q" });
        }

        /**
         * Initializes Granite and applies the user's preferred style.
         * @return {@code void}
         */
        public override void startup () {
            base.startup ();

            Granite.init ();

            // Follow the system style unless the user picked one with the ModeSwitch
            var settings = Configs.Settings.get_instance ();
            if (settings.has_style_preference) {
                Granite.StyleManager.get_default ().color_scheme =
                    settings.dark_theme ? Gtk.InterfaceColorScheme.DARK : Gtk.InterfaceColorScheme.LIGHT;
            }
        }

        /**
         * Handle attempts to start up the application
         * @return {@code void}
         */
        public override void activate () {
            if (controller == null) {
                controller = new AppController (this);
            }

            controller.activate ();
        }
    }
}
