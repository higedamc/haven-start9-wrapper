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
      // Check if Haven HTTP server is responding using curl
      const process = Deno.run({
        cmd: ["curl", "-sf", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "5", "http://localhost:3355/"],
        stdout: "piped",
        stderr: "piped",
      });
      
      const status = await process.status();
      const output = new TextDecoder().decode(await process.output());
      process.close();
      
      // curl exits with 0 on success, non-zero on failure
      if (status.success) {
        const httpCode = parseInt(output);
        // Accept 200 OK and 3xx redirects as success
        if (httpCode >= 200 && httpCode < 400) {
          return null;
        } else {
          if (isStarting) {
            return null;
          } else {
            return `Haven returned HTTP ${httpCode}`;
          }
        }
      } else {
        // curl failed (connection error, timeout, etc.)
        if (isStarting) {
          // During startup, this is expected
          return null;
        } else {
          // After startup period, connection failures are errors
          return "Haven is not responding";
        }
      }
    } catch (error) {
      // Unexpected error running curl
      if (isStarting) {
        return null;
      } else {
        const errorMsg = error instanceof Error ? error.message : String(error);
        return `Health check error: ${errorMsg}`;
      }
    }
  },
};
