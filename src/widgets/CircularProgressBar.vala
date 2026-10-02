/* CircularProgressBar.vala
 *
 * Copyright 2019 Hannes Schulze
 * Based on vala-circular-progressbar by phastmike
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

namespace Optimizer.Widgets {

    /**
     * The {@code CircularProgressBar} class provides a widget displaying a circular progress bar.
     *
     * @since 1.0.0
     */
    public class CircularProgressBar : Gtk.Widget {
        private const int MIN_DIAMETER = 80;
        private const double LINE_WIDTH = 7.0;
        private double m_percentage = 0.0;
        private bool m_is_in_focus = true;
        private ulong window_active_handler = 0;
        private unowned Gtk.Window? tracked_window = null;

        [Description(nick = "Percentage/Value", blurb = "The percentage value [0.0 ... 1.0]")]
        public double percentage {
            get {
                return m_percentage;
            }
            set {
                if (value > 1.0) {
                    m_percentage = 1.0;
                } else if (value < 0.0) {
                    m_percentage = 0.0;
                } else {
                    m_percentage = value;
                }
            }
        }

        [Description(nick = "Description", blurb = "Title of the progress bar")]
        public string description { get; set; }

        [Description(nick = "Custom progress text", blurb = "Custom progress text other than %d PERCENT")]
        public string custom_progress_text { get; set; default = ""; }

        /**
         * Constructs a new {@code CircularProgressBar} object.
         */
        public CircularProgressBar () {
            set_size_request (200, 200);
            notify.connect ((pspec) => {
                if (pspec.name == "root") {
                    track_window ();
                }
                queue_draw ();
            });
        }

        // Dim the progress bar while the window is in the background
        private void track_window () {
            if (tracked_window != null && window_active_handler != 0) {
                tracked_window.disconnect (window_active_handler);
            }
            window_active_handler = 0;

            tracked_window = get_root () as Gtk.Window;
            if (tracked_window != null) {
                window_active_handler = tracked_window.notify["is-active"].connect (() => {
                    m_is_in_focus = tracked_window.is_active;
                    queue_draw ();
                });
                m_is_in_focus = tracked_window.is_active;
            }
        }

        // Redraw when the style (e.g. light/dark) changes
        public override void css_changed (Gtk.CssStyleChange change) {
            base.css_changed (change);
            queue_draw ();
        }

        private int calculate_radius () {
            return (int) double.min (get_width () / 2,
                                     get_height () / 2) - 1;
        }

        public override Gtk.SizeRequestMode get_request_mode () {
            return Gtk.SizeRequestMode.CONSTANT_SIZE;
        }

        public override void measure (Gtk.Orientation orientation, int for_size,
                                      out int minimum, out int natural,
                                      out int minimum_baseline, out int natural_baseline) {
            minimum = MIN_DIAMETER;
            natural = MIN_DIAMETER;
            minimum_baseline = -1;
            natural_baseline = -1;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            var width = get_width ();
            var height = get_height ();
            if (width <= 0 || height <= 0) {
                return;
            }

            var cr = snapshot.append_cairo (Graphene.Rect ().init (0, 0, width, height));
            draw (cr);
        }

        private void draw (Cairo.Context cr) {
            int width, height;
            Pango.Layout layout;
            Pango.FontDescription font_description;

            cr.save ();

            var center_x = (get_width () - 2) / 2;
            var center_y = (get_height () - 2) / 2;
            var radius = (double) (calculate_radius () - 1);

            // Use the foreground color to detect whether a dark style is in use;
            // this works for both the system preference and the in-app ModeSwitch.
            Gdk.RGBA color = get_color ();
            var dark = (color.red + color.green + color.blue) / 3.0 > 0.5;

            // Radius fill

            if (dark) {
                if (Constants.USE_FALLBACK_PROGRESS_BAR_THEME) {
                    if (m_is_in_focus) {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.15, 0.15, 0.15);
                    } else {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.07, 0.07, 0.07);
                    }
                } else {
                    if (m_is_in_focus) {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.18, 0.18, 0.18);
                        draw_gradient_stroke (cr, radius, 1.0, 1.0, center_x, center_y, 0.32, 0.32, 0.32,
                                              0.28, 0.28, 0.28);
                        draw_gradient_stroke (cr, radius, 2.0, 1.0, center_x, center_y, 0.28, 0.28, 0.28,
                                              0.25, 0.25, 0.25);
                    } else {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.21, 0.21, 0.21);
                        draw_gradient_stroke (cr, radius, 1.0, 1.0, center_x, center_y, 0.35, 0.35, 0.35,
                                              0.32, 0.32, 0.32);
                        draw_gradient_stroke (cr, radius, 2.0, 1.0, center_x, center_y, 0.3, 0.3, 0.3,
                                              0.29, 0.29, 0.29);
                    }
                }
            } else {
                if (Constants.USE_FALLBACK_PROGRESS_BAR_THEME) {
                    if (m_is_in_focus) {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.85, 0.85, 0.85);
                    } else {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.93, 0.93, 0.93);
                    }
                } else {
                    if (m_is_in_focus) {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.79, 0.79, 0.79);
                        draw_gradient_stroke (cr, radius, 1.0, 1.0, center_x, center_y, 0.99, 0.99, 0.99,
                                              1.0, 1.0, 1.0);
                        draw_gradient_stroke (cr, radius, 2.0, 1.0, center_x, center_y, 0.98, 0.98, 0.98,
                                              1.0, 1.0, 1.0);
                    } else {
                        draw_solid_stroke (cr, radius, 0.0, 1.0, center_x, center_y, 0.78, 0.78, 0.78);
                        draw_gradient_stroke (cr, radius, 1.0, 1.0, center_x, center_y, 0.99, 0.99, 0.99,
                                              0.99, 0.99, 0.99);
                        draw_gradient_stroke (cr, radius, 2.0, 1.0, center_x, center_y, 0.98, 0.98, 0.98,
                                              0.99, 0.99, 0.99);
                    }
                }
            }

            // Progress fill
            double progress = (double) percentage;
            if (dark) {
                if (progress > 0.0) {
                    if (Constants.USE_FALLBACK_PROGRESS_BAR_THEME) {
                        if (m_is_in_focus) {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.95, 0.45, 0.16);
                        } else {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.35, 0.35, 0.35);
                        }
                    } else {
                        if (m_is_in_focus) {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.66, 0.32, 0.11);
                            draw_gradient_stroke (cr, radius, 1.0, progress, center_x, center_y, 0.95, 0.5, 0.25,
                                                  0.95, 0.47, 0.2);
                            draw_gradient_stroke (cr, radius, 2.0, progress, center_x, center_y, 0.95, 0.47, 0.20,
                                                  0.95, 0.45, 0.16);
                        } else {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.11, 0.11, 0.11);
                            draw_gradient_stroke (cr, radius, 1.0, progress, center_x, center_y, 0.2, 0.2, 0.2,
                                                  0.18, 0.18, 0.18);
                            draw_solid_stroke (cr, radius, 2.0, progress, center_x, center_y, 0.15, 0.15, 0.15);
                        }
                    }
                }
            } else {
                if (progress > 0.0) {
                    if (Constants.USE_FALLBACK_PROGRESS_BAR_THEME) {
                        if (m_is_in_focus) {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.95, 0.45, 0.16);
                        } else {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.65, 0.65, 0.65);
                        }
                    } else {
                        if (m_is_in_focus) {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.76, 0.36, 0.13);
                            draw_gradient_stroke (cr, radius, 1.0, progress, center_x, center_y, 0.97, 0.69, 0.53,
                                                  0.96, 0.56, 0.33);
                            draw_gradient_stroke (cr, radius, 2.0, progress, center_x, center_y, 0.96, 0.56, 0.33,
                                                  0.95, 0.45, 0.16);
                        } else {
                            draw_solid_stroke (cr, radius, 0.0, progress, center_x, center_y, 0.70, 0.70, 0.70);
                            draw_gradient_stroke (cr, radius, 1.0, progress, center_x, center_y, 0.91, 0.91, 0.91,
                                                  0.9, 0.9, 0.9);
                            draw_solid_stroke (cr, radius, 2.0, progress, center_x, center_y, 0.87, 0.87, 0.87);
                        }
                    }
                }
            }

            // Textual information
            var baseFont = get_pango_context ().get_font_description ();
            if (baseFont == null) {
                baseFont = new Pango.FontDescription ();
            }
            Gdk.cairo_set_source_rgba (cr, color);

            // Title
            layout = Pango.cairo_create_layout (cr);
            layout.set_text (description.printf ((int) (percentage * 100.0)), -1);
            font_description = baseFont.copy ();
            font_description.set_size (26 * Pango.SCALE);
            font_description.set_weight (Pango.Weight.BOLD);
            layout.set_font_description (font_description);
            Pango.cairo_update_layout (cr, layout);
            layout.get_size (out width, out height);
            cr.move_to (center_x - ((width / Pango.SCALE) / 2), center_y - 32);
            Pango.cairo_show_layout (cr, layout);

            // Percentage
            if (custom_progress_text != "") {
                layout.set_text (custom_progress_text, -1);
            } else {
                layout.set_text (_("%d Percent").printf ((int) (percentage * 100.0)).up (), -1);
            }
            font_description = baseFont.copy ();
            font_description.set_size (9 * Pango.SCALE);
            font_description.set_weight (Pango.Weight.NORMAL);
            layout.set_font_description (font_description);
            Pango.cairo_update_layout (cr, layout);
            layout.get_size (out width, out height);
            cr.move_to (center_x - ((width / Pango.SCALE) / 2), center_y + 18);
            Pango.cairo_show_layout (cr, layout);

            cr.restore ();
        }

        private void mask_arc (Cairo.Context cr, double radius, double shrink,
                               double progress, double center_x, double center_y) {
            cr.set_line_width (LINE_WIDTH - shrink * 2.0);
            var actual_radius = radius - LINE_WIDTH * 0.5;
            cr.arc (center_x, center_y, actual_radius, 1.5 * Math.PI,
                    (1.5 + progress * 2.0) * Math.PI);
        }

        private void draw_solid_stroke (Cairo.Context cr, double radius, double shrink,
                                        double progress, double center_x, double center_y,
                                        double color_r, double color_g, double color_b) {
            mask_arc (cr, radius, shrink, progress, center_x, center_y);
            cr.set_source_rgb (color_r, color_g, color_b);
            cr.stroke ();
        }

        private void draw_gradient_stroke (Cairo.Context cr, double radius, double shrink,
                                           double progress, double center_x, double center_y,
                                           double outer_r, double outer_g, double outer_b,
                                           double inner_r, double inner_g, double inner_b) {
            mask_arc (cr, radius, shrink, progress, center_x, center_y);
            var outer_radius = radius - shrink;
            var inner_radius = outer_radius - LINE_WIDTH;
            var pattern = new Cairo.Pattern.radial (center_x, center_y, outer_radius,
                                                    center_x, center_y, inner_radius);
            pattern.add_color_stop_rgb (0.0, outer_r, outer_g, outer_b);
            pattern.add_color_stop_rgb (1.0, inner_r, inner_g, inner_b);
            cr.set_source (pattern);
            cr.stroke ();
        }
    }
}
