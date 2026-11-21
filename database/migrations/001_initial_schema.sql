PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

CREATE TABLE people (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    is_current_user INTEGER NOT NULL DEFAULT 0
        CHECK (is_current_user IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE UNIQUE INDEX people_one_current_user_idx
    ON people (is_current_user)
    WHERE is_current_user = 1;

CREATE TABLE categories (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL COLLATE NOCASE
        CHECK (length(trim(name)) > 0),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE (name)
);

CREATE TABLE credit_cards (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    owner_person_id TEXT NOT NULL,
    closing_day INTEGER NOT NULL CHECK (closing_day BETWEEN 1 AND 31),
    due_day INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 31),
    is_active INTEGER NOT NULL DEFAULT 1
        CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (owner_person_id) REFERENCES people (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX credit_cards_owner_idx ON credit_cards (owner_person_id);

CREATE TABLE card_statements (
    id TEXT PRIMARY KEY NOT NULL,
    credit_card_id TEXT NOT NULL,
    cycle_month TEXT NOT NULL
        CHECK (
            length(cycle_month) = 7
            AND substr(cycle_month, 5, 1) = '-'
            AND CAST(substr(cycle_month, 6, 2) AS INTEGER) BETWEEN 1 AND 12
        ),
    closing_date TEXT NOT NULL CHECK (date(closing_date) IS NOT NULL),
    due_date TEXT NOT NULL CHECK (date(due_date) IS NOT NULL),
    paid_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (credit_card_id) REFERENCES credit_cards (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (credit_card_id, cycle_month),
    CHECK (date(due_date) >= date(closing_date))
);

CREATE INDEX card_statements_due_date_idx ON card_statements (due_date);

CREATE TABLE subscriptions (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL CHECK (length(trim(title)) > 0),
    category_id TEXT NOT NULL,
    icon_key TEXT NOT NULL CHECK (length(trim(icon_key)) > 0),
    standard_amount_cents INTEGER NOT NULL CHECK (standard_amount_cents >= 0),
    payment_method TEXT NOT NULL
        CHECK (payment_method IN ('boleto', 'credit_card')),
    credit_card_id TEXT,
    default_payer_person_id TEXT NOT NULL,
    billing_day INTEGER NOT NULL CHECK (billing_day BETWEEN 1 AND 31),
    start_date TEXT NOT NULL CHECK (date(start_date) IS NOT NULL),
    end_date TEXT CHECK (end_date IS NULL OR date(end_date) IS NOT NULL),
    is_active INTEGER NOT NULL DEFAULT 1
        CHECK (is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (category_id) REFERENCES categories (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (credit_card_id) REFERENCES credit_cards (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (default_payer_person_id) REFERENCES people (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (
        (payment_method = 'boleto' AND credit_card_id IS NULL)
        OR
        (payment_method = 'credit_card' AND credit_card_id IS NOT NULL)
    ),
    CHECK (end_date IS NULL OR date(end_date) >= date(start_date))
);

CREATE INDEX subscriptions_category_idx ON subscriptions (category_id);
CREATE INDEX subscriptions_default_payer_idx
    ON subscriptions (default_payer_person_id);
CREATE INDEX subscriptions_credit_card_idx
    ON subscriptions (credit_card_id)
    WHERE credit_card_id IS NOT NULL;

CREATE TABLE subscription_participants (
    subscription_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    share_weight INTEGER NOT NULL DEFAULT 1 CHECK (share_weight >= 0),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    PRIMARY KEY (subscription_id, person_id),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people (id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX subscription_participants_person_idx
    ON subscription_participants (person_id);

CREATE TRIGGER subscription_participants_zero_weight_insert_guard
BEFORE INSERT ON subscription_participants
WHEN NEW.share_weight = 0
 AND NOT EXISTS (
     SELECT 1 FROM people
     WHERE id = NEW.person_id AND is_current_user = 1
 )
BEGIN
    SELECT RAISE(ABORT, 'only the current user may have zero share weight');
END;

CREATE TRIGGER subscription_participants_zero_weight_update_guard
BEFORE UPDATE OF person_id, share_weight ON subscription_participants
WHEN NEW.share_weight = 0
 AND NOT EXISTS (
     SELECT 1 FROM people
     WHERE id = NEW.person_id AND is_current_user = 1
 )
BEGIN
    SELECT RAISE(ABORT, 'only the current user may have zero share weight');
END;

CREATE TABLE payment_occurrences (
    id TEXT PRIMARY KEY NOT NULL,
    subscription_id TEXT NOT NULL,
    cycle_month TEXT NOT NULL
        CHECK (
            length(cycle_month) = 7
            AND substr(cycle_month, 5, 1) = '-'
            AND CAST(substr(cycle_month, 6, 2) AS INTEGER) BETWEEN 1 AND 12
        ),
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    payer_person_id TEXT NOT NULL,
    payment_method TEXT NOT NULL
        CHECK (payment_method IN ('boleto', 'credit_card')),
    charge_date TEXT NOT NULL CHECK (date(charge_date) IS NOT NULL),
    direct_due_date TEXT CHECK (direct_due_date IS NULL OR date(direct_due_date) IS NOT NULL),
    card_statement_id TEXT,
    direct_paid_at TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (payer_person_id) REFERENCES people (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (card_statement_id) REFERENCES card_statements (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (subscription_id, cycle_month),
    CHECK (
        (
            payment_method = 'boleto'
            AND direct_due_date IS NOT NULL
            AND card_statement_id IS NULL
        )
        OR
        (
            payment_method = 'credit_card'
            AND direct_due_date IS NULL
            AND card_statement_id IS NOT NULL
            AND direct_paid_at IS NULL
        )
    )
);

CREATE INDEX payment_occurrences_payer_idx
    ON payment_occurrences (payer_person_id);
CREATE INDEX payment_occurrences_statement_idx
    ON payment_occurrences (card_statement_id)
    WHERE card_statement_id IS NOT NULL;
CREATE INDEX payment_occurrences_direct_due_date_idx
    ON payment_occurrences (direct_due_date)
    WHERE direct_due_date IS NOT NULL;

CREATE TABLE payment_shares (
    id TEXT PRIMARY KEY NOT NULL,
    payment_occurrence_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    amount_due_cents INTEGER NOT NULL CHECK (amount_due_cents >= 0),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (payment_occurrence_id) REFERENCES payment_occurrences (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (payment_occurrence_id, person_id)
);

CREATE INDEX payment_shares_person_idx ON payment_shares (person_id);

CREATE TABLE share_settlements (
    id TEXT PRIMARY KEY NOT NULL,
    payment_share_id TEXT NOT NULL,
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    paid_at TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    FOREIGN KEY (payment_share_id) REFERENCES payment_shares (id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX share_settlements_share_idx
    ON share_settlements (payment_share_id);
CREATE INDEX share_settlements_paid_at_idx ON share_settlements (paid_at);

-- A credit-card subscription is paid by the owner of the selected card.
CREATE TRIGGER subscriptions_card_owner_insert_guard
BEFORE INSERT ON subscriptions
WHEN NEW.payment_method = 'credit_card'
     AND NEW.default_payer_person_id <> (
         SELECT owner_person_id FROM credit_cards WHERE id = NEW.credit_card_id
     )
BEGIN
    SELECT RAISE(ABORT, 'credit-card subscription payer must own the card');
END;

CREATE TRIGGER subscriptions_card_owner_update_guard
BEFORE UPDATE OF payment_method, credit_card_id, default_payer_person_id ON subscriptions
WHEN NEW.payment_method = 'credit_card'
     AND NEW.default_payer_person_id <> (
         SELECT owner_person_id FROM credit_cards WHERE id = NEW.credit_card_id
     )
BEGIN
    SELECT RAISE(ABORT, 'credit-card subscription payer must own the card');
END;

-- A card occurrence must use a statement belonging to its subscription's card,
-- and its payer must be that card's owner.
CREATE TRIGGER payment_occurrences_card_insert_guard
BEFORE INSERT ON payment_occurrences
WHEN NEW.payment_method = 'credit_card'
     AND NOT EXISTS (
         SELECT 1
         FROM card_statements statement
         JOIN credit_cards card ON card.id = statement.credit_card_id
         JOIN subscriptions subscription ON subscription.id = NEW.subscription_id
         WHERE statement.id = NEW.card_statement_id
           AND statement.credit_card_id = subscription.credit_card_id
           AND card.owner_person_id = NEW.payer_person_id
     )
BEGIN
    SELECT RAISE(ABORT, 'card occurrence must use the subscription card and its owner');
END;

CREATE TRIGGER payment_occurrences_card_update_guard
BEFORE UPDATE OF subscription_id, payer_person_id, payment_method, card_statement_id
ON payment_occurrences
WHEN NEW.payment_method = 'credit_card'
     AND NOT EXISTS (
         SELECT 1
         FROM card_statements statement
         JOIN credit_cards card ON card.id = statement.credit_card_id
         JOIN subscriptions subscription ON subscription.id = NEW.subscription_id
         WHERE statement.id = NEW.card_statement_id
           AND statement.credit_card_id = subscription.credit_card_id
           AND card.owner_person_id = NEW.payer_person_id
     )
BEGIN
    SELECT RAISE(ABORT, 'card occurrence must use the subscription card and its owner');
END;

-- Share rows can be inserted incrementally, but their total can never exceed
-- the occurrence value. The app must finish each creation transaction with an
-- exact total.
CREATE TRIGGER payment_shares_total_insert_guard
BEFORE INSERT ON payment_shares
WHEN NEW.amount_due_cents + COALESCE((
         SELECT SUM(amount_due_cents)
         FROM payment_shares
         WHERE payment_occurrence_id = NEW.payment_occurrence_id
     ), 0) > (
         SELECT amount_cents
         FROM payment_occurrences
         WHERE id = NEW.payment_occurrence_id
     )
BEGIN
    SELECT RAISE(ABORT, 'payment shares exceed the occurrence amount');
END;

CREATE TRIGGER payment_shares_total_update_guard
BEFORE UPDATE OF payment_occurrence_id, amount_due_cents ON payment_shares
WHEN NEW.amount_due_cents + COALESCE((
         SELECT SUM(amount_due_cents)
         FROM payment_shares
         WHERE payment_occurrence_id = NEW.payment_occurrence_id
           AND id <> OLD.id
     ), 0) > (
         SELECT amount_cents
         FROM payment_occurrences
         WHERE id = NEW.payment_occurrence_id
     )
BEGIN
    SELECT RAISE(ABORT, 'payment shares exceed the occurrence amount');
END;

CREATE TRIGGER payment_occurrences_amount_update_guard
BEFORE UPDATE OF amount_cents ON payment_occurrences
WHEN NEW.amount_cents < COALESCE((
         SELECT SUM(amount_due_cents)
         FROM payment_shares
         WHERE payment_occurrence_id = NEW.id
     ), 0)
BEGIN
    SELECT RAISE(ABORT, 'occurrence amount is below its existing shares');
END;

-- The provider payer does not reimburse themselves; only other participants
-- create settlement rows.
CREATE TRIGGER share_settlements_payer_guard
BEFORE INSERT ON share_settlements
WHEN EXISTS (
    SELECT 1
    FROM payment_shares share
    JOIN payment_occurrences occurrence
      ON occurrence.id = share.payment_occurrence_id
    WHERE share.id = NEW.payment_share_id
      AND share.person_id = occurrence.payer_person_id
)
BEGIN
    SELECT RAISE(ABORT, 'the provider payer cannot reimburse themselves');
END;

CREATE TRIGGER share_settlements_total_insert_guard
BEFORE INSERT ON share_settlements
WHEN NEW.amount_cents + COALESCE((
         SELECT SUM(amount_cents)
         FROM share_settlements
         WHERE payment_share_id = NEW.payment_share_id
     ), 0) > (
         SELECT amount_due_cents
         FROM payment_shares
         WHERE id = NEW.payment_share_id
     )
BEGIN
    SELECT RAISE(ABORT, 'settlements exceed the share amount');
END;

CREATE TRIGGER share_settlements_total_update_guard
BEFORE UPDATE OF payment_share_id, amount_cents ON share_settlements
WHEN NEW.amount_cents + COALESCE((
         SELECT SUM(amount_cents)
         FROM share_settlements
         WHERE payment_share_id = NEW.payment_share_id
           AND id <> OLD.id
     ), 0) > (
         SELECT amount_due_cents
         FROM payment_shares
         WHERE id = NEW.payment_share_id
     )
BEGIN
    SELECT RAISE(ABORT, 'settlements exceed the share amount');
END;

CREATE TRIGGER payment_shares_amount_update_guard
BEFORE UPDATE OF amount_due_cents ON payment_shares
WHEN NEW.amount_due_cents < COALESCE((
         SELECT SUM(amount_cents)
         FROM share_settlements
         WHERE payment_share_id = NEW.id
     ), 0)
BEGIN
    SELECT RAISE(ABORT, 'share amount is below its existing settlements');
END;

PRAGMA user_version = 1;

COMMIT;
