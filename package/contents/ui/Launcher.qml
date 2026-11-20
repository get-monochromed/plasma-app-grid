// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.kwindowsystem as KWindowSystem
import org.kde.layershell as LayerShell
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmaCore.Window {
    id: launcher

    required property PlasmoidItem appletInterface
    required property string favoritesClient
    signal closeRequested()

    readonly property bool onWayland: KWindowSystem.KWindowSystem.isPlatformWayland
    readonly property bool searching: searchField.text.trim().length > 0
    readonly property bool showSystem: tabs.currentIndex === 2 && !searching
    readonly property bool showFavorites: tabs.currentIndex === 0 && !searching
    readonly property int padding: Kirigami.Units.largeSpacing
    readonly property int preferredCellWidth: Math.round(Kirigami.Units.gridUnit * 6.5)
    readonly property int preferredCellHeight: Kirigami.Units.gridUnit * 6
    readonly property int columns: Math.max(1, Math.min(showSystem ? 6 : 7,
        Math.floor(grid.width / (Kirigami.Units.gridUnit * 4))))
    readonly property Kicker.KAStatsFavoritesModel favorites: rootModel.favoritesModel as Kicker.KAStatsFavoritesModel
    readonly property var sessionActions: ["lock-screen", "logout", "switch-user", "suspend", "reboot", "shutdown"]
    property Kicker.AppsModel allAppsModel: null

    title: qsTr("Plasma App Grid")
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: Math.min(7 * preferredCellWidth + 2 * padding + leftPadding + rightPadding,
        Math.max(1, (appletInterface.Screen.desktopAvailableWidth || 1024) - 2 * padding))
    height: Math.min(4 * preferredCellHeight + searchField.implicitHeight + tabs.implicitHeight
        + 5 * padding + topPadding + bottomPadding,
        Math.max(1, (appletInterface.Screen.desktopAvailableHeight || 768) - 2 * padding))
    // Layer shell centers the window within the monitor's work area on Wayland.
    x: onWayland ? 0 : Math.round(appletInterface.screenGeometry.x + (appletInterface.screenGeometry.width - width) / 2)
    y: onWayland ? 0 : Math.round(appletInterface.screenGeometry.y + (appletInterface.screenGeometry.height - height) / 2)

    LayerShell.Window.anchors: LayerShell.Window.AnchorNone
    LayerShell.Window.layer: LayerShell.Window.LayerTop
    LayerShell.Window.exclusionZone: 0
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
    LayerShell.Window.activateOnShow: true
    LayerShell.Window.wantsToBeOnActiveScreen: true
    LayerShell.Window.scope: "plasma-app-grid"

    onVisibleChanged: {
        if (visible) {
            if (!onWayland) {
                requestActivate();
            }
            searchField.forceActiveFocus(Qt.PopupFocusReason);
        } else {
            favoritesMenu.close();
            searchField.clear();
            grid.positionViewAtBeginning();
        }
    }

    onActiveChanged: {
        if (!active && visible) {
            closeRequested();
        }
    }

    onClosing: closeRequested()

    function updateAllApps(): void {
        for (let row = 0; row < rootModel.count; row++) {
            const child = rootModel.modelForRow(row) as Kicker.AppsModel;
            if (child?.description === "KICKER_ALL_MODEL") {
                allAppsModel = child;
                return;
            }
        }
        allAppsModel = null;
    }

    function activateTile(row: int): void {
        if (row < 0 || row >= grid.count) {
            return;
        }

        let launched = false;
        if (showSystem) {
            launched = systemModel.trigger(systemActions.mapToSource(systemActions.index(row, 0)).row, "", null);
        } else if (showFavorites) {
            launched = favorites.trigger(row, "", null);
        } else {
            const sourceRow = apps.mapToSource(apps.index(row, 0)).row;
            launched = allAppsModel !== null && allAppsModel.trigger(sourceRow, "", null);
        }

        if (launched) {
            closeRequested();
        }
    }

    Kicker.RootModel {
        id: rootModel

        appletInterface: launcher.appletInterface
        appNameFormat: 0
        flat: true
        sorted: true
        showSeparators: false
        showRootSeparator: false
        showTopLevelItems: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        highlightNewlyInstalledApps: false

        onRefreshed: launcher.updateAllApps()
        Component.onCompleted: {
            launcher.favorites.initForClient(launcher.favoritesClient);
            launcher.updateAllApps();
        }
    }

    KItemModels.KSortFilterProxyModel {
        id: apps

        sourceModel: launcher.allAppsModel
        filterRoleName: "display"
        filterCaseSensitivity: Qt.CaseInsensitive
        filterString: searchField.text.trim()
    }

    Kicker.SystemModel {
        id: systemModel
        favoritesModel: rootModel.systemFavoritesModel as Kicker.SimpleFavoritesModel
    }

    KItemModels.KSortFilterProxyModel {
        id: systemActions
        sourceModel: systemModel
        filterRowCallback: (row, parentIndex) => {
            const role = systemModel.KItemModels.KRoleNames.role("favoriteId");
            const id = systemModel.data(systemModel.index(row, 0, parentIndex), role);
            return launcher.sessionActions.includes(id);
        }
    }

    mainItem: Item {
        id: surface

        LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Keys.onEscapePressed: {
            if (searchField.text.length > 0) {
                searchField.clear();
                searchField.forceActiveFocus(Qt.ShortcutFocusReason);
            } else {
                launcher.closeRequested();
            }
        }

        // Typing from the tabs or grid continues to work as a launcher search.
        Keys.onPressed: event => {
            if (!searchField.activeFocus && event.text.trim()
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                searchField.forceActiveFocus(Qt.ShortcutFocusReason);
                searchField.insert(searchField.cursorPosition, event.text);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: launcher.padding
            spacing: launcher.padding

            PlasmaExtras.SearchField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: qsTr("Search apps…")
                Accessible.name: placeholderText
                onAccepted: {
                    if (launcher.searching) {
                        launcher.activateTile(0);
                    }
                }
                onTextChanged: {
                    grid.positionViewAtBeginning();
                    grid.currentIndex = 0;
                }

                Keys.onDownPressed: event => {
                    if (grid.count > 0) {
                        grid.currentIndex = 0;
                        grid.forceActiveFocus(Qt.TabFocusReason);
                    } else {
                        event.accepted = false;
                    }
                }
            }

            PlasmaComponents.TabBar {
                id: tabs

                Layout.fillWidth: true
                Accessible.name: qsTr("Launcher sections")
                currentIndex: 1

                onCurrentIndexChanged: {
                    searchField.clear();
                    grid.positionViewAtBeginning();
                    grid.currentIndex = 0;
                }

                PlasmaComponents.TabButton { text: qsTr("Favourites") }
                PlasmaComponents.TabButton { text: qsTr("All Apps") }
                PlasmaComponents.TabButton { text: qsTr("System") }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: grid

                    anchors.fill: parent
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    clip: true
                    focus: false
                    activeFocusOnTab: count > 0
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor(width / launcher.columns)
                    cellHeight: Math.floor(height / Math.max(1, Math.min(4,
                        Math.floor(height / (Kirigami.Units.gridUnit * 4)))))
                    model: launcher.showSystem ? systemActions : (launcher.showFavorites ? launcher.favorites : apps)
                    keyNavigationEnabled: true

                    Accessible.name: launcher.searching ? qsTr("Search results") : (tabs.currentItem as PlasmaComponents.TabButton)?.text ?? ""

                    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                        id: scrollbar
                        parent: grid.parent
                        anchors.top: grid.top
                        anchors.bottom: grid.bottom
                        anchors.right: parent.right
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    Keys.onReturnPressed: launcher.activateTile(currentIndex)
                    Keys.onEnterPressed: launcher.activateTile(currentIndex)
                    Keys.onSpacePressed: launcher.activateTile(currentIndex)
                    Keys.onMenuPressed: {
                        (currentItem as Tile)?.requestMenu();
                    }

                    delegate: Tile {
                        id: tile

                        required property int index
                        required property var model

                        width: grid.cellWidth
                        height: grid.cellHeight
                        text: model.display
                        iconSource: model.decoration
                        selected: GridView.isCurrentItem && grid.activeFocus
                        pinnable: !launcher.showSystem && !!model.favoriteId
                        onClicked: launcher.activateTile(index)
                        onMenuRequested: {
                            grid.currentIndex = index;
                            favoritesMenu.favoriteId = model.favoriteId;
                            favoritesMenu.popup(tile, 0, tile.height);
                        }
                    }
                }

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)
                    visible: grid.count === 0
                    text: {
                        if (launcher.searching) {
                            return qsTr("No matching apps");
                        }
                        if (launcher.showFavorites) {
                            return qsTr("No favourites yet");
                        }
                        return launcher.showSystem ? qsTr("No system actions available") : qsTr("No apps found");
                    }
                    explanation: launcher.showFavorites ? qsTr("Right-click an app to add it here.") : ""
                }
            }
        }

        PlasmaComponents.Menu {
            id: favoritesMenu
            property string favoriteId: ""
            popupType: QQC.Popup.Item

            PlasmaComponents.MenuItem {
                readonly property bool pinned: favoritesMenu.visible && launcher.favorites.isFavorite(favoritesMenu.favoriteId)
                text: pinned ? qsTr("Remove from Favourites") : qsTr("Add to Favourites")
                icon.name: pinned ? "bookmark-remove" : "bookmark-new"

                onTriggered: {
                    if (launcher.favorites.isFavorite(favoritesMenu.favoriteId)) {
                        launcher.favorites.removeFavorite(favoritesMenu.favoriteId);
                    } else {
                        launcher.favorites.addFavorite(favoritesMenu.favoriteId);
                    }
                }
            }
        }
    }
}
