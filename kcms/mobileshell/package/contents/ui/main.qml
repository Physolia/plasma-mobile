/*
 * SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kcm 1.3 as KCM
import org.kde.plasma.private.mobileshell 1.0 as MobileShell

import "mobileform" as MobileForm

KCM.SimpleKCM {
    id: root

    title: i18n("Shell")

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit
    
    ColumnLayout {
        spacing: 0
        width: root.width
        
        MobileForm.FormCard {
            Layout.fillWidth: true
            
            contentItem: ColumnLayout {
                spacing: 0
                
                MobileForm.FormCardHeader {
                    title: i18n("Home Screen")
                }
                
                MobileForm.FormButtonDelegate {
                    text: i18n("Launcher type")
                    description: i18n("Change the homescreen application launcher.")
                    onClicked: kcm.push("SelectHomeScreen.qml");
                }
            }
        }
        
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            
            contentItem: ColumnLayout {
                spacing: 0
                
                MobileForm.FormCardHeader {
                    title: i18n("Navigation Panel")
                }
                
                MobileForm.FormSwitchDelegate {
                    text: i18n("Gesture-only Mode")
                    description: i18n("Whether to hide the navigation panel.")
                    checked: !kcm.navigationPanelEnabled
                    onCheckedChanged: {
                        if (checked != !kcm.navigationPanelEnabled) {
                            kcm.navigationPanelEnabled = !checked;
                        }
                    }
                }
            }
        }
        
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            
            contentItem: ColumnLayout {
                spacing: 0
                
                MobileForm.FormCardHeader {
                    title: i18n("Quick Settings")
                    subtitle: i18n("Customize the order of quick settings in the pull-down panel.")
                }
                
                ListView {
                    id: enabledQSListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    interactive: false
                    
                    model: savedQuickSettings.enabledModel
                    
                    moveDisplaced: Transition {
                        YAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                    
                    Component {
                        id: listItemComponent
                        
                        MobileForm.AbstractFormDelegate {
                            id: qsDelegate
                            
                            contentItem: RowLayout {
                                Kirigami.ListItemDragHandle {
                                    Layout.rightMargin: Kirigami.Units.largeSpacing
                                    listItem: qsDelegate
                                    listView: enabledQSListView
                                    onMoveRequested: savedQuickSettings.enabledModel.moveRow(oldIndex, newIndex)
                                }
                                
                                Kirigami.Icon {
                                    visible: model.icon !== ""
                                    source: model.icon
                                    Layout.rightMargin: (model.icon !== "") ? Kirigami.Units.largeSpacing : 0
                                    implicitWidth: (model.icon !== "") ? Kirigami.Units.iconSizes.small : 0
                                    implicitHeight: (model.icon !== "") ? Kirigami.Units.iconSizes.small : 0
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing
                                    
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        text: model.name
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                    
                    delegate: Kirigami.DelegateRecycler {
                        width: enabledQSListView.width
                        sourceComponent: listItemComponent
                    }
                }
            }
                
            MobileShell.SavedQuickSettings {
                id: savedQuickSettings
            }
        }
    }
}
