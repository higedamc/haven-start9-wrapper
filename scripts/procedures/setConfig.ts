/**
 * Haven Configuration Setter
 * Uses Start9 SDK compat helper to properly handle config updates
 */

import { compat, T } from "../deps.ts";

export const setConfig: T.ExpectedExports.setConfig = async (
  effects: T.Effects,
  newConfig: T.Config,
) => {
  // Validate owner-npub if provided
  if (newConfig['owner-npub']) {
    const npub = newConfig['owner-npub'];
    const npubPattern = /^npub1[a-z0-9]{58}$/;
    
    if (!npubPattern.test(npub)) {
      throw new Error('Invalid npub format. Must start with "npub1" and be 63 characters long (e.g., npub1abc...xyz)');
    }
  }
  
  // Validate blastr-relays if provided
  if (newConfig['blastr-relays']) {
    const blastrRelays = newConfig['blastr-relays'];
    
    // Skip validation if empty/null
    if (blastrRelays && blastrRelays.trim().length > 0) {
      // Split by comma and validate each relay URL
      const relays = blastrRelays.split(',').map(r => r.trim()).filter(r => r.length > 0);
      
      for (const relay of relays) {
        // Check if it's a valid relay URL format
        // Can be domain only (e.g., "relay.damus.io") or full URL (e.g., "wss://relay.damus.io")
        const hasProtocol = relay.startsWith('wss://') || relay.startsWith('ws://');
        const domainPart = hasProtocol ? relay.split('://')[1] : relay;
        
        // Basic domain validation (contains at least one dot and valid characters)
        const domainPattern = /^[a-zA-Z0-9][a-zA-Z0-9-_.]*\.[a-zA-Z]{2,}$/;
        
        if (!domainPattern.test(domainPart)) {
          throw new Error(`Invalid relay URL: "${relay}". Each relay must be a valid domain (e.g., "relay.damus.io") or full WebSocket URL (e.g., "wss://relay.damus.io")`);
        }
      }
    }
  }
  
  // Use compat helper to return the correct SetResult type
  return compat.setConfig(effects, newConfig);
};
