/**
 * Haven Health Check
 * Checks if the Haven service is running properly
 */

import { T } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  async main(effects, duration) {
    // Simple health check - always return OK for now
    // In the future, could check if Haven is actually responsive
    return {
      result: "OK",
    } as T.ResultType<T.Health>;
  },
};
