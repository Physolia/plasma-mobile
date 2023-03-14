// SPDX-FileCopyrightText: 2021 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kcm 1.2
import cellularnetworkkcm 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("Available Networks")
    
    property Modem modem
    property Sim sim

    ListView {
        id: listView
        header: ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
            
            MessagesList {
                visible: count != 0
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                model: kcm.messages
            }
        }
        
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            visible: !modem.details.isScanningNetworks && listView.count == 0
            icon.name: "network-mobile-100"
            text: i18n("Current operator: %1", modem.details.operatorName ? modem.details.operatorName : i18n("none"))
            helpfulAction: Kirigami.Action {
                icon.name: "view-refresh"
                text: i18n("Scan For Networks")
                enabled: !modem.details.isScanningNetworks
                onTriggered: modem.details.scanNetworks()
            }
        }
        
        Controls.BusyIndicator {
            anchors.centerIn: parent
            visible: modem.details.isScanningNetworks
            implicitWidth: Kirigami.Units.iconSizes.large
            implicitHeight: implicitWidth
        }
        
        model: modem.details.networks
        
        delegate: Kirigami.SwipeListItem {
            onClicked: {
                if (!modelData.isCurrentlyUsed) {
                    modelData.registerToNetwork();
                    modem.details.scanNetworks();
                }
            }
            
            contentItem: RowLayout {
                Layout.fillWidth: true
                
                ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Heading {
                        level: 3
                        text: modelData.operatorLong + " | " + modelData.operatorShort + "(" + modelData.operatorCode + ")"
                    }
                    Controls.Label {
                        text: modelData.accessTechnology
                    }
                }
                Controls.RadioButton {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    checked: modelData.isCurrentlyUsed
                    onClicked: {
                        if (!modelData.isCurrentlyUsed) {
                            modelData.registerToNetwork();
                            modem.details.scanNetworks();
                        }
                        checked = modelData.isCurrentlyUsed;
                    }
                }
            }
        }
    }
}


