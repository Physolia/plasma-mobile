// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15

import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.plasma.private.mobileshell 1.0 as MobileShell

MobileShell.QuickSetting {
    PlasmaNM.Handler {
        id: nmHandler
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }
    
    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    text: i18n("Wi-Fi")
    status: enabledConnections.wirelessEnabled ? networkStatus.activeConnections : ""
    icon: "network-wireless-signal"
    settingsCommand: "plasma-open-settings kcm_mobile_wifi"
    function toggle() {
        nmHandler.enableWireless(!enabledConnections.wirelessEnabled)
    }
    enabled: enabledConnections.wirelessEnabled
}
