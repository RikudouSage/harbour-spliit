#ifndef SPLIITAPI_H
#define SPLIITAPI_H

#include <QObject>
#include <QJsonObject>
#include <functional>

#include "libspliit.h"

class SpliitApi : public QObject
{
    Q_OBJECT
public:
    explicit SpliitApi(QObject *parent = nullptr);
    ~SpliitApi();

    Q_INVOKABLE bool isValid() const;
    Q_INVOKABLE void getGroup(const QString &groupId);
    Q_INVOKABLE void getGroups(const QStringList &groupIds);
    Q_INVOKABLE void listExpenses(const QString &groupId, int cursor, int limit);
    Q_INVOKABLE void getCategories();
    Q_INVOKABLE void createExpense(const QString &groupId, const QVariantMap &request, const QString &participantId);
    Q_INVOKABLE void deleteExpense(const QString &groupId, const QString &expenseId, const QString &participantId);

signals:
    void groupFetched(const QJsonObject &response);
    void groupFetchFailed(const QString &error);
    void groupsFetched(const QJsonObject &response);
    void expenseListFailed(const QString &error);
    void expenseListResult(const QJsonObject &response);
    void categoryFetchingFailed(const QString &error);
    void categoriesFetched(const QJsonObject &response);
    void expenseCreated(const QString &expenseId);
    void expenseCreationFailed(const QString &error);
    void expenseDeleted(const QString &id);
    void expenseDeleteFailed(const QString &id, const QString &error);

private:
    void runRequest(
        const QString &endpoint,
        const QJsonObject &input,
        const QString &invalidJsonError,
        const std::function<void(const QJsonObject &)> &onSuccess,
        const std::function<void(const QString &)> &onError
    );
    const QString getLastError() const;

private:
    uint64_t m_clientPointer;
    bool m_valid = true;
};

#endif // SPLIITAPI_H
