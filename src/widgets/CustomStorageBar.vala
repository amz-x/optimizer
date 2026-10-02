/**
 *  Copyright (C) 2011-2017 Granite Developers (https://launchpad.net/granite)
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 *
 *  Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Optimizer.Widgets.CustomStorageBar : Gtk.Box {
    public enum ItemDescription {
        OTHER,
        PACKAGE_CACHES,
        CRASH_REPORTS,
        APPLICATION_LOGS,
        APPLICATION_CACHES,
        TRASH;

        public static string? get_class (ItemDescription description) {
            switch (description) {
                case ItemDescription.PACKAGE_CACHES:
                    return "files";
                case ItemDescription.CRASH_REPORTS:
                    return "audio";
                case ItemDescription.APPLICATION_LOGS:
                    return "video";
                case ItemDescription.APPLICATION_CACHES:
                    return "photo";
                case ItemDescription.TRASH:
                    return "app";
                default:
                    return null;
            }
        }

        public static string get_name (ItemDescription description) {
            switch (description) {
                case ItemDescription.PACKAGE_CACHES:
                    return _("Package Caches");
                case ItemDescription.CRASH_REPORTS:
                    return _("Crash Reports");
                case ItemDescription.APPLICATION_LOGS:
                    return _("Application Logs");
                case ItemDescription.APPLICATION_CACHES:
                    return _("Application Caches");
                case ItemDescription.TRASH:
                    return _("Trash");
                default:
                    return _("Other");
            }
        }
    }

    private uint64 _storage = 0;
    public uint64 storage {
        get {
            return _storage;
        }

        set {
            _storage = value;
            update_size_description ();
        }
    }

    private uint64 _total_usage = 0;

    public uint64 total_usage {
        get {
            return _total_usage;
        }

        set {
            _total_usage = uint64.min (value, storage);
            update_size_description ();
        }
    }

    public int inner_margin_sides {
        get {
            return fillblock_box.margin_start;
        }
        set {
            fillblock_box.margin_end = fillblock_box.margin_start = value;
        }
    }

    private Gtk.Label description_label;
    private GLib.HashTable<int, FillBlock> blocks;
    private int index = 0;
    private FillBlockBox fillblock_box;
    private Gtk.Box legend_box;
    private FillBlock free_space;
    private FillBlock used_space;

    /**
     * Creates a new StorageBar widget with the given amount of space.
     *
     * @param storage the total amount of space.
     */
    public CustomStorageBar (uint64 storage) {
        Object (storage: storage);
    }

    /**
     * Creates a new StorageBar widget with the given amount of space.an a larger total usage block
     *
     * @param storage the total amount of space.
     * @param usage the amount of space used.
     */
    public CustomStorageBar.with_total_usage (uint64 storage, uint64 total_usage) {
        Object (storage: storage, total_usage: total_usage);
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        add_css_class ("storage-bar");

        description_label = new Gtk.Label (null);
        description_label.hexpand = true;
        description_label.margin_top = 6;
        blocks = new GLib.HashTable<int, FillBlock> (null, null);
        fillblock_box = new FillBlockBox (this);
        fillblock_box.add_css_class ("trough");
        fillblock_box.hexpand = true;
        inner_margin_sides = 12;
        legend_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        legend_box.halign = Gtk.Align.CENTER;
        legend_box.hexpand = true;
        var legend_scrolled = new Gtk.ScrolledWindow ();
        legend_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        legend_scrolled.propagate_natural_height = true;
        legend_scrolled.hexpand = true;
        legend_scrolled.margin_bottom = 12;
        legend_scrolled.child = legend_box;
        var grid = new Gtk.Grid ();
        grid.attach (legend_scrolled, 0, 0, 1, 1);
        grid.attach (fillblock_box, 0, 1, 1, 1);
        grid.attach (description_label, 0, 2, 1, 1);
        append (grid);

        create_default_blocks ();
    }

    private void create_default_blocks () {
        var seq = new Sequence<ItemDescription> ();
        seq.append (ItemDescription.PACKAGE_CACHES);
        seq.append (ItemDescription.CRASH_REPORTS);
        seq.append (ItemDescription.APPLICATION_LOGS);
        seq.append (ItemDescription.APPLICATION_CACHES);
        seq.append (ItemDescription.TRASH);
        seq.sort ((a, b) => {
            return ItemDescription.get_name (a).collate (ItemDescription.get_name (b));
        });

        seq.foreach ((description) => {
            var fill_block = new FillBlock (description, 0);
            fillblock_box.add_block (fill_block);
            legend_box.append (fill_block.legend_item);
            blocks.set (index, fill_block);
            index++;
        });

        free_space = new FillBlock (ItemDescription.OTHER, storage);
        used_space = new FillBlock (ItemDescription.OTHER, total_usage);
        free_space.add_css_class ("empty-block");
        blocks.set (index++, used_space);
        blocks.set (index++, free_space);
        fillblock_box.add_block (used_space);
        fillblock_box.add_block (free_space);

        update_size_description ();
    }

    private void update_size_description () {
        if (blocks == null) {
            // Called from a property setter during construction
            return;
        }

        uint64 user_size = 0;
        foreach (unowned FillBlock block in blocks.get_values ()) {
            if (block.visible == false || block == free_space || block == used_space)
                continue;
            user_size += block.size;
        }

        uint64 free = storage - user_size;
        if (used_space != null) {
            used_space.size = total_usage - user_size;
        }

        if (free_space != null) {
            free_space.size = free;
        }
        description_label.label = _("%s out of %s can be deleted").printf (GLib.format_size (storage - free, FormatSizeFlags.IEC_UNITS), GLib.format_size (storage, FormatSizeFlags.IEC_UNITS));
        fillblock_box.queue_allocate ();
    }

    /**
     * Update the specified block with a given amount of space.
     *
     * @param description the category to update.
     * @param size the size of the category or 0 to hide.
     */
    public void update_block_size (ItemDescription description, uint64 size) {
        foreach (unowned FillBlock block in blocks.get_values ()) {
            if (block.description == description) {
                block.size = size;
                update_size_description ();
                return;
            }
        }
    }

    /**
     * Lays out the fill blocks horizontally, each one taking up a share of the
     * width proportional to the space it represents.
     */
    internal class FillBlockBox : Gtk.Widget {
        private unowned CustomStorageBar bar;
        private GLib.List<FillBlock> children = new GLib.List<FillBlock> ();

        internal FillBlockBox (CustomStorageBar bar) {
            this.bar = bar;
            overflow = Gtk.Overflow.HIDDEN;
        }

        internal void add_block (FillBlock block) {
            block.set_parent (this);
            children.append (block);
        }

        public override void dispose () {
            foreach (unowned FillBlock block in children) {
                block.unparent ();
            }
            children = new GLib.List<FillBlock> ();
            base.dispose ();
        }

        public override Gtk.SizeRequestMode get_request_mode () {
            return Gtk.SizeRequestMode.CONSTANT_SIZE;
        }

        public override void measure (Gtk.Orientation orientation, int for_size,
                                      out int minimum, out int natural,
                                      out int minimum_baseline, out int natural_baseline) {
            minimum = 0;
            natural = 0;
            minimum_baseline = -1;
            natural_baseline = -1;

            foreach (unowned FillBlock block in children) {
                if (!block.has_size ()) {
                    continue;
                }

                int child_min, child_nat;
                block.measure (orientation, -1, out child_min, out child_nat, null, null);
                if (orientation == Gtk.Orientation.VERTICAL) {
                    minimum = int.max (minimum, child_min);
                    natural = int.max (natural, child_nat);
                }
            }
        }

        public override void size_allocate (int width, int height, int baseline) {
            // lost_size is here because we use truncation so that it is possible for a full device to have a filled bar.
            double lost_size = 0;
            int current_x = 0;
            var storage = bar.storage;

            foreach (unowned FillBlock block in children) {
                if (!block.has_size ()) {
                    continue;
                }

                double block_width = 0;
                if (storage > 0) {
                    block_width = (((double) width) * (double) block.size / (double) storage) + lost_size;
                }
                var allocated_width = (int) GLib.Math.trunc (block_width);
                lost_size = block_width - allocated_width;

                var transform = new Gsk.Transform ().translate (Graphene.Point () { x = current_x, y = 0 });
                block.allocate (allocated_width, height, baseline, transform);

                current_x += allocated_width;
            }
        }
    }

    internal class FillBlock : FillRound {
        private uint64 _size = 0;
        public uint64 size {
            get {
                return _size;
            }
            set {
                _size = value;
                if (_size == 0) {
                    visible = false;
                    legend_item.visible = false;
                } else {
                    visible = true;
                    legend_item.visible = true;
                    size_label.label = GLib.format_size (_size, FormatSizeFlags.IEC_UNITS);
                    queue_resize ();
                }
            }
        }

        public ItemDescription description { public get; construct set; }
        public Gtk.Grid legend_item { public get; private set; }
        private Gtk.Label name_label;
        private Gtk.Label size_label;
        private FillRound legend_fill;

        internal FillBlock (ItemDescription description, uint64 size) {
            Object (size: size, description: description);
            var clas = ItemDescription.get_class (description);
            if (clas != null) {
                add_css_class (clas);
                legend_fill.add_css_class (clas);
            }

            name_label.label = "<b>%s</b>".printf (GLib.Markup.escape_text (ItemDescription.get_name (description)));
        }

        construct {
            legend_item = new Gtk.Grid ();
            legend_item.column_spacing = 6;
            name_label = new Gtk.Label (null);
            name_label.halign = Gtk.Align.START;
            name_label.use_markup = true;
            size_label = new Gtk.Label (null);
            size_label.halign = Gtk.Align.START;
            legend_fill = new FillRound ();
            legend_fill.add_css_class ("legend");
            legend_fill.hexpand = false;
            legend_fill.vexpand = false;
            legend_fill.valign = Gtk.Align.CENTER;
            legend_item.attach (legend_fill, 0, 0, 1, 2);
            legend_item.attach (name_label, 1, 0, 1, 1);
            legend_item.attach (size_label, 1, 1, 1, 1);
        }

        internal bool has_size () {
            return visible && size > 0;
        }
    }

    /**
     * A widget that only draws its CSS background and border; its size and
     * colors are defined in Application.css.
     */
    internal class FillRound : Gtk.Widget {
        internal FillRound () {

        }

        construct {
            add_css_class ("fill-block");
            hexpand = true;
            vexpand = true;
        }
    }
}
