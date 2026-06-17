-- ══════════════════════════════════════════════════════════════════════════
-- StockRoom — Device Licensing Schema  (v9)
--
-- CHANGES FROM v8
-- ───────────────
-- • PATH 2 fingerprint-collision guard added.
--   Fingerprints are not globally unique — two identical device models on the
--   same OS produce the same string (platform|manufacturer|model|osVersion|physical).
--   Previously PATH 2 would merge the factory-reset device into whichever matching
--   row had the most recent last_seen_at, which could be the WRONG device's row
--   when a store has two identical handsets.
--   Fix: PATH 2 now counts ALL rows (active and inactive) in the store with the
--   presented fingerprint before attempting a merge. If the count is exactly 1 the
--   fingerprint is unambiguous and merging is safe. If 2 or more rows share the
--   fingerprint the path is skipped entirely and the device falls through to PATH 3
--   (new-device registration). The admin must deactivate the stale old row before
--   the reset device can re-enter; this surfaces the ambiguity explicitly rather
--   than silently associating the wrong slot.
--   Inactive rows are included in the count deliberately: deactivating the old row
--   would otherwise drop the count to 1, causing PATH 2 to merge the reset device
--   into a still-active identical device's row.
--   Applies equally to iOS (Keychain UUID) and Android (ANDROID_ID).
--
-- CHANGES FROM v7
-- ───────────────
-- • Table-level lock replaced with per-store row lock (FOR UPDATE on stores).
--   Previously LOCK TABLE devices IN SHARE ROW EXCLUSIVE MODE serialised every
--   check-in globally — all stores queued behind a single lock. Now each store
--   row is locked independently, so concurrent check-ins across different stores
--   run in parallel. Seat-counting correctness is preserved: the FOR UPDATE on
--   the store row blocks any second transaction for the same store until the
--   first commits, which is exactly the invariant needed.
-- • relicense_attempts / last_relicense_attempt now written on every blocked
--   check-in (device_inactive, entitlement_revoked) in PATH 1 and PATH 2.
--   Previously the columns existed but were never populated.
--
-- CHANGES FROM v6
-- ───────────────
-- • pgcrypto extension enabled (required for HMAC signing).
-- • New helper function _gate_hmac(): computes HMAC-SHA256 of the canonical
--   gate response fields. Not callable by the anon role directly.
-- • validate_and_register_device v7: every RETURN now includes an 'hmac' field
--   signed by _gate_hmac(). The mobile client verifies this signature before
--   trusting the response and before caching an approved entitlement.
--   Protects against response substitution in transit (MiTM on LAN) and
--   tampering of the locally cached entitlement on the device.
--
-- CHANGES FROM v5
-- ───────────────
-- • stores.max_devices_updated_at column added (TIMESTAMPTZ NOT NULL DEFAULT NOW())
--   Tracks when max_devices was last reduced. Drives "first-to-open-wins"
--   slot allocation when the limit is reduced below the active device count.
-- • Trigger trg_max_devices_reduced: automatically sets max_devices_updated_at
--   = NOW() whenever max_devices is decreased on a store row. No admin action
--   needed — just run the normal UPDATE stores SET max_devices = N.
-- • validate_and_register_device v6: rank check in PATH 1 & PATH 2 now counts
--   devices that have checked in AFTER max_devices_updated_at (not ranked by
--   historical last_seen_at). First device to open after a reduction claims a
--   slot; later openers are revoked. Replaces the previous behaviour where the
--   most-recently-seen-before-reduction device won.
-- • Added idx_devices_store_last_seen index to support the rank check.
-- ══════════════════════════════════════════════════════════════════════════


-- ── Extensions ───────────────────────────────────────────────────────────
-- pgcrypto is pre-installed on Supabase; this is a no-op if already enabled.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


-- ── Tables ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS stores (
  store_id               TEXT        PRIMARY KEY,
  description            TEXT,
  max_devices            INTEGER     NOT NULL DEFAULT 1,
  max_devices_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  block_emulators        BOOLEAN     NOT NULL DEFAULT FALSE,
  is_active              BOOLEAN     NOT NULL DEFAULT TRUE,
  valid_until            DATE
);

