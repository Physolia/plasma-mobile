/*
 *   Copyright 2011 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 1.1
import org.kde.metadatamodels 0.1 as MetadataModels
import org.kde.plasma.components 0.1 as PlasmaComponents
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.mobilecomponents 0.1 as MobileComponents


Item {
    anchors.fill: parent

    Column {
        id: toolsColumn
        spacing: 4
        TypeFilter {
            
        }




        PlasmaComponents.Label {
            text: "<b>"+i18n("Rating")+"</b>"
        }

        MobileComponents.Rating {
            anchors.horizontalCenter: parent.horizontalCenter
            onScoreChanged: metadataModel.minimumRating = score
        }




        PlasmaComponents.Label {
            text: "<b>"+i18n("Tags")+"</b>"
            visible: tagCloud.count > 0
        }
        Column {
            spacing: 4
            anchors {
                left: parent.left
                leftMargin: theme.defaultFont.mSize.width
            }
            Repeater {
                model: MetadataModels.MetadataCloudModel {
                    id: tagCloud
                    cloudCategory: "nao:hasTag"
                    resourceType: metadataModel.resourceType
                    minimumRating: metadataModel.minimumRating
                }
                delegate: PlasmaComponents.CheckBox {
                    text: i18n("%1 (%2)", model["label"], model["count"])
                    visible: model["label"] != undefined
                    onCheckedChanged: {
                        var tags = metadataModel.tags
                        if (checked) {
                            tags[tags.length] = model["label"];
                            metadataModel.tags = tags
                        } else {
                            for (var i = 0; i < tags.length; ++i) {
                                if (tags[i] == model["label"]) {
                                    tags.splice(i, 1);
                                    metadataModel.tags = tags
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    PlasmaComponents.Button {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        text: i18n("Timeline")
        onClicked: sidebarStack.push(Qt.createComponent("TimelineSidebar.qml"))
    }
}
