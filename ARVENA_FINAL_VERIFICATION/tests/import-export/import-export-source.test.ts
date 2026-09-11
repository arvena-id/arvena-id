import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
describe("import/export P0",()=>{it("has DB primitives and application routes",()=>{
 const sql=readFileSync(join(process.cwd(),"supabase/migrations/0009_arvena_p0_import_export_and_command_hardening.sql"),"utf8");
 for(const token of ["commit_import_job","create_export_job","register_export_result"]) expect(sql).toContain(token);
 expect(existsSync(join(process.cwd(),"app/data/import/page.tsx"))).toBe(true);
 expect(existsSync(join(process.cwd(),"app/data/export/page.tsx"))).toBe(true);
});});
