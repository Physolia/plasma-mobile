/*
 *   Copyright (C) 2014 Antonis Tsiapaliokas <antonis.tsiapaliokas@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License version 2,
 *   or (at your option) any later version, as published by the Free
 *   Software Foundation
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Self
#include "favoritesmodel.h"

// Qt
#include <QByteArray>
#include <QModelIndex>
#include <QDebug>

// KDE
#include <KService>
#include <KSharedConfig>


constexpr int MAX_FAVOURITES = 5;

FavoritesModel::FavoritesModel(HomeScreen *parent)
    : ApplicationListModel(parent)
{
}

FavoritesModel::~FavoritesModel() = default;


QString FavoritesModel::storageToUniqueId(const QString &storageId) const
{
    if (storageId.isEmpty()) {
        return storageId;
    }

    int id = 0;
    QString uniqueId = storageId + QStringLiteral("-") + QString::number(id);

    while (m_appOrder.contains(uniqueId)) {
        uniqueId = storageId + QStringLiteral("-") + QString::number(++id);
    }

    return uniqueId;
}

QString FavoritesModel::uniqueToStorageId(const QString &uniqueId) const
{
    if (uniqueId.isEmpty()) {
        return uniqueId;
    }

    return uniqueId.split(QLatin1Char('-')).first();
}


void FavoritesModel::loadApplications()
{

    beginResetModel();

    m_applicationList.clear();

    QSet<QString> appsToRemove;

    for (const auto &uniqueId : m_appOrder) {
        const QString storageId = uniqueToStorageId(uniqueId);
        if (KService::Ptr service = KService::serviceByStorageId(storageId)) {
            ApplicationData data;
            data.name = service->name();
            data.icon = service->icon();
            data.storageId = service->storageId();
            data.uniqueId = uniqueId;
            data.entryPath = service->exec();
            data.startupNotify = service->property(QStringLiteral("StartupNotify")).toBool();

            if (m_favorites.contains(uniqueId)) {
                data.location = Favorites;
            } else if (m_desktopItems.contains(uniqueId)) {
                data.location = Desktop;
            }

            m_applicationList << data;
        } else {
            appsToRemove.insert(uniqueId);
        }
    }

    bool favChanged = false;

    for (const auto &uniqueId : appsToRemove) {
        m_appOrder.removeAll(uniqueId);
        if (m_favorites.contains(uniqueId)) {
            favChanged = true;
            m_favorites.removeAll(uniqueId);
        }
        m_desktopItems.remove(uniqueId);
    }
    
    endResetModel();
    emit countChanged();

    if (m_applet) {
        m_applet->config().writeEntry("Favorites", m_favorites);
        m_applet->config().writeEntry("AppOrder", m_appOrder);
        m_applet->config().writeEntry("DesktopItems", m_desktopItems.values());
        emit m_applet->configNeedsSaving();
    }

    if (favChanged) {
        emit favoriteCountChanged();
    }
}

void FavoritesModel::addFavorite(const QString &storageId, int row, LauncherLocation location)
{
    if (row < 0 || row > m_applicationList.count()) {
        return;
    }

    if (KService::Ptr service = KService::serviceByStorageId(storageId)) {
        const QString uniqueId = storageToUniqueId(service->storageId());
        ApplicationData data;
        data.name = service->name();
        data.icon = service->icon();
        data.storageId = service->storageId();
        data.uniqueId = uniqueId;
        data.entryPath = service->exec();
        data.startupNotify = service->property(QStringLiteral("StartupNotify")).toBool();

        bool favChanged = false;
        if (location == Favorites) {
            data.location = Favorites;
            m_favorites.insert(qMin(row, m_favorites.count()), uniqueId);
            favChanged = true;
        } else {
            data.location = location;
            m_desktopItems.insert(data.uniqueId);
        }

        beginInsertRows(QModelIndex(), row, row);
        m_applicationList.insert(row, data);
        m_appOrder.insert(row, uniqueId);
        endInsertRows();
        if (favChanged) {
            emit favoriteCountChanged();
        }

        if (m_applet) {
            m_applet->config().writeEntry("Favorites", m_favorites);
            m_applet->config().writeEntry("AppOrder", m_appOrder);
            m_applet->config().writeEntry("DesktopItems", m_desktopItems.values());
            emit m_applet->configNeedsSaving();
        }
    }
}

void FavoritesModel::removeFavorite(int row)
{
    if (row < 0 || row >= m_applicationList.count()) {
        return;
    }

    beginRemoveRows(QModelIndex(), row, row);
    const QString uniqueId = m_applicationList[row].uniqueId;
    m_appOrder.removeAll(uniqueId);
    const bool favChanged = m_favorites.contains(uniqueId);
    m_favorites.removeAll(uniqueId);
    m_desktopItems.remove(uniqueId);
    m_appPositions.remove(uniqueId);
    m_applicationList.removeAt(row);
    endRemoveRows();

    if (favChanged) {
        emit favoriteCountChanged();
    }

    if (m_applet) {
        m_applet->config().writeEntry("Favorites", m_favorites);
        m_applet->config().writeEntry("AppOrder", m_appOrder);
        m_applet->config().writeEntry("DesktopItems", m_desktopItems.values());
        emit m_applet->configNeedsSaving();
    }
}

#include "moc_favoritesmodel.cpp"

