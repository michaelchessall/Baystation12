// Money accounts should not be flattened. Child accounts do some work with references post save,
// and because both network accounts and transactions are flattened, could lead to absurdly large rows in the database.
SAVED_VAR(/datum/money_account, account_name)
SAVED_VAR(/datum/money_account, owner_name)
SAVED_VAR(/datum/money_account, remote_access_pin)
SAVED_VAR(/datum/money_account, money)
SAVED_VAR(/datum/money_account, transaction_log)
SAVED_VAR(/datum/money_account, suspended)
SAVED_VAR(/datum/money_account, security_level)
SAVED_VAR(/datum/money_account, account_type)
SAVED_VAR(/datum/money_account, account_number)
