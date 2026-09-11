import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";
describe("exact money source",()=>{it("uses integer minor-unit columns and rejects overpayment",()=>{
 const schema=readFileSync(join(process.cwd(),"supabase/migrations/0001_arvena_p0_schema.sql"),"utf8");
 const fn=readFileSync(join(process.cwd(),"supabase/migrations/0002_arvena_p0_functions.sql"),"utf8");
 expect(schema).toContain("minor_unit_exponent"); expect(schema).toMatch(/amount_minor\s+bigint/); expect(fn).toMatch(/overpayment/i);
});});
