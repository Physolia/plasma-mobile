/*
 *  SPDX-FileCopyrightText: 2021 Devin Lin <devin@kde.org>
 *  SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQml.Models 2.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.plasma.private.nanoshell 2.0 as NanoShell
import org.kde.plasma.private.mobileshell 1.0 as MobileShell

import org.kde.taskmanager 0.1 as TaskManager
import org.kde.notificationmanager 1.0 as NotificationManager

Item {
    id: root
    
    // only opaque if there are no maximized windows on this screen
    readonly property bool showingApp: visibleMaximizedWindowsModel.count > 0
    readonly property color backgroundColor: topPanel.colorScopeColor

    Plasmoid.backgroundHints: showingApp ? PlasmaCore.Types.StandardBackground : PlasmaCore.Types.NoBackground
    
    width: 480
    height: PlasmaCore.Units.gridUnit
    
//BEGIN API implementation

    Binding {
        target: MobileShell.TopPanelControls
        property: "panelHeight"
        value: root.height
    }
    Binding {
        target: MobileShell.TopPanelControls
        property: "inSwipe"
        value: drawer.actionDrawer.dragging
    }
    Binding {
        target: MobileShell.TopPanelControls
        property: "actionDrawerVisible"
        value: drawer.visible
    }
    
    Connections {
        target: MobileShell.TopPanelControls
        
        function onStartSwipe() {
            swipeArea.startSwipe();
        }
        function onEndSwipe() {
            swipeArea.endSwipe();
        }
        function onRequestRelativeScroll(offsetY) {
            swipeArea.updateOffset(offsetY);
        }
        function onCloseActionDrawer() {
            drawer.actionDrawer.close();
        }
        function onOpenActionDrawer() {
            drawer.actionDrawer.open();
        }
    }
    
//END API implementation
    
    Component.onCompleted: {
        // we want to bind global volume shortcuts here
        MobileShell.VolumeProvider.bindShortcuts = true;
    }
    
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    PlasmaCore.SortFilterModel {
        id: visibleMaximizedWindowsModel
        filterRole: 'IsMinimized'
        filterRegExp: 'false'
        sourceModel: TaskManager.TasksModel {
            id: tasksModel
            filterByVirtualDesktop: true
            filterByActivity: true
            filterNotMaximized: true
            filterByScreen: true
            filterHidden: true

//             screenGeometry: panel.screenGeometry
            virtualDesktop: virtualDesktopInfo.currentDesktop
            activity: activityInfo.currentActivity

            groupMode: TaskManager.TasksModel.GroupDisabled
        }
    }
    
    // top panel component
    MobileShell.StatusBar {
        id: topPanel
        anchors.fill: parent
        
        showDropShadow: !root.showingApp
        colorGroup: root.showingApp ? PlasmaCore.Theme.HeaderColorGroup : PlasmaCore.Theme.ComplementaryColorGroup
        backgroundColor: !root.showingApp ? "transparent" : root.backgroundColor
    }
    
    MobileShell.ActionDrawerOpenSurface {
        id: swipeArea
        actionDrawer: drawer.actionDrawer
        anchors.fill: parent
    }
    
    // swipe-down drawer component
    MobileShell.ActionDrawerWindow {
        id: drawer
        
        actionDrawer.notificationSettings: NotificationManager.Settings {}
        actionDrawer.notificationModel: NotificationManager.Notifications {
            showExpired: true
            showDismissed: true
            showJobs: drawer.actionDrawer.notificationSettings.jobsInNotifications
            sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
            groupMode: NotificationManager.Notifications.GroupApplicationsFlat
            groupLimit: 2
            expandUnread: true
            blacklistedDesktopEntries: drawer.actionDrawer.notificationSettings.historyBlacklistedApplications
            blacklistedNotifyRcNames: drawer.actionDrawer.notificationSettings.historyBlacklistedServices
            urgencies: {
                var urgencies = NotificationManager.Notifications.CriticalUrgency
                            | NotificationManager.Notifications.NormalUrgency;
                if (drawer.actionDrawer.notificationSettings.lowPriorityHistory) {
                    urgencies |= NotificationManager.Notifications.LowUrgency;
                }
                return urgencies;
            }
        }
    }
}
