/*
 *  Copyright 2015 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.1
import QtQuick.Layouts 1.3
import QtQml.Models 2.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.plasma.workspace.components 2.0 as PlasmaWorkspace
import org.kde.taskmanager 0.1 as TaskManager

import "LayoutManager.js" as LayoutManager

import "quicksettings"
import "indicators" as Indicators

PlasmaCore.ColorScope {
    id: root
    width: 480
    height: 30
    //colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

    Plasmoid.backgroundHints: showingApp ? PlasmaCore.Types.StandardBackground : PlasmaCore.Types.NoBackground

    property Item toolBox
    property int buttonHeight: width/4
    property bool reorderingApps: false
    property var layoutManager: LayoutManager

    readonly property bool showingApp: tasksModel.activeTask && tasksModel.activeTask.valid && !tasksModel.data(tasksModel.activeTask, TaskManager.AbstractTasksModel.IsFullScreen)

    Containment.onAppletAdded: {
        addApplet(applet, x, y);
        LayoutManager.save();
    }

    function addApplet(applet, x, y) {
        var compactContainer = compactContainerComponent.createObject(appletIconsRow)
        print("Applet added: " + applet + " " + applet.title)

        applet.parent = compactContainer;
        compactContainer.applet = applet;
        applet.anchors.fill = compactContainer;
        applet.visible = true;
        if (applet.pluginName == "org.kde.phone.notifications") {
            
        }
        //FIXME: make a way to instantiate fullRepresentationItem without the open/close dance
        applet.expanded = true
        applet.expanded = false

        var fullContainer = fullContainerComponent.createObject(fullRepresentationView.contentItem);
        applet.fullRepresentationItem.parent = fullContainer;
        fullContainer.applet = applet;
        applet.fullRepresentationItem.anchors.fill = fullContainer;
    }

    Component.onCompleted: {
        LayoutManager.plasmoid = plasmoid;
        LayoutManager.root = root;
        LayoutManager.layout = appletsLayout;
        LayoutManager.restore();
    }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled

        screenGeometry: plasmoid.screenGeometry
        filterByScreen: plasmoid.configuration.showForCurrentScreenOnly

    }

    PlasmaCore.DataSource {
        id: statusNotifierSource
        engine: "statusnotifieritem"
        interval: 0
        onSourceAdded: {
            connectSource(source)
        }
        Component.onCompleted: {
            connectedSources = sources
        }
    }

    RowLayout {
        id: appletsLayout
        Layout.minimumHeight: Math.max(root.height, Math.round(Layout.preferredHeight / root.height) * root.height)
    }
 
    //todo: REMOVE?
    Component {
        id: compactContainerComponent
        Item {
            property Item applet
            visible: applet && (applet.status != PlasmaCore.Types.HiddenStatus && applet.status != PlasmaCore.Types.PassiveStatus)
            Layout.fillHeight: true
            Layout.minimumWidth: applet && applet.compactRepresentationItem ? Math.max(applet.compactRepresentationItem.Layout.minimumWidth, appletIconsRow.height) : appletIconsRow.height
            Layout.maximumWidth: Layout.minimumWidth
        }
    }

    Component {
        id: fullContainerComponent
        Item {
            id: fullContainer
            property Item applet
            visible: applet && (applet.status != PlasmaCore.Types.HiddenStatus && applet.status != PlasmaCore.Types.PassiveStatus)
            height: parent.height
            width: visible ? fullRepresentationView.width : 0
            Layout.minimumHeight: applet && applet.switchHeight
            onVisibleChanged: {
                if (visible) {
                    for (var i = 0; i < fullRepresentationModel.count; ++i) {
                        if (fullRepresentationModel.get(i) === this) {
                            return;
                        }
                    }
                    fullRepresentationModel.append(this);
                    fullRepresentationView.forceLayout();

                    fullRepresentationView.currentIndex = ObjectModel.index;
                    fullRepresentationView.positionViewAtIndex(ObjectModel.index, ListView.SnapPosition)
                } else if (ObjectModel.index >= 0) {
                    fullRepresentationModel.remove(ObjectModel.index);
                    fullRepresentationView.forceLayout();
                }
            }
            Connections {
                target: fullContainer.applet
                onActivated: {
                    if (!visible) {
                        return;
                    }
                    fullRepresentationView.currentIndex = ObjectModel.index;
                }
            }
        }
    }

    PlasmaCore.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 60 * 1000
    }

    Item {
        z: 1
        //parent: slidingPanel.visible && !slidingPanel.wideScreen ? panelContents : root
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: root.height
        Rectangle {
            anchors.fill: parent
            color: PlasmaCore.ColorScope.backgroundColor
            opacity: showingApp
        }

        Loader {
            id: strengthLoader
            height: parent.height
            width: item ? item.width : 0
            source: Qt.resolvedUrl("indicators/SignalStrength.qml")
        }

        Row {
            id: sniRow
            anchors.left: strengthLoader.right
            height: parent.height
            Repeater {
                id: statusNotifierRepeater
                model: PlasmaCore.SortFilterModel {
                    id: filteredStatusNotifiers
                    filterRole: "Title"
                    sourceModel: PlasmaCore.DataModel {
                        dataSource: statusNotifierSource
                    }
                }

                delegate: TaskWidget {
                }
            }
        }

        PlasmaComponents.Label {
            id: clock
            anchors.fill: parent
            text: Qt.formatTime(timeSource.data.Local.DateTime, "hh:mm")
            color: PlasmaCore.ColorScope.textColor
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.pixelSize: height / 2
        }

        RowLayout {
            id: appletIconsRow
            anchors {
                bottom: parent.bottom
                right: simpleIndicatorsLayout.left
            }
            height: parent.height
        }

        //TODO: pluggable
        RowLayout {
            id: simpleIndicatorsLayout
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: units.smallSpacing
            }
            Indicators.Bluetooth {}
            Indicators.Wifi {}
            Indicators.Battery {}
        }
    }
    MouseArea {
        z: 99
        property int oldMouseY: 0

        anchors.fill: parent
        onPressed: {
            slidingPanel.drawerX = Math.min(Math.max(0, mouse.x - slidingPanel.drawerWidth/2), slidingPanel.width - slidingPanel.drawerWidth)
            slidingPanel.userInteracting = true;
            oldMouseY = mouse.y;
            slidingPanel.offset = 0//units.gridUnit * 2;
            slidingPanel.showFullScreen();
        }
        onPositionChanged: {
            slidingPanel.offset = slidingPanel.offset + (mouse.y - oldMouseY);
            oldMouseY = mouse.y;
        }
        onReleased: {
            slidingPanel.userInteracting = false;
            slidingPanel.updateState();
        }
    }

    SlidingPanel {
        id: slidingPanel
        width: plasmoid.availableScreenRect.width
        height: plasmoid.availableScreenRect.height
        openThreshold: units.gridUnit * 10
        headerHeight: root.height

        contentItem: Item {
            id: panelContents
            anchors.fill: parent
            implicitWidth: quickSettingsParent.implicitWidth
            implicitHeight: quickSettingsParent.implicitHeight

            DrawerBackground {
                id: quickSettingsParent
                anchors.fill: parent
                z: 1
                contentItem: QuickSettings {
                    id: quickSettings
                }
            }

            DrawerBackground {
                id: fullRepresentationDrawer
                anchors {
                    left: parent.left
                    right: parent.right
                }
                y: quickSettingsParent.height - height * (1-opacity)
                opacity: slidingPanel.offset/panelContents.height
                height: Math.min(plasmoid.screenGeometry.height - quickSettingsParent.y - quickSettingsParent.height, implicitHeight)
                contentItem: ListView {
                    id: fullRepresentationView

                    implicitHeight: 300
                    cacheBuffer: width * 100
                    highlightFollowsCurrentItem: true
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: units.longDuration
                    snapMode: ListView.SnapOneItem
                    model: ObjectModel {
                        id: fullRepresentationModel
                    }
                    orientation: ListView.Horizontal


                    //implicitHeight: fullRepresentationLayout.implicitHeight
                    clip: true

                }
            }
            
        }
        footer: DrawerBackground {
            id: bottomBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            opacity: fullRepresentationDrawer.opacity
            visible: fullRepresentationModel.count > 1
            //height: 40
            z: 100
            contentItem: RowLayout {
                PlasmaComponents.TabBar {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    position: PlasmaComponents.TabBar.Footer
                    
                    Repeater {
                        model: fullRepresentationView.count
                        delegate: PlasmaComponents.TabButton {
                            implicitHeight: parent.height
                            text: fullRepresentationModel.get(index).applet.title
                            checked: fullRepresentationView.currentIndex === index
                        
                            onClicked: fullRepresentationView.currentIndex = index
                        }
                    }
                }
                PlasmaComponents.ToolButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    icon.name: "paint-none"
                    onClicked: slidingPanel.close();
                }
            }
        }
    }
}
