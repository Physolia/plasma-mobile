// -*- coding: iso-8859-1 -*-
/*
 *   Copyright 2011 Sebastian K�gler <sebas@kde.org>
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

import QtQuick 1.0
import org.kde.plasma.core 0.1 as PlasmaCore

Item {
    width: 400
    height: 500

    Column {
        anchors.fill: parent
        Text {
            width: parent.width
            id: title
            text: i18n("<h1>Cool and Useful Apps</h1>")
            color: theme.textColor
            style: Text.Sunken
            styleColor: theme.backgroundColor
        }

        Text {
            id: description
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n("<p>Plasma Active comes with a set of apps to make your day to day tasks easier.</p>")
            color: theme.textColor
            //style: Text.Sunken
            styleColor: theme.backgroundColor
        }

        Image {
            id: exampleImage
            scale: 0.4
            source: plasmoid.file("images", "example_image.png")
            anchors.top: description.top
            anchors.right: description.right
        }
    }
}
