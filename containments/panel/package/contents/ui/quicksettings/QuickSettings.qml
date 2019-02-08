/*
 *   Copyright 2015 Marco Martin <notmart@gmail.com>
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

import QtQuick 2.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root

    function toggleAirplane() {
        print("toggle airplane mode")
    }

    function toggleTorch() {
        plasmoid.nativeInterface.toggleTorch()
    }

    function requestShutdown() {
        print("Shutdown requested, depends on ksmserver running");
        var service = pmSource.serviceForSource("PowerDevil");
        //note the strange camelCasing is intentional
        var operation = service.operationDescription("requestShutDown");
        return service.startOperationCall(operation);
    }

    function addPlasmoid(applet) {
        settingsModel.append({"icon": applet.icon,
                              "text": applet.title,
                              "enabled": false,
                              "applet": applet,
                              "settingsCommand": "",
                              "toggleFunction": ""});
    }

    signal plasmoidTriggered(var applet, var id)
    Layout.minimumHeight: flow.implicitHeight + units.largeSpacing*2

    property int screenBrightness
    property bool disableBrightnessUpdate: true
    readonly property int maximumScreenBrightness: pmSource.data["PowerDevil"] ? pmSource.data["PowerDevil"]["Maximum Screen Brightness"] || 0 : 0

    onScreenBrightnessChanged: {
        if(!disableBrightnessUpdate) {
            var service = pmSource.serviceForSource("PowerDevil");
            var operation = service.operationDescription("setBrightness");
            operation.brightness = screenBrightness;
            operation.silent = true
            service.startOperationCall(operation);
        }
    }

    PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["PowerDevil"]
        onSourceAdded: {
            if (source === "PowerDevil") {
                disconnectSource(source);
                connectSource(source);
            }
        }
        onDataChanged: {
            disableBrightnessUpdate = true;
            root.screenBrightness = pmSource.data["PowerDevil"]["Screen Brightness"];
            disableBrightnessUpdate = false;
        }
    }
    //HACK: make the list know about the applet delegate which is a qtobject
    QtObject {
        id: nullApplet
    }
    Component.onCompleted: {
        //NOTE: add all in javascript as the static decl of listelements can't have scripts
        settingsModel.append({
            "text": i18n("Settings"),
            "icon": "configure",
            "enabled": false,
            "settingsCommand": "plasma-settings",
            "toggleFunction": "",
            "delegate": "",
            "enabled": false,
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Wifi"),
            "icon": "network-wireless-signal",
            "enabled": false,
            "settingsCommand": "plasma-settings -m kcm_mobile_wifi",
            "toggleFunction": "",
            "delegate": "",
            "enabled": false,
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Mobile Data"),
            "icon": "network-modem",
            "enabled": false,
            "settingsCommand": "plasma-settings -m kcm_mobile_broadband",
            "toggleFunction": "",
            "delegate": "",
            "enabled": false,
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Battery"),
            "icon": "battery",
            "enabled": false,
            "settingsCommand": "plasma-settings -m kcm_mobile_power",
            "toggleFunction": "",
            "delegate": "",
            "enabled": false,
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Sound"),
            "icon": "audio-speakers-symbolic",
            "enabled": false,
            "settingsCommand": "plasma-settings -m kcm_pulseaudio",
            "toggleFunction": "",
            "delegate": "",
            "enabled": false,
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Flashlight"),
            "icon": "flashlight-on",
            "enabled": false,
            "settingsCommand": "",
            "toggleFunction": "toggleTorch",
            "applet": null
        });
        settingsModel.append({
            "text": i18n("Location"),
            "icon": "find-location-symbolic",
            "enabled": false,
            "settingsCommand": "",
            "applet": null
        });
        if (plasmoid.configuration.ShowPowerButton) {
            settingsModel.append({
                "text": i18n("Shutdown"),
                "icon": "system-shutdown-symbolic",
                "enabled": false,
                "settingsCommand": "",
                "toggleFunction": "requestShutdown",
                "plasmoidId": -1,
                "applet": null
            });
        }

        brightnessSlider.moved.connect(function() {
            root.screenBrightness = brightnessSlider.value;
        });
        disableBrightnessUpdate = false;
    }

    ListModel {
        id: settingsModel
    }

    Flow {
        id: flow
        anchors {
            fill: parent
            margins: units.largeSpacing
        }
        spacing: units.largeSpacing
        Repeater {
            model: settingsModel
            delegate: Loader {
                //FIXME: why this is needed?
                width: flow.width / 2 - units.largeSpacing / 2//item ? item.implicitWidth : 0
                height: item ? item.implicitHeight : 0
                source: Qt.resolvedUrl((model.delegate ? model.delegate : "Delegate") + ".qml")
            }
        }
        move: Transition {
            NumberAnimation {
                duration: units.shortDuration
                easing.type: Easing.InOutQuad
                properties: "x,y"
            }
        }

        BrightnessItem {
            id: brightnessSlider
            width: flow.width
            icon: "video-display-brightness"
            label: i18n("Display Brightness")
            value: root.screenBrightness
            maximumValue: root.maximumScreenBrightness
            Connections {
                target: root
                onScreenBrightnessChanged: brightnessSlider.value = root.screenBrightness
            }
        }
    }
}
