import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
describe("Worker offline implementation",()=>{
  it("contains durable client-side queue implementation, not DB receipts alone",()=>{
    const candidates=["lib/offline.ts","lib/offline-client.ts","lib/offline/queue.ts"];
    const found=candidates.find(p=>existsSync(join(process.cwd(),p)));
    expect(found,"offline queue source").toBeTruthy();
    if(found){const s=readFileSync(join(process.cwd(),found),"utf8"); for(const token of ["client_action_id","sequence","RETRYABLE","CONFLICT","REJECTED"]) expect(s).toContain(token);}
  });
});
