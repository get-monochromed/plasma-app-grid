// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

PlasmaComponents.ItemDelegate {
    id: tile

    required property int index
    required property var iconSource
    required property int preferredIconSize
    required property bool selected
    required property bool menuEnabled
    signal menuRequested(point position)

    function requestMenu(position = Qt.point(width / 2, height / 2)): void {
        if (menuEnabled) {
            menuRequested(position);
        }
    }

    readonly property int iconSize: Math.max(1, Math.min(preferredIconSize,
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
            roundToIconSize: false
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
        pressed: tile.selected || tile.down
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: tile.menuEnabled
        onTapped: eventPoint => tile.requestMenu(eventPoint.position)
    }

    PlasmaComponents.ToolTip.visible: tile.hovered && caption.truncated
    PlasmaComponents.ToolTip.text: tile.text
    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
}