-- Safe to run on existing databases — no-op if column already exists.
ALTER TABLE stores ADD COLUMN IF NOT EXISTS
  max_devices_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE TABLE IF NOT EXISTS devices (
  hardware_id            TEXT      PRIMARY KEY,
  store_id               TEXT      NOT NULL REFERENCES stores(store_id),
  device_name            TEXT,
  device_model           TEXT,
  system_name            TEXT,
  system_version         TEXT,
  is_physical            BOOLEAN,
  is_active              BOOLEAN   NOT NULL DEFAULT TRUE,
  registered_at          TIMESTAMP NOT NULL DEFAULT NOW(),
  last_seen_at           TIMESTAMP,
  store_description      TEXT,
  relicense_attempts     INTEGER   NOT NULL DEFAULT 0,
  last_relicense_attempt TIMESTAMP WITH TIME ZONE,
  device_fingerprint     TEXT,
  install_token          TEXT,
  reinstall_count        INTEGER   NOT NULL DEFAULT 0,
  last_hardware_id       TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_devices_store_active
  ON devices (store_id, is_active);

CREATE INDEX IF NOT EXISTS idx_devices_hardware_id
  ON devices (hardware_id);

CREATE INDEX IF NOT EXISTS idx_devices_fingerprint_store
  ON devices (store_id, device_fingerprint);

-- Supports the post-reduction rank check (count openers since max_devices_updated_at)
CREATE INDEX IF NOT EXISTS idx_devices_store_last_seen
  ON devices (store_id, is_active, last_seen_at);


-- ── Row-Level Security ────────────────────────────────────────────────────
-- Anon key cannot touch tables directly.
-- All reads/writes go through validate_and_register_device (SECURITY DEFINER).

ALTER TABLE stores  ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
     WHERE tablename = 'stores' AND policyname = 'deny_anon_stores'
  ) THEN
    CREATE POLICY deny_anon_stores ON stores FOR ALL TO anon USING (false);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
     WHERE tablename = 'devices' AND policyname = 'deny_anon_devices'
  ) THEN
    CREATE POLICY deny_anon_devices ON devices FOR ALL TO anon USING (false);
  END IF;
END $$;


-- ── Trigger: auto-stamp max_devices_updated_at on reduction ──────────────
-- Fires BEFORE any UPDATE that lowers max_devices. Sets max_devices_updated_at
-- to NOW() so the RPC knows when the current limit epoch began.
-- Increasing max_devices does NOT reset the timestamp — existing slot-holders
-- keep their positions and newly freed slots open up to the next opener.

CREATE OR REPLACE FUNCTION trg_set_max_devices_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.max_devices < OLD.max_devices THEN
    NEW.max_devices_updated_at := NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_max_devices_reduced ON stores;
CREATE TRIGGER trg_max_devices_reduced
  BEFORE UPDATE OF max_devices ON stores
  FOR EACH ROW
  EXECUTE FUNCTION trg_set_max_devices_updated_at();


-- ── HMAC helper ───────────────────────────────────────────────────────────
-- Computes HMAC-SHA256 of the canonical gate response.
-- Message format (pipe-separated, no spaces):
--   "{allowed}|{reason}|{valid_until}|{hardware_id}|{store_id}"
-- where allowed = 'true'/'false', valid_until = 'YYYY-MM-DD' or ''.
--
-- The secret MUST match LicenseConstants.hmacSecret in the Flutter app.
-- This function is intentionally NOT granted to the anon role — it is only
-- called internally from validate_and_register_device (SECURITY DEFINER).

CREATE OR REPLACE FUNCTION _gate_hmac(
  p_allowed      BOOLEAN,
  p_reason       TEXT,
  p_valid_until  DATE,
  p_hardware_id  TEXT,
  p_store_id     TEXT
)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT encode(
    extensions.hmac(
      (
        CASE WHEN p_allowed THEN 'true' ELSE 'false' END
        || '|' || COALESCE(p_reason, '')
        || '|' || COALESCE(p_valid_until::text, '')
        || '|' || COALESCE(p_hardware_id, '')
        || '|' || COALESCE(p_store_id, '')
      )::bytea,
      '95ee072bcc2bd55251c4b0bd0485ca910f0c2ffccfa3dd1f1787b1cfca6d614b'::bytea,
      'sha256'
    ),
    'hex'
  );
$$;

-- Prevent the anon role from calling the helper directly.
REVOKE EXECUTE ON FUNCTION _gate_hmac(BOOLEAN, TEXT, DATE, TEXT, TEXT) FROM PUBLIC;


