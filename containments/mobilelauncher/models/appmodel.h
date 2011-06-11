/*
    Copyright 2009 Ivan Cukic <ivan.cukic+kde@gmail.com>
    Copyright 2011 Marco Martin <notmart@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef APPMODEL_H
#define APPMODEL_H

#include <QStandardItemModel>


#include "standarditemfactory.h"


class AppModel : public QStandardItemModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory)

public:
    AppModel(QObject *parent);
    virtual ~AppModel();

    void setCategory(const QString &category);
    QString category() const;

    int count() const {return QStandardItemModel::rowCount();}

Q_SIGNALS:
    void countChanged();

private:
    QString m_category;
};

#endif // APPMODEL_H

