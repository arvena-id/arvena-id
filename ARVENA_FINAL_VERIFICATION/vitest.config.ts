import { defineConfig } from "vitest/config";
export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/unit/**/*.test.ts", "tests/integration/**/*.test.ts", "tests/offline/**/*.test.ts", "tests/recurring/**/*.test.ts", "tests/finance/**/*.test.ts", "tests/import-export/**/*.test.ts"],
    passWithNoTests: false,
  },
});
