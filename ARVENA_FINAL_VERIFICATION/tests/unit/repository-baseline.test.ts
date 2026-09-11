import { describe, expect, it } from "vitest";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
const root = process.cwd();
describe("ARVENA P0 repository release surface", () => {
  it("has required build and verification configuration", () => {
    for (const file of ["package.json","tsconfig.json","next.config.ts","eslint.config.mjs","vitest.config.ts","playwright.config.ts",".env.example"]) {
      expect(existsSync(join(root,file)), file).toBe(true);
    }
  });
  it("does not silently accept a missing migration sequence", () => {
    const nums = readdirSync(join(root,"supabase/migrations")).filter(x=>/^\d{4}_.*\.sql$/.test(x)).map(x=>Number(x.slice(0,4))).sort((a,b)=>a-b);
    const missing:number[]=[]; for(let n=nums[0]; n<=nums.at(-1)!; n++) if(!nums.includes(n)) missing.push(n);
    expect(missing).toEqual([]);
  });
  it("has actual Next.js route source", () => {
    const app = join(root,"app");
    const stack=[app]; let routes=0;
    while(stack.length){ const p=stack.pop()!; for(const e of readdirSync(p,{withFileTypes:true})){ const full=join(p,e.name); if(e.isDirectory()) stack.push(full); else if(["page.tsx","route.ts"].includes(e.name)) routes++; } }
    expect(routes).toBeGreaterThan(0);
  });
});
