import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("recurring contract source",()=>{
  it("contains explicit 60-day and DST metadata persistence primitives",()=>{
    const sql=readFileSync(join(process.cwd(),"supabase/migrations/0001_arvena_canonical_baseline.sql"),"utf8");
    expect(sql).toContain("dst_resolution");
    expect(sql).toContain("occurrence_local_date");
    expect(sql).toMatch(/interval '60 days'/i);
  });
});
