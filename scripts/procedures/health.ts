/**
 * Haven Health Check
 * Checks if the Haven service is running properly
 */

import { T } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  async main(effects, duration) {
    // During startup (first 60 seconds), be more lenient
    const isStarting = duration < 60_000;
    
    try {
      // Check if Haven HTTP server is responding
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch("http://localhost:3355/", {
        method: "GET",
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);

      // Accept 200 OK and 3xx redirects as success
      if (response.ok || (response.status >= 300 && response.status < 400)) {
        // Success - return null
        return null;
      } else {
        // Non-OK responses
        if (isStarting) {
          // During startup, don't report errors yet
          return null;
        } else {
          // After startup, report HTTP errors
          return `Haven returned HTTP ${response.status}`;
        }
      }
    } catch (error) {
      // Connection errors (Haven not yet listening, timeout, etc.)
      if (isStarting) {
        // During startup, this is expected
        return null;
      } else {
        // After startup period, connection failures are errors
        const errorMsg = error instanceof Error ? error.message : String(error);
        return `Haven is not responding: ${errorMsg}`;
      }
    }
  },
};
