/***************************************************************************
 *   Copyright 2006-2008 Aaron Seigo <aseigo@kde.org>                      *
 *   Copyright 2009 Marco Martin <notmart@gmail.com>                       *
 *   Copyright 2010 Alexis Menard <menard@kde.org>                         *
 *   Copyright 2010 Artur Duque de Souza <asouza@kde.org>                  *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

#include "mobcorona.h"
#include "mobdialogmanager.h"

#include <QApplication>
#include <QDesktopWidget>
#include <QDir>
#include <QGraphicsLayout>

#include <KCmdLineArgs>
#include <KDebug>
#include <KDialog>
#include <KGlobalSettings>
#include <KStandardDirs>

#include <Plasma/Containment>
#include <Plasma/DataEngineManager>

#include "plasmaapp.h"
#include "mobview.h"
#include <plasma/containmentactionspluginsconfig.h>

#include "../common/qmlwidget.h"

MobCorona::MobCorona(QObject *parent)
    : Plasma::Corona(parent)
{
    init();
}

void MobCorona::init()
{
    Plasma::ContainmentActionsPluginsConfig desktopPlugins;
    desktopPlugins.addPlugin(Qt::NoModifier, Qt::Vertical, "switchdesktop");
    desktopPlugins.addPlugin(Qt::NoModifier, Qt::RightButton, "contextmenu");
    Plasma::ContainmentActionsPluginsConfig panelPlugins;
    panelPlugins.addPlugin(Qt::NoModifier, Qt::RightButton, "contextmenu");

    setContainmentActionsDefaults(Plasma::Containment::DesktopContainment, desktopPlugins);
    setContainmentActionsDefaults(Plasma::Containment::PanelContainment, panelPlugins);
    setContainmentActionsDefaults(Plasma::Containment::CustomPanelContainment, panelPlugins);

    enableAction("lock widgets", false);

    setItemIndexMethod(QGraphicsScene::NoIndex);
    setDialogManager(new MobDialogManager(this));
}

void MobCorona::loadDefaultLayout()
{
    QString defaultConfig = KStandardDirs::locate("appdata", "plasma-default-layoutrc");
    if (!defaultConfig.isEmpty()) {
        kDebug() << "attempting to load the default layout from:" << defaultConfig;
        loadLayout(defaultConfig);
        return;
    }

    // used to force a save into the config file
    KConfigGroup invalidConfig;

    // FIXME: need to load the Mobile-specific containment
    // passing in an empty string will get us whatever the default
    // containment type is!
    Plasma::Containment* c = addContainmentDelayed(QString());

    if (!c) {
        return;
    }

    c->init();

    KCmdLineArgs *args = KCmdLineArgs::parsedArgs();
    bool isDesktop = args->isSet("desktop");

    if (isDesktop) {
        c->setScreen(0);
    }

    c->setWallpaper("image", "SingleImage");
    c->setFormFactor(Plasma::Planar);
    c->updateConstraints(Plasma::StartupCompletedConstraint);
    c->flushPendingConstraintsEvents();
    c->save(invalidConfig);

    // stacks all the containments at the same place
    c->setPos(0, 0);

    emit containmentAdded(c);
    requestConfigSync();
}

void MobCorona::layoutContainments()
{
    // we dont need any layout for this as we are going to bind the position
    // of the containments to QML items to animate them. As soon as we don't
    // need the containment anymore we can just let it stay wherever it is as
    // long as it's offscreen (the view is not 'looking' at it).

    // As this method is called from containments resize event and itemChange
    // if we let the default implementation work here we could have bad surprises
    // of containments appearing in the view when putting them in the default
    // grid-like layout.
    return;
}

Plasma::Applet *MobCorona::loadDefaultApplet(const QString &pluginName, Plasma::Containment *c)
{
    QVariantList args;
    Plasma::Applet *applet = Plasma::Applet::load(pluginName, 0, args);

    if (applet) {
        c->addApplet(applet);
    }
    return applet;
}

Plasma::Containment *MobCorona::findFreeContainment() const
{
    foreach (Plasma::Containment *cont, containments()) {
        if ((cont->containmentType() == Plasma::Containment::DesktopContainment ||
             cont->containmentType() == Plasma::Containment::CustomContainment) &&
            cont->screen() == -1 && !offscreenWidgets().contains(cont)) {
            return cont;
        }
    }
    return 0;
}

int MobCorona::numScreens() const
{
    return QApplication::desktop()->screenCount();
}

void MobCorona::setScreenGeometry(const QRect &geometry)
{
    m_screenGeometry = geometry;
}

QRect MobCorona::screenGeometry(int id) const
{
    return m_screenGeometry;
}

QRegion MobCorona::availableScreenRegion(int id) const
{
    QRegion r(screenGeometry(id));
    return r;
}

#include "mobcorona.moc"

