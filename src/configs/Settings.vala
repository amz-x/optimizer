/* Settings.vala
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

namespace Optimizer.Configs {

    /**
     * The {@code Settings} class provides typed access to the application's
     * GSettings schema.
     *
     * @see GLib.Settings
     * @since 1.0.0
     */
    public class Settings : GLib.Settings {

        /**
         * This static property represents the {@code Settings} type.
         */
        private static Settings? instance;

        /**
         * The most recent width of the window.
         */
        public int window_width {
            get { return get_int ("window-width"); }
            set { set_int ("window-width", value); }
        }

        /**
         * The most recent height of the window.
         */
        public int window_height {
            get { return get_int ("window-height"); }
            set { set_int ("window-height", value); }
        }

        /**
         * Whether the window was maximized when it was last closed.
         */
        public bool window_maximized {
            get { return get_boolean ("window-maximized"); }
            set { set_boolean ("window-maximized", value); }
        }

        /**
         * This property will represent the mount path of the partition that is
         * monitored in the dashboard view.
         */
        public string monitored_partition {
            owned get { return get_string ("monitored-partition"); }
            set { set_string ("monitored-partition", value); }
        }

        /**
         * This property is set to true when the user selected a dark theme using
         * the ModeSwitch.
         */
        public bool dark_theme {
            get { return get_boolean ("dark-theme"); }
            set { set_boolean ("dark-theme", value); }
        }

        /**
         * Whether the user ever explicitly chose a light or dark style.
         * If not, the application follows the system style.
         */
        public bool has_style_preference {
            get { return get_user_value ("dark-theme") != null; }
        }

        /**
         * Constructs a new {@code Settings} object.
         */
        private Settings () {
            Object (schema_id: Constants.ID);
        }

        /**
         * Returns a single instance of this class.
         *
         * @return {@code Settings}
         */
        public static unowned Settings get_instance () {
            if (instance == null) {
                instance = new Settings ();
            }

            return instance;
        }
    }
}
