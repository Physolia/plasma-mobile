// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "applicationfolder.h"

#include <QJsonArray>

ApplicationFolder::ApplicationFolder(QObject *parent, QString name)
    : QObject{parent}
    , m_name{name}
{
}

ApplicationFolder *ApplicationFolder::fromJson(QJsonObject &obj, QObject *parent)
{
    QString name = obj[QStringLiteral("name")].toString();
    QList<Application *> apps;
    for (auto storageId : obj[QStringLiteral("apps")].toArray()) {
        if (KService::Ptr service = KService::serviceByStorageId(storageId.toString())) {
            apps.append(new Application(parent, service));
        }
    }

    ApplicationFolder *folder = new ApplicationFolder(parent, name);
    folder->setApplications(apps);
    return folder;
}

QJsonObject ApplicationFolder::toJson()
{
    QJsonObject obj;
    obj[QStringLiteral("type")] = "folder";
    obj[QStringLiteral("name")] = m_name;

    QJsonArray arr;
    for (auto *application : m_applications) {
        arr.append(QJsonValue::fromVariant(application->storageId()));
    }

    obj[QStringLiteral("apps")] = arr;

    return obj;
}

QString ApplicationFolder::name() const
{
    return m_name;
}

void ApplicationFolder::setName(QString &name)
{
    m_name = name;
    Q_EMIT nameChanged();
    Q_EMIT saveRequested();
}

QList<Application *> ApplicationFolder::applications()
{
    return m_applications;
}

void ApplicationFolder::setApplications(QList<Application *> applications)
{
    m_applications = applications;
    Q_EMIT applicationsChanged();
    Q_EMIT saveRequested();
}

void ApplicationFolder::addApp(const QString &storageId, int row)
{
    if (row < 0 || row > m_applications.size()) {
        return;
    }

    if (KService::Ptr service = KService::serviceByStorageId(storageId)) {
        Application *app = new Application(this, service);
        m_applications.insert(row, app);
        Q_EMIT applicationsChanged();
        Q_EMIT saveRequested();
    }
}

void ApplicationFolder::removeApp(int row)
{
    if (row < 0 || row >= m_applications.size()) {
        return;
    }

    m_applications[row]->deleteLater();
    m_applications.removeAt(row);
    Q_EMIT applicationsChanged();
    Q_EMIT saveRequested();
}
