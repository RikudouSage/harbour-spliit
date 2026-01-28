.pragma library
.import "currencies.js" as Currencies

function expenseFormFromDialog(dialog) {
    return {
        expenseDate: dialog.date.toISOString(),
        title: dialog.name,
        category: dialog.categoryId,
        amount: Currencies.parseAmountToCents(dialog.amount),
        paidBy: dialog.paidBy,
        paidFor: dialog.paidFor.map(function(id) {
            return {
                participant: id,
                shares: 100,
            };
        }),
        splitMode: "EVENLY",
        isReimbursement: dialog.isReimbursement,
        notes: dialog.notes,
        recurrenceRule: "NONE",
    };
}
