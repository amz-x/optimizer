using Optimizer.Configs;
using Optimizer.Controllers;
using Optimizer.Views;

namespace Optimizer {

    /**
     * Class responsible for creating the u window and will contain contain other widgets.
     * allowing the user to manipulate the window (resize it, move it, close it, ...).
     *
     * @see Gtk.ApplicationWindow
     * @since 1.0.0
     */
    public class Window : Gtk.ApplicationWindow {

        /**
         * Constructs a new {@code Window} object.
         *
         * @see App.Configs.Constants
         */
        public Window (Gtk.Application app) {
            Object (
                application: app,
                icon_name: Constants.APP_ICON,
                resizable: true,
                title: Constants.PROGRAME_NAME
            );

            var settings = Optimizer.Configs.Settings.get_instance ();

            // GTK 4 doesn't let applications position their windows, so only
            // the size and maximized state are restored.
            set_default_size (settings.window_width, settings.window_height);
            if (settings.window_maximized) {
                maximize ();
            }

            // Save the window's size on close
            close_request.connect (() => {
                settings.window_maximized = maximized;
                if (!maximized) {
                    settings.window_width = get_width ();
                    settings.window_height = get_height ();
                }
                return false;
            });
        }
    }
}
