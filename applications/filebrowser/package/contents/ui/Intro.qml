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
import org.kde.plasma.mobilecomponents 0.1 as MobileComponents


PlasmaComponents.Page {
    id: introPage
    objectName: "introPage"

    tools: Item {
        width: parent.width
        height: childrenRect.height

        MobileComponents.ViewSearch {
            id: searchBox
            anchors.centerIn: parent

            onSearchQueryChanged: {
                metadataModel.extraParameters["nfo:fileName"] = searchBox.searchQuery
                busy = (searchBox.searchQuery.length > 0)
                push("")
            }
        }
    }

    anchors {
        fill: parent
        topMargin: toolBar.height
    }

    function push(category)
    {
        var page = mainStack.push(Qt.createComponent("Browser.qml"))
        metadataModel.resourceType = category
    }

    function iconFor(category)
    {
        switch (category) {
        case "nfo:Bookmark":
            return "folder-bookmark"
        case "nfo:Audio":
            return "folder-sound"
        case "nfo:Archive":
            return "folder-tar"
        case "nco:Contact":
            return "folder-image-people"
        case "nfo:Document":
            return "folder-documents"
        case "nfo:Image":
            return "folder-image"
        case "nfo:Video":
            return "folder-video"
            break;
        }
    }

    Image {
        id: browserFrame
        z: 100
        source: "image://appbackgrounds/standard"
        fillMode: Image.Tile
        anchors.fill: parent

        MobileComponents.IconGrid {
            id: introGrid
            anchors.fill: parent

            model: MetadataModels.MetadataCloudModel {
                cloudCategory: "rdf:type"
                resourceType: "nfo:FileDataObject"
                minimumRating: metadataModel.minimumRating
                allowedCategories: userTypes.userTypes.filter(function(val) {
                    return val != "nfo:Application";
                })
            }

            delegate: MobileComponents.ResourceDelegate {
                className: "FileDataObject"
                genericClassName: "FileDataObject"
                property string decoration: iconFor(model["label"])

                property string label: i18n("%1 (%2)", userTypes.typeNames[model["label"]], model["count"])

                width: introGrid.delegateWidth
                height: introGrid.delegateHeight

                onClicked: push(model["label"])
            }
        }
    }
}

