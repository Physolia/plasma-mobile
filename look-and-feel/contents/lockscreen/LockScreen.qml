/*
 * SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
 * SPDX-FileCopyrightText: 2021-2022 Devin Lin <espidev@gmail.com>
 * 
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.notificationmanager 1.1 as Notifications

PlasmaCore.ColorScope {
    id: root

    property string password
    
    property bool isWidescreen: root.height < root.width * 0.75
    property bool notificationsShown: false
    
    readonly property bool drawerOpen: flickable.openFactor >= 1
    
    function askPassword() {
        flickable.goToOpenPosition();
    }
    
    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
    anchors.fill: parent
    
    Notifications.WatchedNotificationsModel {
        id: notifModel
    }
    
    // wallpaper blur 
    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: WallpaperBlur {
            source: wallpaper
            blur: root.notificationsShown || root.drawerOpen // only blur once animation finished for performance
        }
    }

    FlickContainer {
        id: flickable
        anchors.fill: parent
        
        property real openFactor: position / keypadHeight
        
        keypadHeight: PlasmaCore.Units.gridUnit * 20
        
        Component.onCompleted: {
            flickable.position = 0;
            flickable.goToClosePosition();
        }
        
        onPositionChanged: {
            if (position > keypadHeight) {
                position = keypadHeight;
            } else if (position < 0) {
                position = 0;
            }
        }
        
        Item {
            width: flickable.width
            height: flickable.height
            y: flickable.contentY // effectively anchored to the screen
            
            // header bar
            StatusBarComponent {
                id: statusBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                opacity: 1 - flickable.openFactor
            }
            
            LockScreenNarrowContent {
                id: phoneComponent
                visible: !isWidescreen
                active: visible
                opacity: 1 - flickable.openFactor
                
                fullHeight: root.height
                
                anchors.top: parent.top
                anchors.bottom: scrollUpIcon.top
                anchors.left: parent.left
                anchors.right: parent.right
                
                // move while swiping up
                transform: Translate { y: Math.round((1 - phoneComponent.opacity) * (-root.height / 6)) }
            }
            
            LockScreenWideScreenContent {
                id: tabletComponent
                visible: isWidescreen
                active: visible
                opacity: 1 - flickable.openFactor
                
                anchors.top: statusBar.bottom
                anchors.bottom: scrollUpIcon.top
                anchors.left: parent.left
                anchors.right: parent.right
                
                // move while swiping up
                transform: Translate { y: Math.round((1 - phoneComponent.opacity) * (-root.height / 6)) }
            }
            
            // scroll up icon
            PlasmaCore.IconItem {
                id: scrollUpIcon
                anchors.bottom: parent.bottom
                anchors.bottomMargin: PlasmaCore.Units.gridUnit + flickable.position * 0.5
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: PlasmaCore.Units.iconSizes.smallMedium
                implicitHeight: PlasmaCore.Units.iconSizes.smallMedium 
                opacity: 1 - flickable.openFactor
                
                colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
                source: "arrow-up"
            }
            
            // password keypad
            ColumnLayout {
                id: passwordLayout
                anchors.bottom: parent.bottom
                transform: Translate { y: flickable.keypadHeight - flickable.position }
                
                width: parent.width
                spacing: PlasmaCore.Units.gridUnit
                
                // scroll down icon
                PlasmaCore.IconItem {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: PlasmaCore.Units.iconSizes.smallMedium
                    implicitHeight: PlasmaCore.Units.iconSizes.smallMedium
                    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup
                    source: "arrow-down"
                    opacity: Math.sin((Math.PI / 2) * flickable.openFactor + 1.5 * Math.PI) + 1
                }

                Keypad {
                    id: keypad
                    Layout.fillWidth: true
                    
                    focus: true
                    swipeProgress: flickable.openFactor
                    onPasswordChanged: flickable.goToOpenPosition()
                }
            }
        }
    }
}
