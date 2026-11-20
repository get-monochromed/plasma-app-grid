// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

PlasmaComponents.ItemDelegate {
    id: tile

    required property var iconSource
    required property bool selected
    required property bool pinnable
    signal menuRequested()

    function requestMenu(): void {
        if (pinnable) {
            menuRequested();
        }
    }

    readonly property int iconSize: Math.max(1, Math.min(Kirigami.Units.iconSizes.huge,
        width - 2 * padding, height - 2 * padding - labelHeight - Kirigami.Units.smallSpacing))

    readonly property int labelHeight: Math.ceil(2 * labelMetrics.lineSpacing)

    padding: Kirigami.Units.smallSpacing
    focusPolicy: Qt.NoFocus
    hoverEnabled: true

    FontMetrics {
        id: labelMetrics
        font: caption.font
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: tile.iconSize
            Layout.preferredHeight: tile.iconSize
            source: tile.iconSource
            fallback: "application-x-executable"
        }

        PlasmaComponents.Label {
            id: caption
            Layout.fillWidth: true
            Layout.preferredHeight: tile.labelHeight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            text: tile.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }
    }

    background: PlasmaExtras.Highlight {
        anchors.fill: parent
        active: tile.selected
        hovered: tile.hovered
        pressed: tile.down
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: tile.pinnable
        onTapped: tile.requestMenu()
    }

    PlasmaComponents.ToolTip.visible: tile.hovered && caption.truncated
    PlasmaComponents.ToolTip.text: tile.text
    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
}
