# PayPulse — Security & Access-Control Contract (v2)

This document describes the security model added on 2026-07-05 and the contract
between the Flutter app and Supabase (`https://gnyzctxlqcidubanoiae.supabase.co`).
Run `supabase_migration_v2_security.sql` in the Supabase SQL Editor first.

## 1. Company codes

Each company row in `public.companies` carries three unique 8-character codes
(generated from an unambiguous alphabet, no 0/O/1/I):

| Column | Grants role | Visible to |
|---|---|---|
| `staff_code` | STAFF | Manager, Owner |
| `manager_code` | MANAGER | Owner |
| `owner_code` | OWNER | Owner |

Direct `SELECT` on `companies` is blocked by RLS. Codes are only obtainable via
the `get_company_codes()` RPC, which applies the visibility matrix above.

## 2. Signup flow

1. App calls `validate_company_code(p_code)` (anon-allowed RPC). Returns the
   company name and the role the code grants — never the other codes.
2. App calls `supabase.auth.signUp(email, password, data: {name, company_code})`.
3. DB trigger `handle_new_user` resolves the code again server-side, creates the
   profile with `role` + `company_id` and sets `approval_status`:
   - STAFF → `PENDING` (approved by a manager or owner)
   - MANAGER → `PENDING` (approved by an owner)
   - OWNER → `APPROVED` if the company has no approved owner yet, else `PENDING`
     (approved by an existing owner)
4. While `approval_status != 'APPROVED'`, the app locks the user on the
   "waiting for approval" screen. RLS also blocks all data access
   (`current_role_pp()` returns NULL for non-approved users).

## 3. Approvals

- `get_pending_members()` — managers receive pending STAFF; owners receive all
  pending members of their company.
- `review_member(p_user_id, p_approve)` — enforces hierarchy server-side
  (manager can only approve staff). Sets `approval_status` and `approved_by`.
- The app surfaces pending requests as an alert to managers/owners on login and
  in the "Pending Approvals" section (More → Team).

## 4. Permission matrix (enforced by RLS + triggers)

| Action | STAFF | MANAGER | OWNER |
|---|---|---|---|
| Create invoice | ✔ | ✔ | ✔ |
| Delete / recover invoice | ✔ | ✔ | ✔ |
| Modify existing invoice (items/amounts/customer) | ✖ (blocked by `guard_invoice_edit` trigger) | ✔ | ✔ |
| Update daily rates | ✔ | ✔ | ✔ |
| Add customer / product | ✔ | ✔ | ✔ |
| Manage coupons (update) | ✖ | ✔ | ✔ |
| Export reports | ✖ (UI-gated) | ✔ | ✔ |
| Manage staff access | ✖ | ✔ | ✔ |
| Modify company details (`company_settings`) | ✖ | ✖ | ✔ |
| See staff code | ✖ | ✔ | ✔ |
| See manager + owner codes | ✖ | ✖ | ✔ |

Invoice numbering: the counter lives in `company_settings` (owner-write-only),
so all roles bump it through `next_invoice_number()` /
`rollback_invoice_counter(p_invoice_number)` SECURITY DEFINER RPCs.

## 5. Multi-tenancy

`company_id` was added to `profiles`, `company_settings`, `coupons`,
`customers`, `products`, `invoices`, `daily_rates`, `record_book`. A
`BEFORE INSERT` trigger auto-fills it from the current user's profile, and RLS
scopes every read/write to `company_id = current_company_id()`.

## 6. Other server objects

- `avatars` storage bucket (public read; users may only write objects named
  `<their-uid>*`). Profile photos are stored as `<uid>.jpg` and the public URL
  saved to `profiles.avatar_url`.
- `products` unique index on `(company_id, huid_number)` — HUID is the unique
  product identifier. The app auto-generates `HUID000001`, `HUID000002`, … when
  left blank.
- `profiles.role` now allows `OWNER | MANAGER | STAFF` (old `CO_OWNER` rows are
  migrated to `MANAGER`).

## 7. Notes for the HF-space backend (if reactivated)

The Flutter app currently talks to Supabase directly. If the custom backend at
`swarnayanjewellers-backend.hf.space` is reactivated, it must go through the
same RPCs (using the user's JWT, not the service key) so RLS keeps applying.