-- ── RPC Function ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION validate_and_register_device(
  store_id           TEXT,
  hardware_id        TEXT,
  device_name        TEXT,
  device_model       TEXT,
  system_name        TEXT,
  system_version     TEXT,
  is_physical        BOOLEAN,
  store_description  TEXT DEFAULT NULL,
  device_fingerprint TEXT DEFAULT NULL,
  install_token      TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_store          stores%ROWTYPE;
  v_device         devices%ROWTYPE;
  v_fp_device      devices%ROWTYPE;
  v_device_count   INT;
  v_rank           INT;
BEGIN

  -- ── 1. Load store (with row lock) ────────────────────────────────────────
  -- FOR UPDATE locks only this store's row. Concurrent check-ins for the same
  -- store queue here; check-ins for other stores run in parallel unaffected.
  -- Replaces the previous LOCK TABLE devices which serialised all stores globally.
  SELECT * INTO v_store FROM stores
  WHERE stores.store_id = validate_and_register_device.store_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'allowed', FALSE, 'reason', 'store_not_found', 'valid_until', NULL,
      'hmac', _gate_hmac(FALSE, 'store_not_found', NULL, hardware_id, store_id)
    );
  END IF;

  IF NOT v_store.is_active THEN
    RETURN json_build_object(
      'allowed', FALSE, 'reason', 'store_inactive', 'valid_until', v_store.valid_until,
      'hmac', _gate_hmac(FALSE, 'store_inactive', v_store.valid_until, hardware_id, store_id)
    );
  END IF;

  -- ── 2. Licence expiry ─────────────────────────────────────────────────────
  IF v_store.valid_until IS NOT NULL AND v_store.valid_until < CURRENT_DATE THEN
    RETURN json_build_object(
      'allowed', FALSE, 'reason', 'licence_expired', 'valid_until', v_store.valid_until,
      'hmac', _gate_hmac(FALSE, 'licence_expired', v_store.valid_until, hardware_id, store_id)
    );
  END IF;

  -- ── 3. Emulator guard ─────────────────────────────────────────────────────
  IF v_store.block_emulators AND NOT is_physical THEN
    RETURN json_build_object(
      'allowed', FALSE, 'reason', 'emulator_blocked', 'valid_until', v_store.valid_until,
      'hmac', _gate_hmac(FALSE, 'emulator_blocked', v_store.valid_until, hardware_id, store_id)
    );
  END IF;

  -- ── 4. Optional: refresh store description ────────────────────────────────
  IF store_description IS NOT NULL AND store_description <> '' THEN
    UPDATE stores SET description = validate_and_register_device.store_description
    WHERE stores.store_id = validate_and_register_device.store_id;
  END IF;

  -- ── 5. Count active devices ───────────────────────────────────────────────
  -- Seat-count correctness is guaranteed by the FOR UPDATE on the store row
  -- above — no second transaction for this store can reach this point until
  -- the current one commits. Count active devices for this store — reused by
  -- all three paths below.
  SELECT COUNT(*) INTO v_device_count
  FROM devices
  WHERE devices.store_id = validate_and_register_device.store_id
    AND is_active = TRUE;

  -- ─────────────────────────────────────────────────────────────────────────
  -- PATH 1 — Exact hardware_id match (normal launch, Keychain/SSAID intact)
  -- ─────────────────────────────────────────────────────────────────────────
  SELECT * INTO v_device
  FROM devices
  WHERE devices.store_id    = validate_and_register_device.store_id
    AND devices.hardware_id = validate_and_register_device.hardware_id
  LIMIT 1;

  IF FOUND THEN
    IF NOT v_device.is_active THEN
      UPDATE devices SET
        relicense_attempts     = relicense_attempts + 1,
        last_relicense_attempt = NOW()
      WHERE devices.store_id    = v_device.store_id
        AND devices.hardware_id = v_device.hardware_id;
      RETURN json_build_object(
        'allowed', FALSE, 'reason', 'device_inactive', 'valid_until', v_store.valid_until,
        'hmac', _gate_hmac(FALSE, 'device_inactive', v_store.valid_until, hardware_id, store_id)
      );
    END IF;

    -- When active device count exceeds max_devices (limit was reduced), determine
    -- whether this device still holds a slot using first-to-open-after-reduction
    -- ordering. v_rank is the number of OTHER active devices that have already
    -- checked in since max_devices_updated_at. If those devices fill all slots,
    -- this device opened too late and its entitlement is revoked.
    -- The FOR UPDATE on the store row serialises concurrent check-ins so there are no ties.
    IF v_store.max_devices IS NOT NULL AND v_device_count > v_store.max_devices THEN
      SELECT COUNT(*) INTO v_rank
      FROM devices
      WHERE devices.store_id     = validate_and_register_device.store_id
        AND devices.is_active    = TRUE
        AND devices.hardware_id <> validate_and_register_device.hardware_id
        AND devices.last_seen_at >= v_store.max_devices_updated_at;

      IF v_rank >= v_store.max_devices THEN
        UPDATE devices SET
          relicense_attempts     = relicense_attempts + 1,
          last_relicense_attempt = NOW()
        WHERE devices.store_id    = v_device.store_id
          AND devices.hardware_id = v_device.hardware_id;
        RETURN json_build_object(
          'allowed', FALSE, 'reason', 'entitlement_revoked', 'valid_until', v_store.valid_until,
          'hmac', _gate_hmac(FALSE, 'entitlement_revoked', v_store.valid_until, hardware_id, store_id)
        );
      END IF;
    END IF;

    UPDATE devices SET
      device_name        = validate_and_register_device.device_name,
      device_model       = validate_and_register_device.device_model,
      system_name        = validate_and_register_device.system_name,
      system_version     = validate_and_register_device.system_version,
      is_physical        = validate_and_register_device.is_physical,
      last_seen_at       = NOW(),
      device_fingerprint = COALESCE(validate_and_register_device.device_fingerprint, v_device.device_fingerprint),
      install_token      = validate_and_register_device.install_token,
      store_description  = COALESCE(validate_and_register_device.store_description, v_device.store_description)
    WHERE devices.store_id    = v_device.store_id
      AND devices.hardware_id = v_device.hardware_id;

    RETURN json_build_object(
      'allowed', TRUE, 'reason', 'existing_device', 'valid_until', v_store.valid_until,
      'hmac', _gate_hmac(TRUE, 'existing_device', v_store.valid_until, hardware_id, store_id)
    );
  END IF;

  -- ─────────────────────────────────────────────────────────────────────────
  -- PATH 2 — Fingerprint match, different hardware_id (factory reset / reinstall
  --           where Keychain was wiped). Merges into existing row — no new slot.
  --
  -- Guard: only attempt the merge when exactly ONE row (active or inactive) in
  -- this store shares the fingerprint. Two or more rows means two identical
  -- physical devices have ever existed here — we cannot tell which one reset,
  -- so we fall through to PATH 3 rather than risk merging into the wrong row.
  -- Inactive rows are counted intentionally: if the admin deactivates the stale
  -- row the count drops to 1 only when the other identical device is also gone,
  -- which is the correct point at which the fingerprint becomes unambiguous again.
  -- ─────────────────────────────────────────────────────────────────────────
  IF device_fingerprint IS NOT NULL AND device_fingerprint <> '' THEN
    IF (SELECT COUNT(*) FROM devices
        WHERE devices.store_id           = validate_and_register_device.store_id
          AND devices.device_fingerprint = validate_and_register_device.device_fingerprint
    ) = 1 THEN

    SELECT * INTO v_fp_device
    FROM devices
    WHERE devices.store_id           = validate_and_register_device.store_id
      AND devices.device_fingerprint = validate_and_register_device.device_fingerprint
    ORDER BY last_seen_at DESC
    LIMIT 1;

    IF FOUND THEN
      IF NOT v_fp_device.is_active THEN
        UPDATE devices SET
          relicense_attempts     = relicense_attempts + 1,
          last_relicense_attempt = NOW()
        WHERE devices.store_id    = v_fp_device.store_id
          AND devices.hardware_id = v_fp_device.hardware_id;
        RETURN json_build_object(
          'allowed', FALSE, 'reason', 'device_inactive', 'valid_until', v_store.valid_until,
          'hmac', _gate_hmac(FALSE, 'device_inactive', v_store.valid_until, hardware_id, store_id)
        );
      END IF;

      -- Same first-to-open-after-reduction ranking as PATH 1. The reinstalled
      -- device inherits its old row's slot but must still race for it if the
      -- limit was reduced while the device was being reinstalled.
      IF v_store.max_devices IS NOT NULL AND v_device_count > v_store.max_devices THEN
        SELECT COUNT(*) INTO v_rank
        FROM devices
        WHERE devices.store_id     = validate_and_register_device.store_id
          AND devices.is_active    = TRUE
          AND devices.hardware_id <> v_fp_device.hardware_id
          AND devices.last_seen_at >= v_store.max_devices_updated_at;

        IF v_rank >= v_store.max_devices THEN
          UPDATE devices SET
            relicense_attempts     = relicense_attempts + 1,
            last_relicense_attempt = NOW()
          WHERE devices.store_id    = v_fp_device.store_id
            AND devices.hardware_id = v_fp_device.hardware_id;
          RETURN json_build_object(
            'allowed', FALSE, 'reason', 'entitlement_revoked', 'valid_until', v_store.valid_until,
            'hmac', _gate_hmac(FALSE, 'entitlement_revoked', v_store.valid_until, hardware_id, store_id)
          );
        END IF;
      END IF;

      UPDATE devices SET
        hardware_id        = validate_and_register_device.hardware_id,
        last_hardware_id   = v_fp_device.hardware_id,
        device_name        = validate_and_register_device.device_name,
        device_model       = validate_and_register_device.device_model,
        system_name        = validate_and_register_device.system_name,
        system_version     = validate_and_register_device.system_version,
        is_physical        = validate_and_register_device.is_physical,
        last_seen_at       = NOW(),
        install_token      = validate_and_register_device.install_token,
        reinstall_count    = COALESCE(v_fp_device.reinstall_count, 0) + 1,
        store_description  = COALESCE(validate_and_register_device.store_description, v_fp_device.store_description)
      WHERE devices.store_id    = v_fp_device.store_id
        AND devices.hardware_id = v_fp_device.hardware_id;

      RETURN json_build_object(
        'allowed', TRUE, 'reason', 'reinstall_merged', 'valid_until', v_store.valid_until,
        'hmac', _gate_hmac(TRUE, 'reinstall_merged', v_store.valid_until, hardware_id, store_id)
      );
    END IF;  -- IF FOUND
    END IF;  -- fingerprint count = 1
  END IF;  -- device_fingerprint not null

  -- ─────────────────────────────────────────────────────────────────────────
  -- PATH 3 — Brand new device. Device not yet counted so use >=
  -- ─────────────────────────────────────────────────────────────────────────
  IF v_store.max_devices IS NOT NULL AND v_device_count >= v_store.max_devices THEN
    RETURN json_build_object(
      'allowed', FALSE, 'reason', 'device_limit_reached', 'valid_until', v_store.valid_until,
      'hmac', _gate_hmac(FALSE, 'device_limit_reached', v_store.valid_until, hardware_id, store_id)
    );
  END IF;

  INSERT INTO devices (
    store_id, hardware_id, device_name, device_model,
    system_name, system_version, is_physical,
    registered_at, last_seen_at, is_active,
    device_fingerprint, install_token, store_description,
    reinstall_count
  ) VALUES (
    validate_and_register_device.store_id,
    validate_and_register_device.hardware_id,
    validate_and_register_device.device_name,
    validate_and_register_device.device_model,
    validate_and_register_device.system_name,
    validate_and_register_device.system_version,
    validate_and_register_device.is_physical,
    NOW(), NOW(), TRUE,
    validate_and_register_device.device_fingerprint,
    validate_and_register_device.install_token,
    validate_and_register_device.store_description,
    0
  );

  RETURN json_build_object(
    'allowed', TRUE, 'reason', 'new_device', 'valid_until', v_store.valid_until,
    'hmac', _gate_hmac(TRUE, 'new_device', v_store.valid_until, hardware_id, store_id)
  );

