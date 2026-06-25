-- ============================================================
--  ДОПОЛНЕНИЕ К СХЕМЕ: РЕЖИМ ШИФРОВАНИЯ (SAFE MODE)
--  
--  Концепция:
--    При включении safe_mode приложение генерирует
--    одноразовый симметричный ключ (AES-256) и показывает
--    его пользователю. Без ввода этого ключа в UI весь
--    контент (текст, медиа, аудио/видео звонки) отображается
--    как зашифрованный мусор — даже если E2E уже расшифровал
--    транспортный слой. Это второй, клиентский слой шифрования.
-- ============================================================


-- ─────────────────────────────────────────
--  1. НАСТРОЙКИ РЕЖИМА ШИФРОВАНИЯ
--     Добавляется к существующей таблице privacy
--     (ALTER TABLE вместо новой таблицы)
-- ─────────────────────────────────────────

ALTER TABLE privacy
    ADD COLUMN safe_mode_enabled   BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN safe_mode_hint      VARCHAR(100)          DEFAULT NULL;
    -- safe_mode_hint — необязательная подсказка ("ключ у мамы"),
    -- НЕ сам ключ — ключ никогда не хранится на сервере

-- ─────────────────────────────────────────
--  2. СЕССИОННЫЕ КЛЮЧИ SAFE MODE
--     Каждый раз при входе / смене устройства генерируется
--     новый ключ. Сервер хранит только зашифрованную
--     версию ключа (обёрнутую публичным ключом пользователя),
--     чтобы синхронизировать ключ между устройствами одного
--     пользователя. Расшифровать может только сам пользователь.
-- ─────────────────────────────────────────

CREATE TABLE safe_mode_session (
    id                  BIGSERIAL       PRIMARY KEY,
    user_id             BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,

    -- Ключ, зашифрованный публичным ключом пользователя (RSA/Curve25519)
    -- Сервер не может его прочитать
    encrypted_safe_key  TEXT            NOT NULL,

    -- Fingerprint ключа — показывается в UI для сверки
    -- (первые 8 символов Base58 от SHA-256 ключа)
    key_fingerprint     VARCHAR(20)     NOT NULL,

    -- С какого устройства/сессии создан ключ
    device_label        VARCHAR(100)             DEFAULT NULL,  -- "iPhone 15", "Chrome / Windows"

    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMPTZ              DEFAULT NULL,  -- NULL = бессрочно до смены

    UNIQUE (user_id, key_fingerprint)
);

CREATE INDEX idx_safe_session_user ON safe_mode_session(user_id, is_active);


-- ─────────────────────────────────────────
--  3. ЗАШИФРОВАННЫЕ СООБЩЕНИЯ В SAFE MODE
--     Когда отправитель включил safe mode, сообщение
--     шифруется повторно его safe-ключом ДО отправки.
--     Получатель видит мусор пока не вставит ключ.
-- ─────────────────────────────────────────

ALTER TABLE message
    ADD COLUMN safe_mode_encrypted   BOOLEAN      NOT NULL DEFAULT FALSE,
    -- Если TRUE — encrypted_text содержит ДВОЙНОЕ шифрование:
    -- сначала safe-ключ отправителя, потом E2E.
    -- Получатель расшифровывает E2E → видит safe-ciphertext →
    -- для чтения нужен safe-ключ отправителя (которым поделились).

    ADD COLUMN safe_key_fingerprint  VARCHAR(20)           DEFAULT NULL;
    -- Fingerprint safe-ключа отправителя, чтобы получатель
    -- знал, КАКОЙ именно ключ нужно ввести


-- ─────────────────────────────────────────
--  4. ЗАШИФРОВАННЫЕ ВЛОЖЕНИЯ В SAFE MODE
--     Файлы (фото, видео, аудио) шифруются дополнительно
-- ─────────────────────────────────────────

ALTER TABLE attachment
    ADD COLUMN safe_mode_encrypted      BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN safe_encrypted_file_key  TEXT                  DEFAULT NULL,
    -- Ключ AES файла, зашифрованный safe-ключом отправителя
    -- (сам файл уже зашифрован в поле encryption_key через E2E)
    -- Двойная защита: E2E + safe layer

    ADD COLUMN safe_key_fingerprint     VARCHAR(20)           DEFAULT NULL;


