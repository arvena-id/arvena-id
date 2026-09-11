import { test, expect } from "@playwright/test";
const publicRoutes=["/login","/signup"];
for(const route of publicRoutes){ test(`${route} renders without 404`,async({page})=>{ const r=await page.goto(route); expect(r?.status()).toBeLessThan(400); await expect(page.locator("body")).toBeVisible(); }); }
test("desktop shell has no horizontal overflow on login",async({page})=>{await page.setViewportSize({width:1280,height:800});await page.goto('/login');const v=await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth);expect(v).toBe(true);});
