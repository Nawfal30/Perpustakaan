import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const sql = readFileSync(new URL("../supabase/migrations/202610130001_initial_schema.sql", import.meta.url), "utf8");
const required = [
  "create table if not exists public.organizations",
  "create table if not exists public.item_copies",
  "create table if not exists public.loans",
  "create table if not exists public.reservations",
  "create table if not exists public.fines",
  "create table if not exists public.payments",
  "create table if not exists public.payment_allocations",
  "create table if not exists public.audit_logs",
  "create or replace function public.calculate_fine",
  "create or replace function public.checkout_copy",
  "create or replace function public.return_copy",
  "uq_loans_open_per_copy",
  "enable row level security",
  "revoke update, delete, truncate on public.audit_logs",
];
for (const fragment of required) assert.ok(sql.toLowerCase().includes(fragment.toLowerCase()), `Missing SQL fragment: ${fragment}`);
assert.equal((sql.match(/\$\$/g) ?? []).length % 2, 0, "Unbalanced PL/pgSQL dollar quotes");
assert.equal((sql.match(/create table if not exists public\.loans/gi) ?? []).length, 1, "Duplicate loans table declaration");
console.log(`Schema static checks passed (${required.length} required checks).`);
