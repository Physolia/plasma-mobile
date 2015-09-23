/*
 *   Copyright 2011 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.draganddrop 2.0
import org.kde.kquickcontrolsaddons 2.0

Item {
    id: delegate

    readonly property string pluginName: model.pluginName

    width: list.cellWidth
    height: list.cellHeight



    ColumnLayout {
        id: mainLayout
        spacing: units.smallSpacing
        anchors {
            left: parent.left
            right: parent.right
            //bottom: parent.bottom
            margins: units.smallSpacing * 2
            rightMargin: units.smallSpacing * 2 // don't cram the text to the border too much
            verticalCenter: parent.verticalCenter
        }

        Item {
            id: iconContainer
            width: units.iconSizes.enormous
            height: width
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: iconWidget
                anchors.fill: parent
                QIconItem {
                    anchors.fill: parent
                    icon: model.decoration
                    visible: model.screenshot == ""
                }
                Image {
                    width: units.iconSizes.enormous
                    height: width
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: model.screenshot
                }
            }


            Item {
                id: badgeMask
                anchors.fill: parent

                Rectangle {
                    x: Math.round(-units.smallSpacing * 1.5 / 2)
                    y: x
                    width: runningBadge.width + Math.round(units.smallSpacing * 1.5)
                    height: width
                    radius: height
                    visible: running
                }
            }

            Rectangle {
                id: runningBadge
                width: height
                height: Math.round(theme.mSize(countLabel.font).height * 1.3)
                radius: height
                color: theme.highlightColor
                visible: running
                onVisibleChanged: maskShaderSource.scheduleUpdate()

                PlasmaComponents.Label {
                    id: countLabel
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: running
                }
            }

            ShaderEffect {
                anchors.fill: parent
                property var source: ShaderEffectSource {
                    sourceItem: iconWidget
                    hideSource: true
                    live: false
                }
                property var mask: ShaderEffectSource {
                    id: maskShaderSource
                    sourceItem: badgeMask
                    hideSource: true
                    live: false
                }

                supportsAtlasTextures: true

                fragmentShader: "
                    varying highp vec2 qt_TexCoord0;
                    uniform highp float qt_Opacity;
                    uniform lowp sampler2D source;
                    uniform lowp sampler2D mask;
                    void main() {
                        gl_FragColor = texture2D(source, qt_TexCoord0.st) * (1.0 - (texture2D(mask, qt_TexCoord0.st).a)) * qt_Opacity;
                    }
                "
            }
        }
        PlasmaExtras.Heading {
            id: heading
            Layout.fillWidth: true
            level: 4
            text: model.name
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            lineHeight: 0.95
            horizontalAlignment: Text.AlignHCenter
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            // otherwise causes binding loop due to the way the Plasma sets the height
            height: implicitHeight
            text: model.description
            font.pointSize: theme.smallestFont.pointSize
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: heading.lineCount === 1 ? 3 : 2
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            widgetExplorer.addApplet(pluginName);
            main.closed()
        }
        onEntered: list.currentIndex = index
        onExited: list.currentIndex = -1
    }

}
