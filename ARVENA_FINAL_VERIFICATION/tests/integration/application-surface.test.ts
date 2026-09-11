import { describe, expect, it } from "vitest";
import { existsSync } from "node:fs";
import { join } from "node:path";

const root=process.cwd();
const required=[
  "app/login/page.tsx","app/signup/page.tsx","app/onboarding/page.tsx",
  "app/(protected)/dashboard/page.tsx","app/(protected)/customers/page.tsx","app/(protected)/leads/page.tsx",
  "app/(protected)/quotes/page.tsx","app/(protected)/jobs/page.tsx","app/(protected)/calendar/page.tsx",
  "app/(protected)/invoices/page.tsx","app/(protected)/payments/page.tsx","app/(protected)/assets/page.tsx",
  "app/(protected)/recurring/page.tsx","app/(protected)/data/import/page.tsx","app/(protected)/data/export/page.tsx"
];

describe("P0 application surface",()=>{
  it("contains the required primary routes",()=>{
    for(const p of required) expect(existsSync(join(root,p)),p).toBe(true);
  });
});
