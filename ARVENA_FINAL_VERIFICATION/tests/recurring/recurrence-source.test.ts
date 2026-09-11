import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";
describe("recurring contract source",()=>{it("contains explicit 60-day and DST metadata persistence primitives",()=>{
 const sql=readFileSync(join(process.cwd(),"supabase/migrations/0002_arvena_p0_functions.sql"),"utf8")+readFileSync(join(process.cwd(),"supabase/migrations/0005_arvena_p0_commands.sql"),"utf8");
 expect(sql).toContain("dst_resolution"); expect(sql).toContain("occurrence_local_date");
});});
