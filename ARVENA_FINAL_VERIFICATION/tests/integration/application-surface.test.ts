import { describe, expect, it } from "vitest";
import { existsSync } from "node:fs";
import { join } from "node:path";
const root=process.cwd();
const required=[
  "app/login/page.tsx","app/signup/page.tsx","app/onboarding/page.tsx","app/dashboard/page.tsx",
  "app/customers/page.tsx","app/leads/page.tsx","app/quotes/page.tsx","app/jobs/page.tsx","app/calendar/page.tsx",
  "app/invoices/page.tsx","app/payments/page.tsx","app/assets/page.tsx","app/recurring/page.tsx","app/data/import/page.tsx","app/data/export/page.tsx"
];
describe("P0 application surface",()=>{it("contains the required primary routes",()=>{for(const p of required) expect(existsSync(join(root,p)),p).toBe(true);});});
