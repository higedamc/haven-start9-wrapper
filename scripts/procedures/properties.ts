/**
 * Haven Service Properties
 * Returns current service information and status
 */

import { T } from "../deps.ts";

export const properties: T.ExpectedExports.properties = async (effects) => {
  // Read Tor address from the actual Tor hidden service directory
  // This is the SOURCE OF TRUTH for the onion address
  let torAddress = "Generating...";
  try {
    // First try to read from Tor's hostname file (primary source)
    torAddress = (await Deno.readTextFile("/data/tor/haven/hostname")).trim();
  } catch (_e) {
    // Fallback to tor_address.txt if hostname doesn't exist yet
    try {
      torAddress = (await Deno.readTextFile("/data/tor_address.txt")).trim();
    } catch (_e2) {
      // File doesn't exist yet, use default
    }
  }

  // Get database size
  let dbSize = "0B";
  try {
    const proc = Deno.run({
      cmd: ["du", "-sh", "/data/db"],
      stdout: "piped",
      stderr: "null",
    });
    const output = new TextDecoder().decode(await proc.output());
    await proc.status();
    proc.close();
    dbSize = output.split("\t")[0] || "0B";
  } catch (_e) {
    // Directory doesn't exist yet
  }

  // Get Blossom storage stats
  let blossomSize = "0B";
  let blossomFiles = "0";
  try {
    const sizeProc = Deno.run({
      cmd: ["du", "-sh", "/data/blossom"],
      stdout: "piped",
      stderr: "null",
    });
    const sizeOutput = new TextDecoder().decode(await sizeProc.output());
    await sizeProc.status();
    sizeProc.close();
    blossomSize = sizeOutput.split("\t")[0] || "0B";

    const countProc = Deno.run({
      cmd: ["sh", "-c", "find /data/blossom -type f 2>/dev/null | wc -l"],
      stdout: "piped",
    });
    const countOutput = new TextDecoder().decode(await countProc.output());
    await countProc.status();
    countProc.close();
    blossomFiles = countOutput.trim() || "0";
  } catch (_e) {
    // Directory doesn't exist yet
  }

  // Get total storage
  let totalStorage = "0B";
  try {
    const proc = Deno.run({
      cmd: ["du", "-sh", "/data"],
      stdout: "piped",
      stderr: "null",
    });
    const output = new TextDecoder().decode(await proc.output());
    await proc.status();
    proc.close();
    totalStorage = output.split("\t")[0] || "0B";
  } catch (_e) {
    // Error getting storage
  }

  const properties: T.ResultType<T.Properties> = {
    result: {
      version: 2,
      data: {
        "Haven Version": {
          type: "string",
          value: "1.1.6",
          description: "Current Haven version",
          copyable: false,
          qr: false,
          masked: false,
        },
        "Service Status": {
          type: "string",
          value: "Running",
          description: "Haven service status",
          copyable: false,
          qr: false,
          masked: false,
        },
        "Tor Hidden Service": {
          type: "string",
          value: torAddress,
          description: "Your .onion address (Hidden Service)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Web Interface": {
          type: "string",
          value: `http://${torAddress}/`,
          description: "Haven Web Interface (Dashboard)",
          copyable: true,
          qr: false,
          masked: false,
        },
        "Outbox Relay": {
          type: "string",
          value: `ws://${torAddress}`,
          description: "Public relay URL (anyone can read, only you can write)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Private Relay": {
          type: "string",
          value: `ws://${torAddress}/private`,
          description: "Private relay URL (authentication required)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Chat Relay": {
          type: "string",
          value: `ws://${torAddress}/chat`,
          description: "Chat relay URL (Web of Trust protected)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Inbox Relay": {
          type: "string",
          value: `ws://${torAddress}/inbox`,
          description: "Inbox relay URL (Web of Trust protected)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Blossom Media Server": {
          type: "string",
          value: `http://${torAddress}`,
          description: "Blossom media server URL (NIP-96 & BUD-02 compliant)",
          copyable: true,
          qr: true,
          masked: false,
        },
        "Database Size": {
          type: "string",
          value: dbSize,
          description: "Total database storage used",
          copyable: false,
          qr: false,
          masked: false,
        },
        "Media Storage": {
          type: "string",
          value: `${blossomFiles} files (${blossomSize})`,
          description: "Number of media files and total size",
          copyable: false,
          qr: false,
          masked: false,
        },
        "Total Storage": {
          type: "string",
          value: totalStorage,
          description: "Total Haven data storage",
          copyable: false,
          qr: false,
          masked: false,
        },
      },
    },
  };

  return properties;
};
