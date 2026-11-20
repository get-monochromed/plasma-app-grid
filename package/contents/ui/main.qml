// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: applet

    property bool launcherOpen: false

    function toggleLauncher(): void {
        launcherLoader.active = true;
        launcherOpen = !launcherOpen;
    }

    activationTogglesExpanded: false
    preferredRepresentation: fullRepresentation
    toolTipMainText: Plasmoid.title

    fullRepresentation: PlasmaComponents.ToolButton {
        implicitWidth: Kirigami.Units.iconSizes.large
        implicitHeight: implicitWidth
        Accessible.name: Plasmoid.title
        icon.name: Plasmoid.icon
        checked: applet.launcherOpen
        onClicked: applet.toggleLauncher()
    }

    Loader {
        id: launcherLoader
        active: false
        sourceComponent: Launcher {
            appletInterface: applet
            favoritesClient: Plasmoid.pluginName + ".favorites.instance-" + Plasmoid.id
            visible: applet.launcherOpen
            onCloseRequested: applet.launcherOpen = false
        }
    }

    Connections {
        target: Plasmoid

        function onActivated(): void {
            applet.toggleLauncher();
        }

        function onUserConfiguringChanged(): void {
            if (Plasmoid.userConfiguring) {
                applet.launcherOpen = false;
            }
        }
    }
}
