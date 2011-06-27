/*
   This file is part of the Nepomuk KDE project.
   Copyright (C) 2011 Sebastian Trueg <trueg@kde.org>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) version 3, or any
   later version accepted by the membership of KDE e.V. (or its
   successor approved by the membership of KDE e.V.), which shall
   act as a proxy defined in Section 6 of version 3 of the license.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "recommendationmanager.h"
#include "recommendationmanageradaptor.h"
#include "recommendation.h"
#include "recommendationaction.h"
#include "locationmanager.h"
#include "kext.h"

#include <kworkspace/kactivityinfo.h>
#include <kworkspace/kactivityconsumer.h>

#include <KRandom>
#include <KRun>
#include <KDebug>

#include <Nepomuk/Query/Query>
#include <Nepomuk/Query/QueryServiceClient>
#include <Nepomuk/Query/ComparisonTerm>
#include <Nepomuk/Query/LiteralTerm>
#include <Nepomuk/Query/AndTerm>
#include <Nepomuk/Query/QueryServiceClient>
#include <Nepomuk/Query/Result>
#include <Nepomuk/Resource>
#include <Nepomuk/Variant>

#include <Soprano/Vocabulary/NAO>

#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMetaType>

#include <QtLocation/QLandmark>

using namespace Soprano::Vocabulary;
using namespace Nepomuk::Vocabulary;

QTM_USE_NAMESPACE

//Q_DECLARE_METATYPE(Contour::Recommendation*)


// TODO: act on several changes:
//       * later: triggers from the dms

class Contour::RecommendationManager::Private
{
public:
    KActivityConsumer* m_activityConsumer;
    LocationManager* m_locationManager;

    QList<Recommendation> m_recommendations;
    QHash<QString, RecommendationAction> m_actionHash;
    QHash<QString, Recommendation> m_RecommendationForAction;

    Nepomuk::Query::QueryServiceClient m_queryClient;

    RecommendationManager* q;

    void updateRecommendations();
    void _k_locationChanged(const QList<QLandmark>&);
    void _k_currentActivityChanged(const QString&);
    void _k_newResults(const QList<Nepomuk::Query::Result>&);
    void _k_queryFinished();
};


void Contour::RecommendationManager::Private::updateRecommendations()
{
    // remove old recommendations
    m_recommendations.clear();
    m_actionHash.clear();
    m_RecommendationForAction.clear();

    // get resources that have been touched in the current activity (the dumb way for now)
    const QString query
            = QString::fromLatin1(
                "select distinct ?resource, "
                "    ( "
                "        ( "
                "            SUM ( "
                "                ?lastScore * bif:exp( "
                "                    - bif:datediff('day', ?lastUpdate, %1) "
                "                ) "
                "            ) "
                "        ) "
                "        as ?score "
                "    ) where { "
                "        ?cache kext:targettedResource ?resource . "
                "        ?cache a kext:ResourceScoreCache . "
                "        ?cache nao:lastModified ?lastUpdate . "
                "        ?cache kext:cachedScore ?lastScore . "
                "        ?cache kext:usedActivity %2 . "
                "    } "
                "    GROUP BY (?resource) "
                "    ORDER BY DESC (?score) "
                "    LIMIT 10 "
            ).arg(
                Soprano::Node::literalToN3(
                    QDateTime::currentDateTime()
                ),
                Soprano::Node::resourceToN3(
                    Nepomuk::Resource(m_activityConsumer->currentActivity(), KExt::Activity()).resourceUri()
                )
            );

    kDebug() << query;

    m_queryClient.sparqlQuery(query);

    // IDEA: for files use usage events
    //       for everything else use changes in data via graph metadata
}

void Contour::RecommendationManager::Private::_k_locationChanged(const QList<QLandmark>&)
{
    updateRecommendations();
}

void Contour::RecommendationManager::Private::_k_currentActivityChanged(const QString&)
{
    updateRecommendations();
}

void Contour::RecommendationManager::Private::_k_newResults(const QList<Nepomuk::Query::Result>& results)
{
    foreach(const Nepomuk::Query::Result& result, results) {
        Recommendation r;
        Nepomuk::Resource resource(result.additionalBinding("resource").toString());
        r.resourceUri = KUrl(resource.resourceUri()).url();
        r.relevance = result.additionalBinding("score").toDouble();

        kWarning() << "Got a new result:" << r.resourceUri << result.excerpt() << result.additionalBinding("score");

        // for now we create the one dummy action: open the resource
        QString id;
        do {
            id = KRandom::randomString(5);
        } while(m_actionHash.contains(id));
        RecommendationAction action;
        action.id = id;
        action.text = i18n("Open '%1'", resource.genericLabel());
        action.iconName = "document-open";
        //TODO
        action.relevance = 1;
        m_actionHash[id] = action;
        m_RecommendationForAction[id] = r;

        r.actions << action;

        m_recommendations << r;
    }
}

void Contour::RecommendationManager::Private::_k_queryFinished()
{
    emit q->recommendationsChanged();
}

Contour::RecommendationManager::RecommendationManager(QObject *parent)
    : QObject(parent),
      d(new Private())
{
    d->q = this;

    connect(&d->m_queryClient, SIGNAL(newEntries(QList<Nepomuk::Query::Result>)),
            this, SLOT(_k_newResults(QList<Nepomuk::Query::Result>)));

    d->m_activityConsumer = new KActivityConsumer(this);
    connect(d->m_activityConsumer, SIGNAL(currentActivityChanged(QString)),
            this, SLOT(_k_currentActivityChanged(QString)));
    d->m_locationManager = new LocationManager(this);
    connect(d->m_locationManager, SIGNAL(locationChanged(QList<QLandmark>)),
            this, SLOT(_k_locationChanged(QList<QLandmark>)));
    d->updateRecommendations();

    // export via DBus
    qDBusRegisterMetaType<Contour::Recommendation>();
    qDBusRegisterMetaType<QList<Contour::Recommendation> >();
    qDBusRegisterMetaType<Contour::RecommendationAction>();
    (void)new RecommendationManagerAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QLatin1String("/recommendationmanager"), this);
}

Contour::RecommendationManager::~RecommendationManager()
{
    delete d;
}

QList<Contour::Recommendation> Contour::RecommendationManager::recommendations() const
{
    return d->m_recommendations;
}

void Contour::RecommendationManager::executeAction(const QString &actionId)
{
    if(d->m_actionHash.contains(actionId)) {
        RecommendationAction action = d->m_actionHash.value(actionId);

        // FIXME: this is the hacky execution of the action, make it correct
        Recommendation r = d->m_RecommendationForAction.value(actionId);
        Nepomuk::Resource res(r.resourceUri);
        QString url = res.property(QUrl("http://www.semanticdesktop.org/ontologies/2007/01/19/nie#url")).toString();
        if (url.isEmpty()) {
            return;
        }
        KRun *run = new KRun(url, 0);
        run->setAutoDelete(true);
    }
    else {
        kDebug() << "Invalid action id encountered:" << actionId;
    }
}

#include "recommendationmanager.moc"