END;
$$;

GRANT EXECUTE ON FUNCTION validate_and_register_device TO anon;


-- ── Admin reference ───────────────────────────────────────────────────────
-- Deactivate a device:
--   UPDATE devices SET is_active = false WHERE hardware_id = 'ios:...';
--
-- Reactivate a device:
--   UPDATE devices SET is_active = true WHERE hardware_id = 'ios:...';
--
-- Deactivate an entire store immediately:
--   UPDATE stores SET is_active = false WHERE store_id = '...';
--
-- Change device limit (trigger auto-stamps max_devices_updated_at on reduction):
--   UPDATE stores SET max_devices = 1 WHERE store_id = '...';
--
-- Manually reset the slot race epoch (forces all devices to re-race):
--   UPDATE stores SET max_devices_updated_at = NOW() WHERE store_id = '...';
--
-- Set / renew subscription expiry:
--   UPDATE stores SET valid_until = '2027-01-01' WHERE store_id = '...';
--
-- Remove expiry (no time limit):
--   UPDATE stores SET valid_until = NULL WHERE store_id = '...';
--
-- Block emulators for a store:
--   UPDATE stores SET block_emulators = true WHERE store_id = '...';
--
-- View all devices for a store:
--   SELECT hardware_id, device_name, device_model, is_active,
--          registered_at, last_seen_at, reinstall_count, last_hardware_id,
--          relicense_attempts, last_relicense_attempt
--     FROM devices
--    WHERE store_id = '...'
--    ORDER BY registered_at;
