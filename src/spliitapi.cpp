#include "spliitapi.h"

#include <QDebug>
#include <QString>
#include <QByteArray>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QtConcurrent>
#include <QMetaObject>

SpliitApi::SpliitApi(QObject *parent) : QObject(parent)
{
    qRegisterMetaType<QJsonObject>("QJsonObject");
    const auto result = Spliit_NewClient(&m_clientPointer);
    if (result != SPLIIT_SUCCESS) {
        qWarning() << "Failed creating the Spliit client: " << getLastError();
        m_valid = false;
    }
}

SpliitApi::~SpliitApi()
{
    Spliit_CloseHandle(m_clientPointer);
}

bool SpliitApi::isValid() const
{
    return m_valid;
}

void SpliitApi::getGroup(const QString &groupId)
{
    QJsonObject input;
    input.insert("groupId", groupId);

    runRequest(
        "groups.get",
        input,
        "Invalid JSON in group response",
        [this](const QJsonObject &response) { emit groupFetched(response); },
        [this](const QString &error) { emit groupFetchFailed(error); }
    );
}

void SpliitApi::getGroups(const QStringList &groupIds)
{
    QJsonObject input;
    input.insert("groupIds", QJsonArray::fromStringList(groupIds));

    runRequest(
        "groups.list",
        input,
        "Invalid JSON in group response",
        [this](const QJsonObject &response) { emit groupsFetched(response); },
        [this](const QString &error) { emit groupFetchFailed(error); }
    );
}

void SpliitApi::listExpenses(const QString &groupId, int cursor, int limit)
{
    QJsonObject input;
    input.insert("groupId", groupId);
    input.insert("cursor", cursor);
    input.insert("limit", limit);

    runRequest(
        "groups.expenses.list",
        input,
        "Invalid JSON in expenses list response",
        [this](const QJsonObject &response) {emit expenseListResult(response);},
        [this](const QString &error) {emit expenseListFailed(error);}
    );
}

void SpliitApi::getCategories()
{
    QJsonObject input;

    runRequest(
        "categories.list",
        input,
        "Invalid JSON in categories list response",
        [this](const QJsonObject &response) {emit categoriesFetched(response);},
        [this](const QString &error) {emit categoryFetchingFailed(error);}
    );
}

void SpliitApi::createExpense(const QString &groupId, const QVariantMap &request, const QString &participantId)
{
    auto form = QJsonObject::fromVariantMap(request);
    QJsonObject input;
    input.insert("groupId", groupId);
    input.insert("expenseFormValues", form);
    if (participantId != "") {
        input.insert("participantId", participantId);
    }

    runRequest(
        "groups.expenses.create",
        input,
        "Invalid JSON when creating expense",
        [this](const QJsonObject &response) {
            emit expenseCreated(response.value("expenseId").toString());
        },
        [this](const QString &error) {emit expenseCreationFailed(error);}
    );
}

void SpliitApi::deleteExpense(const QString &groupId, const QString &expenseId, const QString &participantId)
{
    QJsonObject input;
    input.insert("groupId", groupId);
    input.insert("expenseId", expenseId);
    if (participantId != "") {
        input.insert("participantId", participantId);
    }

    runRequest(
        "groups.expenses.delete",
        input,
        "Invalid JSON when deleting expense",
        [this, expenseId](const QJsonObject &response) {
            Q_UNUSED(response);
            emit expenseDeleted(expenseId);
        },
        [this, expenseId](const QString &error) {emit expenseDeleteFailed(expenseId, error);}
    );
}

void SpliitApi::getExpense(const QString &groupId, const QString &expenseId)
{
    QJsonObject input;
    input.insert("groupId", groupId);
    input.insert("expenseId", expenseId);

    runRequest(
        "groups.expenses.get",
        input,
        "Invalid JSON when getting expense",
        [this](const QJsonObject &response) {emit expenseFetched(response);},
        [this, expenseId](const QString &error) {emit expenseFetchFailed(expenseId, error);}
    );
}

void SpliitApi::updateExpense(const QString &groupId, const QString &expenseId, const QVariantMap &request, const QString &participantId)
{
    QJsonObject input;
    input.insert("expenseId", expenseId);
    input.insert("groupId", groupId);
    input.insert("expenseFormValues", QJsonObject::fromVariantMap(request));
    if (participantId != "") {
        input.insert("participantId", participantId);
    }

    runRequest(
        "groups.expenses.update",
        input,
        "Invalid JSON when updating expense",
        [this](const QJsonObject &response) {emit expenseUpdated(response.value("expenseId").toString());},
        [this, expenseId](const QString &error) {emit expenseUpdateFailed(expenseId, error);}
    );
}

void SpliitApi::runRequest(
    const QString &endpoint,
    const QJsonObject &input,
    const QString &invalidJsonError,
    const std::function<void(const QJsonObject &)> &onSuccess,
    const std::function<void(const QString &)> &onError
) {
    const quint64 client = m_clientPointer;
    QPointer<SpliitApi> self(this);

    QtConcurrent::run([self, client, endpoint, input, invalidJsonError, onSuccess, onError] {
        if (!self) {
            return;
        }

        QJsonObject call;
        call.insert("endpoint", endpoint);
        call.insert("input", input);

        QJsonArray calls;
        calls.append(call);

        const QByteArray callsJson = QJsonDocument(calls).toJson(QJsonDocument::Compact);

        SpliitResult* results = nullptr;
        size_t count = 0;

        const auto result = Spliit_SendRequests(
            client,
            const_cast<char*>(callsJson.constData()),
            &results,
            &count
        );

        QJsonObject response;
        QString error;

        if (result != SPLIIT_SUCCESS) {
            error = self->getLastError();
        } else if (!results || count == 0) {
            error = "No response from Spliit api";
        } else {
            const SpliitResult &res = results[0];
            if (res.error != nullptr) {
                error = QString::fromUtf8(res.error);
            } else if (res.result == nullptr) {
                error = "No result returned";
            } else {
                const QByteArray resultJson(res.result);
                const auto doc = QJsonDocument::fromJson(resultJson);
                if (doc.isObject()) {
                    response = doc.object();
                } else {
                    error = invalidJsonError;
                }
            }
        }

        if (results) {
            Spliit_FreeResults(results, count);
        }

        if (!self) {
            return;
        }

        if (!error.isEmpty()) {
            if (onError) {
                onError(error);
            }
        } else if (onSuccess) {
            onSuccess(response);
        }
    });
}

const QString SpliitApi::getLastError() const
{
    std::size_t len = Spliit_GetLastError(nullptr, 0);

    if (len < 1) {
        return QString();
    }

    QByteArray buf(static_cast<int>(len), Qt::Uninitialized);
    Spliit_GetLastError(buf.data(), static_cast<std::size_t>(buf.size()));

    return QString::fromUtf8(buf.constData());
}
