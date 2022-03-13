/*
 *   SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include "qqml.h"
#include <QAbstractListModel>
#include <QQmlListProperty>

#include "mobileshell_export.h"

namespace MobileShell
{

class MOBILESHELL_EXPORT QuickSetting : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText REQUIRED NOTIFY textChanged)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged) // if no status is explicitly set, On/Off is used by default
    Q_PROPERTY(QString icon READ iconName WRITE setIconName REQUIRED NOTIFY iconNameChanged)
    Q_PROPERTY(QString settingsCommand READ settingsCommand WRITE setSettingsCommand NOTIFY settingsCommandChanged)
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QQmlListProperty<QObject> children READ children CONSTANT)
    Q_CLASSINFO("DefaultProperty", "children")
    QML_NAMED_ELEMENT("QuickSetting")
public:
    QuickSetting(QObject *parent = nullptr);

    QString text() const
    {
        return m_text;
    }
    QString status() const
    {
        return m_status;
    }
    QString iconName() const
    {
        return m_iconName;
    }
    QString settingsCommand() const
    {
        return m_settingsCommand;
    }
    bool isEnabled() const
    {
        return m_enabled;
    }

    void setText(const QString &text);
    void setStatus(const QString &status);
    void setIconName(const QString &iconName);
    void setSettingsCommand(const QString &settingsCommand);
    void setEnabled(bool enabled);
    QQmlListProperty<QObject> children();

Q_SIGNALS:
    void enabledChanged(bool enabled);
    void textChanged(const QString &text);
    void statusChanged(const QString &text);
    void iconNameChanged(const QString &icon);
    void settingsCommandChanged(const QString &settingsCommand);

private:
    bool m_enabled = true;
    QString m_text;
    QString m_status;
    QString m_iconName;
    QString m_settingsCommand;
    QList<QObject *> m_children;
};

} // namespace MobileShell
