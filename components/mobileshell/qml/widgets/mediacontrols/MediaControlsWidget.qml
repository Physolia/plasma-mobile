// SPDX-FileCopyrightText: 2021-2023 Devin Lin <devin@kde.org>
// SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.mobileshell as MobileShell
import org.kde.plasma.private.mobileshell.state as MobileShellState

import org.kde.plasma.private.mpris as Mpris

/**
 * Embeddable component that provides MPRIS control.
 */
Item {
    id: root
    visible: sourceRepeater.count > 0

    property bool detailledView: false
    readonly property real heightMultiplier: detailledView ? 2 : 1

    readonly property real padding: Kirigami.Units.gridUnit
    readonly property real contentHeight: Kirigami.Units.gridUnit * 2 * heightMultiplier
    implicitHeight: visible ? padding * 2 + contentHeight : 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }
    
    MediaControlsSource {
        id: mpris2Source
    }
    
    // page indicator
    RowLayout {
        z: 1
        visible: view.count > 1
        spacing: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.bottom: view.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        
        Repeater {
            model: view.count
            delegate: Rectangle {
                width: Kirigami.Units.smallSpacing
                height: Kirigami.Units.smallSpacing
                radius: width / 2
                color: Qt.rgba(255, 255, 255, view.currentIndex == model.index ? 1 : 0.5)
            }
        }
    }
    
    // list of app media widgets
    QQC2.SwipeView {
        id: view
        clip: true
        
        anchors.fill: parent
        
        Repeater {
            id: sourceRepeater
            model: mpris2Source.mpris2Model
            
            delegate: Loader {
                id: delegate
                // NOTE: model is PlayerContainer from KMpris in plasma-workspace

                asynchronous: true
                
                function getTrackName() {
                    console.log('track name: ' + model.title);
                    if (model.title) {
                        return model.title;
                    }
                    // if no track title is given, print out the file name
                    if (!model.url) {
                        return "";
                    }
                    const lastSlashPos = model.url.lastIndexOf('/')
                    if (lastSlashPos < 0) {
                        return ""
                    }
                    const lastUrlPart = model.url.substring(lastSlashPos + 1);
                    return decodeURIComponent(lastUrlPart);
                }

                function msecToString(duration: int): string {
                    let seconds = Math.floor(duration / 1000000)
                    let minutes = Math.floor(seconds / 60)
                    seconds -= minutes * 60
                    return `${minutes}:${seconds.toString().padStart(2, '0')}`
                }

                sourceComponent: MouseArea {
                    id: mouseArea
                    implicitHeight: playerItem.implicitHeight
                    implicitWidth: playerItem.implicitWidth

                    onPressAndHold: {
                        MobileShell.AppLaunch.launchOrActivateApp(model.desktopEntry + ".desktop");
                        MobileShellState.ShellDBusClient.closeActionDrawer();
                    }
                    
                    onClicked: {
                        root.detailledView = !root.detailledView
                    }

                    
                    MobileShell.BaseItem {
                        id: playerItem
                        anchors.fill: parent
                        
                        padding: root.padding
                        implicitHeight: root.contentHeight + root.padding * 2
                        implicitWidth: root.width
                        
                        background: BlurredBackground {
                            darken: mouseArea.pressed
                            imageSource: model.artUrl
                        }
                        
                        contentItem: ColumnLayout {
                            Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                            Kirigami.Theme.inherit: false
                            width: playerItem.width - playerItem.leftPadding - playerItem.rightPadding
                            spacing: Kirigami.Units.largeSpacing
                            
                            RowLayout {
                                id: controlsRow
                                spacing: 0

                                enabled: model.canControl

                                Image {
                                    id: albumArt
                                    Layout.preferredWidth: height
                                    Layout.preferredHeight: controlsRow.height
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    source: model.artUrl
                                    sourceSize.height: height
                                    visible: status === Image.Loading || status === Image.Ready
                                }

                                ColumnLayout {
                                    Layout.leftMargin: albumArt.visible ? Kirigami.Units.gridUnit : 0
                                    Layout.rightMargin: Kirigami.Units.largeSpacing
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing

                                    // media track name text
                                    MobileShell.MarqueeLabel {
                                        id: trackLabel
                                        Layout.fillWidth: true

                                        inputText: model.track || i18n("No media playing");
                                        textFormat: Text.PlainText
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                                        color: "white"
                                    }

                                    // media artist name text
                                    MobileShell.MarqueeLabel {
                                        id: artistLabel
                                        Layout.fillWidth: true

                                        // if no artist is given, show player name instead
                                        inputText: model.artist || model.identity || ""
                                        textFormat: Text.PlainText
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                        opacity: 0.9
                                        color: "white"
                                    }
                                }

                                QQC2.ToolButton {
                                    enabled: model.canGoPrevious
                                    icon.name: LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
                                    icon.width: Kirigami.Units.iconSizes.smallMedium
                                    icon.height: Kirigami.Units.iconSizes.smallMedium
                                    icon.color: "white"
                                    onClicked: {
                                        mpris2Source.setIndex(model.index);
                                        mpris2Source.goPrevious();
                                    }
                                    visible: model.canGoPrevious || model.canGoNext
                                    Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Previous track")
                                }

                                QQC2.ToolButton {
                                    icon.name: (model.playbackStatus === Mpris.PlaybackStatus.Playing) ? "media-playback-pause" : "media-playback-start"
                                    icon.width: Kirigami.Units.iconSizes.smallMedium
                                    icon.height: Kirigami.Units.iconSizes.smallMedium
                                    icon.color: "white"
                                    onClicked: {
                                        mpris2Source.setIndex(model.index);
                                        mpris2Source.playPause();
                                    }
                                    Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Play or Pause media")
                                }

                                QQC2.ToolButton {
                                    enabled: model.canGoNext
                                    icon.name: LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
                                    icon.width: Kirigami.Units.iconSizes.smallMedium
                                    icon.height: Kirigami.Units.iconSizes.smallMedium
                                    icon.color: "white"
                                    onClicked: {
                                        mpris2Source.setIndex(model.index);
                                        mpris2Source.goNext();
                                    }
                                    visible: model.canGoPrevious || model.canGoNext
                                    Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Next track")
                                }
                            }

                            RowLayout {
                                id: timerControlsRow

                                spacing: Kirigami.Units.largeSpacing

                                visible: root.detailledView

                                Text {
                                    text: msecToString(model.position)

                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                    color: "white"
                                }

                                PC3.Slider {
                                    Layout.fillWidth: true

                                    from: 0
                                    value: model.position
                                    to: model.length

                                    onMoved: model.position = value

                                    Timer {
                                        interval: 1000; running: true; repeat: true
                                        onTriggered: {
                                            mpris2Source.setIndex(model.index);
                                            mpris2Source.updatePosition()
                                        }
                                    }
                                }

                                Text {
                                    text: msecToString(model.length)

                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
