# Plasma App Grid

A centered KDE Plasma application launcher with the active Plasma theme’s dialog frame, blur, and shadow. It shows **Favourites**, **All Apps**, and **System**. The app grid shows four visible rows, with more rows available by scrolling. Two installable variants offer five columns with larger icons or six columns with smaller icons.

## Install

Use KDE Plasma 6.8 or later with the Plasma Desktop and Layer Shell Qt QML packages. Plasma 6.8.3 on Wayland is the development target. Install the widget from this checkout as your regular user:

```sh
kpackagetool6 --type Plasma/Applet --install package
```

In Plasma, open **Add Widgets**, find **Plasma App Grid**, and drag it onto your panel. To use it in your current launcher’s slot, right-click that launcher, open **Show Alternatives**, and select **Plasma App Grid**. You can assign a shortcut through the widget’s keyboard shortcut settings.

To install **Plasma App Grid (6 Columns)** alongside the five-column launcher, build its package with Python 3:

```sh
build_dir="$(mktemp -d)"
python3 scripts/build-six-columns.py "$build_dir/package"
kpackagetool6 --type Plasma/Applet --install "$build_dir/package"
```

Both names appear under **Show Alternatives** and **Add Widgets**. Both use the same Plasma favourites.

To update either variant, build its package if needed and use `--upgrade` in place of `--install`, then restart Plasma Shell to load the updated widget. On a systemd-based Plasma session, run:

```sh
systemctl --user restart plasma-plasmashell.service
```

To remove a variant, pass its plugin ID to `kpackagetool6 --type Plasma/Applet --remove`. Use `io.github.get_monochromed.plasma_app_grid` for five columns or `io.github.get_monochromed.plasma_app_grid.six_columns` for six.

## Use

- **Favourites** shows Plasma’s shared application favourites for the current activity. Right-click an app and choose **Add to Favourites** or **Remove from Favourites**.
- **All Apps** shows installed apps in alphabetical order. Start typing to filter by app name. Press **Enter** to open the first match, or use **Down** and the arrow keys to select a tile.
- **System** shows Lock, Log Out, Switch User, Sleep, Restart, and Shut Down when supported by the session. Plasma handles the actions and its normal confirmation settings.
- **Esc** clears the current search, then closes the launcher.

The applet uses the Kicker application, favourites, and session models shared by KDE’s [Kickoff and Application Dashboard](https://invent.kde.org/plasma/plasma-desktop/-/tree/master/applets). These internal Plasma interfaces can change between releases.

Licensed under GPL-2.0-or-later.
