-- ============================================================
--  MESSENGER DATABASE SCHEMA
--  Encryption: AES-256-GCM (E2E)
--  All message content is stored encrypted
-- ============================================================

-- ─────────────────────────────────────────
--  ACCOUNTS
-- ─────────────────────────────────────────

CREATE TABLE user (
    id              BIGSERIAL       PRIMARY KEY,
    username        VARCHAR(50)     NOT NULL UNIQUE,
    phone_number    VARCHAR(20)     NOT NULL UNIQUE,
    email           VARCHAR(255)    UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,           -- bcrypt / argon2
    public_key      TEXT            NOT NULL,           -- RSA / Curve25519 public key for E2E
    is_online       BOOLEAN         NOT NULL DEFAULT FALSE,
    last_seen       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE TABLE profile (
    id          BIGSERIAL       PRIMARY KEY,
    user_id     BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    name        VARCHAR(100),
    photo       TEXT,                                   -- URL or file path
    bio         TEXT,
    birthday    DATE,
    status      VARCHAR(200)                            -- custom status text
);

CREATE TABLE user_key (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    public_key      TEXT            NOT NULL,
    key_fingerprint VARCHAR(100)    NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE
);
-- When the user changes device a new key is generated; old messages stay readable via old key

-- ─────────────────────────────────────────
--  SETTINGS
-- ─────────────────────────────────────────

CREATE TABLE chat_settings (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    theme           VARCHAR(20)     NOT NULL DEFAULT 'system',   -- light | dark | system
    text_size       VARCHAR(20)     NOT NULL DEFAULT 'medium',   -- small | medium | large
    notifications   BOOLEAN         NOT NULL DEFAULT TRUE,
    language        VARCHAR(10)     NOT NULL DEFAULT 'ru'
);

CREATE TABLE privacy (
    id                      BIGSERIAL   PRIMARY KEY,
    user_id                 BIGINT      NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    see_phone_number        VARCHAR(20) NOT NULL DEFAULT 'contacts',  -- everyone | contacts | nobody
    see_profile_photo       VARCHAR(20) NOT NULL DEFAULT 'everyone',
    see_last_seen           VARCHAR(20) NOT NULL DEFAULT 'everyone',
    autodeleting_messages   BOOLEAN     NOT NULL DEFAULT FALSE,
    message_ttl_days        INT                  DEFAULT NULL,         -- NULL = no auto-delete
    two_factor_auth         BOOLEAN     NOT NULL DEFAULT FALSE,
    time_of_sunset          TIME                 DEFAULT NULL          -- daily quiet hours start
);

CREATE TABLE app_language (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    language        VARCHAR(10)     NOT NULL DEFAULT 'ru',
    translate_text  BOOLEAN         NOT NULL DEFAULT FALSE             -- auto-translate incoming msgs
);

-- ─────────────────────────────────────────
--  CONTACTS & BLOCKS
-- ─────────────────────────────────────────

CREATE TABLE contact (
    id              BIGSERIAL       PRIMARY KEY,
    owner_id        BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    contact_id      BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    nickname        VARCHAR(100),                                      -- custom name for this contact
    is_blocked      BOOLEAN         NOT NULL DEFAULT FALSE,
    added_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (owner_id, contact_id)
);

-- ─────────────────────────────────────────
--  CONVERSATIONS (direct + group + channel)
-- ─────────────────────────────────────────

CREATE TABLE conversation (
    id              BIGSERIAL       PRIMARY KEY,
    type            VARCHAR(20)     NOT NULL,                          -- direct | group | channel
    name            VARCHAR(100),                                      -- NULL for direct chats
    photo           TEXT,
    description     TEXT,
    invite_link     VARCHAR(100)    UNIQUE,
    created_by      BIGINT          REFERENCES user(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE TABLE conversation_member (
    id                  BIGSERIAL   PRIMARY KEY,
    conversation_id     BIGINT      NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
    user_id             BIGINT      NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    role                VARCHAR(20) NOT NULL DEFAULT 'member',         -- owner | admin | member
    joined_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted            BOOLEAN     NOT NULL DEFAULT FALSE,
    mute_until          TIMESTAMPTZ          DEFAULT NULL,
    last_read_message_id BIGINT              DEFAULT NULL,
    UNIQUE (conversation_id, user_id)
);

-- ─────────────────────────────────────────
--  MESSAGES  (E2E encrypted)
-- ─────────────────────────────────────────

CREATE TABLE message (
    id                  BIGSERIAL       PRIMARY KEY,
    conversation_id     BIGINT          NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
    sender_id           BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    -- Encrypted payload (AES-256-GCM)
    encrypted_text      TEXT,                                          -- base64 ciphertext
    iv                  VARCHAR(50),                                   -- base64 initialisation vector
    -- Metadata
    message_type        VARCHAR(20)     NOT NULL DEFAULT 'text',       -- text | image | audio | video | file | sticker
    reply_to_id         BIGINT          REFERENCES message(id) ON DELETE SET NULL,
    forwarded_from_id   BIGINT          REFERENCES message(id) ON DELETE SET NULL,
    is_edited           BOOLEAN         NOT NULL DEFAULT FALSE,
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    sent_at             TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMPTZ              DEFAULT NULL           -- self-destruct timestamp
);

CREATE TABLE message_status (
    id          BIGSERIAL       PRIMARY KEY,
    message_id  BIGINT          NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    user_id     BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    status      VARCHAR(20)     NOT NULL DEFAULT 'sent',               -- sent | delivered | seen
    seen_at     TIMESTAMPTZ              DEFAULT NULL,
    UNIQUE (message_id, user_id)
);

-- ─────────────────────────────────────────
--  ATTACHMENTS  (E2E encrypted files)
-- ─────────────────────────────────────────

CREATE TABLE attachment (
    id                  BIGSERIAL       PRIMARY KEY,
    message_id          BIGINT          NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    file_url            TEXT            NOT NULL,
    file_type           VARCHAR(50)     NOT NULL,                      -- image/jpeg, audio/ogg, etc.
    file_size           BIGINT          NOT NULL,                      -- bytes
    file_name           VARCHAR(255),
    duration_seconds    INT,                                           -- for audio / video
    width               INT,                                           -- for image / video
    height              INT,
    thumbnail_url       TEXT,
    encryption_key      TEXT            NOT NULL,                      -- per-file AES key (encrypted with recipient public key)
    encryption_iv       VARCHAR(50)     NOT NULL
);

-- ─────────────────────────────────────────
--  REACTIONS
-- ─────────────────────────────────────────

CREATE TABLE reaction (
    id          BIGSERIAL       PRIMARY KEY,
    message_id  BIGINT          NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    user_id     BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    emoji       VARCHAR(10)     NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (message_id, user_id, emoji)
);

-- ─────────────────────────────────────────
--  CALLS
-- ─────────────────────────────────────────

CREATE TABLE call (
    id                  BIGSERIAL       PRIMARY KEY,
    conversation_id     BIGINT          NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
    initiator_id        BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    call_type           VARCHAR(20)     NOT NULL,                      -- voice | video
    status              VARCHAR(20)     NOT NULL DEFAULT 'ringing',    -- ringing | active | ended | missed | rejected
    started_at          TIMESTAMPTZ              DEFAULT NULL,
    ended_at            TIMESTAMPTZ              DEFAULT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE call_participant (
    id          BIGSERIAL       PRIMARY KEY,
    call_id     BIGINT          NOT NULL REFERENCES call(id) ON DELETE CASCADE,
    user_id     BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ              DEFAULT NULL,
    left_at     TIMESTAMPTZ              DEFAULT NULL,
    UNIQUE (call_id, user_id)
);

-- ─────────────────────────────────────────
--  STORIES (24-hour posts)
-- ─────────────────────────────────────────

CREATE TABLE story (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    media_url       TEXT            NOT NULL,
    media_type      VARCHAR(20)     NOT NULL,                          -- image | video
    caption         TEXT,
    encryption_key  TEXT,
    encryption_iv   VARCHAR(50),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ     NOT NULL                           -- usually created_at + 24h
);

CREATE TABLE story_view (
    id          BIGSERIAL       PRIMARY KEY,
    story_id    BIGINT          NOT NULL REFERENCES story(id) ON DELETE CASCADE,
    viewer_id   BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    viewed_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (story_id, viewer_id)
);

-- ─────────────────────────────────────────
--  INDEXES  (performance)
-- ─────────────────────────────────────────

CREATE INDEX idx_message_conversation   ON message(conversation_id, sent_at DESC);
CREATE INDEX idx_message_sender         ON message(sender_id);
CREATE INDEX idx_message_status         ON message_status(message_id);
CREATE INDEX idx_conv_member_user       ON conversation_member(user_id);
CREATE INDEX idx_conv_member_conv       ON conversation_member(conversation_id);
CREATE INDEX idx_contact_owner          ON contact(owner_id);
CREATE INDEX idx_story_user             ON story(user_id, expires_at);
CREATE INDEX idx_user_phone             ON user(phone_number);
CREATE INDEX idx_user_username          ON user(username);
