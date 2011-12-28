/*
 *   Copyright 2011 Sebastian Kügler <sebas@kde.org>
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

#include "settingsplugin.h"
#include <kdebug.h>

#include <QtDeclarative/qdeclarative.h>

//#include "settingsmoduleloader.h"
#include "settingsmodulesmodel.h"
#include "settingscomponent.h"
#include "configmodel.h"

void SettingsPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.active.settings"));
    const int major = 0;
    const int minor = 1;
    qmlRegisterType<SettingsModulesModel>(uri, major, minor, "SettingsModulesModel");
    qmlRegisterType<SettingsModulesItem>(uri, major, minor, "SettingsModulesItem");
    qmlRegisterType<SettingsComponent>(uri, major, minor, "SettingsComponent");
    qmlRegisterType<Plasma::ConfigModel>(uri, major, minor, "ConfigModel");
}

#include "settingsplugin.moc"