-- ─────────────────────────────────────────
--  5. SAFE MODE В ЗВОНКАХ
--     Аудио/видео потоки тоже идут через safe-слой.
--     Сервер получает зашифрованные медиа-потоки,
--     которые без ключа — тишина и чёрный экран.
-- ─────────────────────────────────────────

ALTER TABLE call
    ADD COLUMN safe_mode_enabled    BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN safe_key_fingerprint VARCHAR(20)           DEFAULT NULL;
    -- При safe_mode_enabled=TRUE клиент должен запросить
    -- safe-ключ перед тем как декодировать WebRTC поток


-- ─────────────────────────────────────────
--  6. ИСТОРИЯ ВЫДАННЫХ КЛЮЧЕЙ
--     Лог: когда был выдан ключ, кому, через какой канал
--     (QR, текст, и т.д.) — для аудита самого пользователя
-- ─────────────────────────────────────────

CREATE TABLE safe_mode_key_share_log (
    id                  BIGSERIAL       PRIMARY KEY,
    session_id          BIGINT          NOT NULL REFERENCES safe_mode_session(id) ON DELETE CASCADE,
    owner_id            BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    shared_with_user_id BIGINT                   REFERENCES user(id) ON DELETE SET NULL,
    -- NULL = поделился вне приложения (скопировал вручную)

    share_method        VARCHAR(30)     NOT NULL DEFAULT 'copy',
    -- copy | qr_code | link | nfc

    shared_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    revoked_at          TIMESTAMPTZ              DEFAULT NULL  -- если отозвал доступ
);

CREATE INDEX idx_key_share_owner ON safe_mode_key_share_log(owner_id);
CREATE INDEX idx_key_share_session ON safe_mode_key_share_log(session_id);


-- ─────────────────────────────────────────
--  7. UI-СОСТОЯНИЕ: ВВЁЛ ЛИ ПОЛЬЗОВАТЕЛЬ КЛЮЧ
--     Хранится только на клиенте (в памяти / localStorage).
--     На сервере — только факт, что сессия активна.
--     Эта таблица нужна для серверной синхронизации
--     между вкладками/устройствами одного пользователя.
-- ─────────────────────────────────────────

CREATE TABLE safe_mode_ui_state (
    id                  BIGSERIAL       PRIMARY KEY,
    user_id             BIGINT          NOT NULL REFERENCES user(id) ON DELETE CASCADE,
    session_id          BIGINT          NOT NULL REFERENCES safe_mode_session(id) ON DELETE CASCADE,
    device_label        VARCHAR(100),
    key_unlocked        BOOLEAN         NOT NULL DEFAULT FALSE,
    -- TRUE = пользователь ввёл ключ в этой сессии UI
    -- Сбрасывается при выходе или через expire_unlocked_at
    unlocked_at         TIMESTAMPTZ              DEFAULT NULL,
    expire_unlocked_at  TIMESTAMPTZ              DEFAULT NULL,
    -- Например: автоблокировка через 1 час без активности
    last_seen_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, device_label)
);

CREATE INDEX idx_safe_ui_user ON safe_mode_ui_state(user_id);


-- ─────────────────────────────────────────
--  ИТОГО: ЧТО ПРОИСХОДИТ ПРИ SAFE MODE
-- ─────────────────────────────────────────
--
--  ОТПРАВИТЕЛЬ (safe mode включён):
--    1. Приложение генерирует safe_key (AES-256)
--    2. Показывает ключ пользователю (1 раз, как seed-фраза)
--    3. Зашифровывает encrypted_safe_key публичным ключом → сервер
--    4. Все message.encrypted_text шифруются: AES(safe_key) → E2E
--    5. safe_mode_encrypted=TRUE, safe_key_fingerprint=первые 8 символов
--
--  ПОЛУЧАТЕЛЬ (без ключа):
--    → видит message.encrypted_text после E2E-расшифровки: "a7Fk2#Xp..."
--    → фото/видео не открываются (чёрный экран)
--    → в звонке: тишина и серый экран
--    → в углу UI: поле "Введите ключ [________]"
--
--  ПОЛУЧАТЕЛЬ (ключ введён):
--    → приложение расшифровывает safe-слой локально
--    → видит читаемый текст, фото, слышит аудио
--    → ключ живёт только в памяти (не сохраняется на сервере)
-- ============================================================
