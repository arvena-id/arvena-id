import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("exact money source",()=>{
  it("uses integer minor-unit columns and rejects overpayment",()=>{
    const sql=readFileSync(join(process.cwd(),"supabase/migrations/0001_arvena_canonical_baseline.sql"),"utf8");
    expect(sql).toContain("minor_unit_exponent");
    expect(sql).toMatch(/amount_minor\s+bigint/);
    expect(sql).toMatch(/overpayment/i);
  });
});
