#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import re, sys
ROOT = Path(__file__).resolve().parents[1]
MIG = ROOT / 'supabase' / 'migrations'
files = sorted(MIG.glob('*.sql'))
errors: list[str] = []
warnings: list[str] = []

nums=[]
for p in files:
    m=re.match(r'^(\d{4})_',p.name)
    if m: nums.append(int(m.group(1)))
if nums:
    for n in range(min(nums), max(nums)+1):
        if n not in nums:
            errors.append(f'Missing migration number {n:04d} in sequence {min(nums):04d}-{max(nums):04d}')

# Parse CREATE FUNCTION signatures well enough for ARVENA migrations.
def split_args(raw: str):
    out=[]; cur=[]; depth=0
    for ch in raw:
        if ch=='(': depth+=1
        elif ch==')': depth-=1
        if ch==',' and depth==0:
            out.append(''.join(cur).strip()); cur=[]
        else: cur.append(ch)
    if ''.join(cur).strip(): out.append(''.join(cur).strip())
    return out

def norm_type(t: str):
    t=' '.join(t.strip().lower().split())
    t=t.replace('timestamp with time zone','timestamptz')
    t=t.replace('timestamp without time zone','timestamp')
    t=t.replace('integer','int')
    t=t.replace('character varying','varchar')
    return t

def decl_types(raw: str):
    types=[]
    for part in split_args(raw):
        part=re.split(r'\s+default\s+|\s*=\s*', part, maxsplit=1, flags=re.I)[0].strip()
        toks=part.split()
        if not toks: continue
        if toks[0].lower() in {'in','out','inout','variadic'}: toks=toks[1:]
        if len(toks)>=2: typ=' '.join(toks[1:])
        else: typ=toks[0]
        types.append(norm_type(typ))
    return tuple(types)

known: dict[tuple[str,tuple[str,...]], str] = {}
for p in files:
    text=p.read_text(encoding='utf-8')
    # Before mutations on this migration, collect / check in textual order.
    events=[]
    for m in re.finditer(r'(?is)create\s+(?:or\s+replace\s+)?function\s+app\.([a-zA-Z0-9_]+)\s*\((.*?)\)\s*returns\s+', text):
        events.append((m.start(),'create',m))
    for m in re.finditer(r'(?im)^alter\s+function\s+app\.([a-zA-Z0-9_]+)\(([^)]*)\)\s+rename\s+to\s+([a-zA-Z0-9_]+)', text):
        events.append((m.start(),'rename',m))
    for m in re.finditer(r'(?im)^(?:grant\s+execute\s+on\s+function|revoke\s+all\s+on\s+function)\s+app\.([a-zA-Z0-9_]+)\(([^)]*)\)', text):
        events.append((m.start(),'acl',m))
    for _,kind,m in sorted(events,key=lambda x:x[0]):
        if kind=='create':
            name=m.group(1); sig=decl_types(m.group(2)); known[(name,sig)] = p.name
        elif kind=='rename':
            name=m.group(1); sig=tuple(norm_type(x) for x in m.group(2).split(',') if x.strip()); new=m.group(3)
            key=(name,sig)
            if key not in known:
                variants=[f'{n}{s} from {src}' for (n,s),src in known.items() if n==name]
                errors.append(f'{p.name}: ALTER FUNCTION app.{name}{sig} has no prior matching function. Variants: {variants or "none"}')
            else:
                src=known.pop(key); known[(new,sig)] = p.name + f' (renamed from {src})'
        else:
            name=m.group(1); sig=tuple(norm_type(x) for x in m.group(2).split(',') if x.strip())
            if (name,sig) not in known:
                warnings.append(f'{p.name}: ACL targets app.{name}{sig} not known at this point')

    # SECURITY DEFINER must set search_path in function header.
    for m in re.finditer(r'(?is)create\s+(?:or\s+replace\s+)?function\s+([\w.]+)\s*\((.*?)\)\s*returns\s+.*?\bas\s+\$\$', text):
        header=text[m.start():m.end()]
        if re.search(r'\bsecurity\s+definer\b', header, re.I) and not re.search(r'\bset\s+search_path\s*=', header, re.I):
            errors.append(f'{p.name}: SECURITY DEFINER function {m.group(1)} lacks controlled search_path')

# Known 0011 type hazard: UUID results used as one CASE branch against JSONB.
p11=MIG/'0011_arvena_p0_command_contract_completion.sql'
if p11.exists():
    s=p11.read_text(encoding='utf-8')
    for fn in ['schedule_visit','invite_member','update_tax_profile','create_note','create_media']:
        # Wrapper result variable is UUID and generic CASE cannot type-resolve UUID vs JSONB.
        block=re.search(rf'(?is)create\s+or\s+replace\s+function\s+app\.{fn}\b.*?\$\$(.*?)\$\$;',s)
        if block and "pg_typeof(result)::text='jsonb'" in block.group(1):
            errors.append(f'{p11.name}: {fn} UUID-returning wrapper uses CASE result(jsonb/uuid) pattern that is not type-safe; wrap UUID explicitly with jsonb_build_object')

# Basic table/rls coverage signal.
created_tables=[]
for p in files:
    t=p.read_text(encoding='utf-8')
    created_tables += re.findall(r'(?im)^create\s+table\s+if\s+not\s+exists\s+public\.([a-zA-Z0-9_]+)',t)
rls_text='\n'.join(p.read_text(encoding='utf-8') for p in files)
for tbl in created_tables:
    if not re.search(rf'(?i)alter\s+table\s+(?:public\.)?{re.escape(tbl)}\s+enable\s+row\s+level\s+security',rls_text):
        # some global configuration tables intentionally not tenant RLS; classify.
        if tbl not in {'currency_definitions','plan_versions','plan_entitlements','industry_templates','industry_template_versions','system_role_templates'}:
            warnings.append(f'Table {tbl} has no explicit ENABLE ROW LEVEL SECURITY statement detected')

print('ARVENA static SQL audit')
print(f'Migrations: {len(files)}')
print(f'Errors: {len(errors)}')
for e in errors: print('ERROR:',e)
print(f'Warnings: {len(warnings)}')
for w in warnings[:100]: print('WARN:',w)
if len(warnings)>100: print(f'WARN: ... {len(warnings)-100} more')
sys.exit(1 if errors else 0)
