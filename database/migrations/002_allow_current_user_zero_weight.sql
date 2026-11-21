PRAGMA foreign_keys = OFF;

BEGIN IMMEDIATE;

ALTER TABLE subscription_participants
    RENAME TO subscription_participants_v1;

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

INSERT INTO subscription_participants (
    subscription_id,
    person_id,
    share_weight,
    created_at,
    updated_at
)
SELECT
    subscription_id,
    person_id,
    share_weight,
    created_at,
    updated_at
FROM subscription_participants_v1;

DROP TABLE subscription_participants_v1;

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

PRAGMA user_version = 2;

COMMIT;

PRAGMA foreign_keys = ON;
