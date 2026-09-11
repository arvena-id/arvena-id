#!/usr/bin/env bash
set -euo pipefail
: "${ARVENA_TEST_DATABASE_URL:?Set ARVENA_TEST_DATABASE_URL}"
command -v psql >/dev/null 2>&1 || { echo 'ENVIRONMENT BLOCKER: psql is not installed' >&2; exit 78; }
PSQL=(psql "$ARVENA_TEST_DATABASE_URL" -X -q -v ON_ERROR_STOP=1)
fail(){ echo "CONCURRENCY FAIL: $*" >&2; exit 1; }
run_pair(){
  local name="$1" sql1="$2" sql2="$3" out1 out2 rc1 rc2
  out1=$(mktemp); out2=$(mktemp)
  set +e
  ("${PSQL[@]}" -c "$sql1" >"$out1" 2>&1) & p1=$!
  ("${PSQL[@]}" -c "$sql2" >"$out2" 2>&1) & p2=$!
  wait "$p1"; rc1=$?; wait "$p2"; rc2=$?
  set -e
  echo "[$name] rc1=$rc1 rc2=$rc2"
  cat "$out1" "$out2"
  rm -f "$out1" "$out2"
  PAIR_RC1=$rc1; PAIR_RC2=$rc2
}

ORG_A=aaaaaaaa-0000-0000-0000-000000000001
OWNER1=10000000-0000-0000-0000-000000000001
OWNER2=30000000-0000-0000-0000-000000000001
MEMBER1=a1000001-0000-0000-0000-000000000001
MEMBER2=a1000012-0000-0000-0000-000000000001
OWNER_ROLE=a0000001-0000-0000-0000-000000000001
ADMIN_ROLE=a0000002-0000-0000-0000-000000000001

# Final Owner race: provision a second active Owner as deterministic precondition, then concurrently demote both.
"${PSQL[@]}" -c "update organization_members set role_id='$OWNER_ROLE' where id='$MEMBER2';" >/dev/null
run_pair final-owner \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.update_member('$ORG_A','$MEMBER1','$ADMIN_ROLE','ACTIVE','con-owner-1');" \
"select set_config('request.jwt.claim.sub','$OWNER2',false); select app.update_member('$ORG_A','$MEMBER2','$ADMIN_ROLE','ACTIVE','con-owner-2');"
owners=$("${PSQL[@]}" -Atc "select count(*) from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id where m.organization_id='$ORG_A' and m.status='ACTIVE' and r.system_key='OWNER';")
[[ "$owners" -ge 1 ]] || fail "final Owner invariant broken"

# Restore owner1 for remaining commands.
"${PSQL[@]}" -c "update organization_members set role_id='$OWNER_ROLE',status='ACTIVE' where id='$MEMBER1'; update organization_members set role_id='$ADMIN_ROLE',status='ACTIVE' where id='$MEMBER2';" >/dev/null

# Simultaneous final settlement: only one request may settle outstanding 60000.
INV=ab000001-0000-0000-0000-000000000001
run_pair final-payment \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.record_payment('$ORG_A','$INV',60000,'IDR','BANK_TRANSFER','race-a',now(),null,1,'con-pay-1');" \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.record_payment('$ORG_A','$INV',60000,'IDR','BANK_TRANSFER','race-b',now(),null,1,'con-pay-2');"
paid=$("${PSQL[@]}" -Atc "select paid_minor from invoices where id='$INV';")
[[ "$paid" -le 100000 ]] || fail "overpayment occurred: paid_minor=$paid"

# Concurrent Visit reschedule from same expected version: at most one logical update.
VIS=a6000001-0000-0000-0000-000000000001
JOB=a5000001-0000-0000-0000-000000000001
run_pair visit-reschedule \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.schedule_visit('$ORG_A','$JOB','$VIS','2026-09-12T02:00:00Z','2026-09-12T03:00:00Z','Asia/Jakarta','{}'::jsonb,array['a1000006-0000-0000-0000-000000000001']::uuid[],false,null,1,'con-visit-1');" \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.schedule_visit('$ORG_A','$JOB','$VIS','2026-09-13T02:00:00Z','2026-09-13T03:00:00Z','Asia/Jakarta','{}'::jsonb,array['a1000006-0000-0000-0000-000000000001']::uuid[],false,null,1,'con-visit-2');"
[[ $PAIR_RC1 -ne 0 || $PAIR_RC2 -ne 0 ]] || fail "both stale-version reschedules succeeded"

# Quote conversion: exactly one Job may reference a Quote.
Q=a4000001-0000-0000-0000-000000000001
"${PSQL[@]}" -c "update quotes set status='ACCEPTED',accepted_at=now() where id='$Q';" >/dev/null
run_pair quote-conversion \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.convert_quote_to_job('$ORG_A','$Q','con-q-1');" \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.convert_quote_to_job('$ORG_A','$Q','con-q-2');"
qjobs=$("${PSQL[@]}" -Atc "select count(*) from jobs where organization_id='$ORG_A' and quote_id='$Q';")
[[ "$qjobs" -le 1 ]] || fail "quote converted to multiple Jobs"

# Recurring generator: unique occurrence + one generated Job under concurrent attempts.
RULE=ad000001-0000-0000-0000-000000000001
run_pair recurring-generator \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.generate_recurring_occurrence('$ORG_A','$RULE','2026-10-15','09:00','2026-10-15T02:00:00Z',420,'EXACT',1,'{}'::jsonb,'con-rec-1');" \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.generate_recurring_occurrence('$ORG_A','$RULE','2026-10-15','09:00','2026-10-15T02:00:00Z',420,'EXACT',1,'{}'::jsonb,'con-rec-2');"
occ=$("${PSQL[@]}" -Atc "select count(*) from recurring_occurrences where organization_id='$ORG_A' and recurring_rule_id='$RULE' and resolved_occurrence_at='2026-10-15T02:00:00Z';")
[[ "$occ" -le 1 ]] || fail "duplicate recurring occurrence"

# Import commit replay/race must not commit a staged row twice.
IMP=a1300001-0000-0000-0000-000000000001
run_pair import-commit \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.commit_import_job('$ORG_A','$IMP','con-imp');" \
"select set_config('request.jwt.claim.sub','$OWNER1',false); select app.commit_import_job('$ORG_A','$IMP','con-imp');"
dup=$("${PSQL[@]}" -Atc "select count(*) from import_rows where organization_id='$ORG_A' and import_job_id='$IMP' and commit_state='COMMITTED';")
[[ "$dup" -le 3 ]] || fail "import committed more rows than staged"

echo 'Concurrency acceptance completed.'
