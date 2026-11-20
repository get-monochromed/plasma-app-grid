/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
    SPDX-FileCopyrightText: 2024 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: root

    property Tile tile
    property var actions: []
    readonly property bool opened: menu.status !== PlasmaExtras.Menu.Closed
    signal actionTriggered(string actionId, var argument)

    visible: false

    function open(tile: Tile, position: point, actions: var): void {
        if (!actions.length) {
            return;
        }

        menu.close();
        root.tile = tile;
        root.actions = actions;
        menu.open(Math.round(position.x), Math.round(position.y));
    }

    function close(): void {
        menu.close();
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: root.tile
    }

    Instantiator {
        model: root.actions
        delegate: menuItemComponent
        onObjectAdded: (_, object) => menu.addMenuItem(object)
        onObjectRemoved: (_, object) => menu.removeMenuItem(object)
    }

    Component {
        id: submenuComponent
        PlasmaExtras.Menu {}
    }

    Component {
        id: menuItemComponent

        PlasmaExtras.MenuItem {
            id: item

            required property var modelData
            readonly property PlasmaExtras.Menu submenu: modelData.subActions
                ? submenuComponent.createObject(item, { visualParent: action }) as PlasmaExtras.Menu
                : null

            text: modelData.text ?? ""
            icon: modelData.icon ?? null
            enabled: modelData.type !== "title" && (modelData.enabled ?? true)
            separator: modelData.type === "separator"
            section: modelData.type === "title"
            checkable: modelData.checkable ?? false
            checked: modelData.checked ?? false

            readonly property Instantiator submenuItems: Instantiator {
                active: item.submenu !== null
                model: item.modelData.subActions
                delegate: menuItemComponent
                onObjectAdded: (_, object) => item.submenu.addMenuItem(object)
                onObjectRemoved: (_, object) => item.submenu.removeMenuItem(object)
            }

            onClicked: {
                if (modelData.actionId) {
                    root.actionTriggered(modelData.actionId, modelData.actionArgument ?? null);
                }
            }
        }
    }
}
