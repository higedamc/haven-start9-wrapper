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
  
  // Use compat helper to return the correct SetResult type
  return compat.setConfig(effects, newConfig);
};
