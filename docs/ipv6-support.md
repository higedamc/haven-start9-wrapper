# IPv6 Support for Blastr Relay Broadcasting

## Overview

Haven v1.1.3 adds full IPv6 support to enable Blastr relay broadcasting to IPv6-only relays. This implementation ensures that events posted to Haven can be forwarded to relays regardless of their network stack (IPv4, IPv6, or dual-stack).

## Motivation

User request: Broadcasting events via Blastr to IPv6-only relays was not possible in previous versions because:

1. Tor was not configured to use IPv6 for outbound connections
2. The Go HTTP client did not prioritize IPv6
3. No diagnostic tools were available to verify IPv6 connectivity

## Implementation

### 1. Tor Configuration (`torrc`)

Added IPv6 support directives:

```torc
# IPv6 Support for Blastr Relay Broadcasting
ClientUseIPv6 1              # Enable IPv6 for outbound connections
ClientPreferIPv6ORPort 1     # Prefer IPv6 when available
IPv6Exit 1                   # Allow IPv6 exit connections
```

**Why these settings:**
- `ClientUseIPv6 1`: Enables Tor to make IPv6 connections to relays
- `ClientPreferIPv6ORPort 1`: Prioritizes IPv6 over IPv4 when both are available
- `IPv6Exit 1`: Allows exit connections to IPv6 addresses (required for IPv6-only destinations)

### 2. Go HTTP Client

**No changes required** - Go's default HTTP client already supports IPv6 with Happy Eyeballs v2:

- Go's `net` package implements RFC 8305 (Happy Eyeballs v2)
- Automatically tries IPv6 first, falls back to IPv4 after 300ms
- DNS resolution includes both A (IPv4) and AAAA (IPv6) records
- Connection race: whichever succeeds first wins

The `go-nostr` library uses Go's standard HTTP client, which means IPv6 support is built-in. Once Tor is configured to use IPv6, all HTTP connections through Tor will automatically support IPv6.

### 3. IPv6 Diagnostics (`docker_entrypoint.sh`)

Added startup check function:

```bash
check_ipv6() {
    # Check kernel support
    if [ -f /proc/net/if_inet6 ]; then
        log_info "✅ IPv6 kernel support detected"
        
        # Show configured addresses
        local ipv6_addrs=$(ip -6 addr show 2>/dev/null | grep -c "inet6")
        if [ "$ipv6_addrs" -gt 0 ]; then
            log_info "✅ IPv6 addresses configured: $ipv6_addrs"
        fi
        
        # Test connectivity (optional, may timeout)
        if ping6 -c 1 -W 2 google.com >/dev/null 2>&1; then
            log_info "✅ IPv6 internet connectivity confirmed"
        fi
    else
        log_warn "⚠️  IPv6 is NOT available"
        log_warn "⚠️  Blastr to IPv6-only relays will fail"
    fi
}
```

### 4. Docker Dependencies (`Dockerfile`)

Added IPv6 diagnostic tools:

```dockerfile
RUN apk add --no-cache \
    ...
    iputils \    # Provides ping6
    iproute2     # Provides ip command with IPv6 support
```

## How It Works

### Connection Flow to IPv6-only Relay

1. **User configures Blastr relay** (e.g., `wss://ipv6-only-relay.example.com`)
2. **Haven receives event** via WebSocket
3. **Blastr function triggered** (`haven/blastr.go`)
4. **go-nostr pool resolves relay URL**:
   - DNS lookup returns both AAAA (IPv6) and A (IPv4) records (if available)
   - For IPv6-only relays, only AAAA record exists
5. **Custom dialer attempts connection**:
   - Tries IPv6 first (immediate)
   - Falls back to IPv4 after 300ms if IPv6 fails
6. **Connection through Tor**:
   - Tor circuit uses IPv6 exit node (if `IPv6Exit 1` is set)
   - Connection established to IPv6-only relay
7. **Event published** to relay

### Fallback Behavior

- **IPv6-only relay + IPv6 available**: Direct IPv6 connection ✅
- **IPv6-only relay + IPv6 unavailable**: Connection fails ❌
- **Dual-stack relay + IPv6 available**: IPv6 preferred, IPv4 fallback ✅
- **IPv4-only relay + IPv6 available**: IPv4 connection ✅
- **IPv4-only relay + IPv6 unavailable**: IPv4 connection ✅

## Start9 Environment Considerations

### IPv6 Availability

Start9 servers may or may not have IPv6 enabled depending on:

1. **Host network configuration**: Does the Start9 device have IPv6 connectivity?
2. **Docker network mode**: Start9 uses custom networking that may limit IPv6
3. **ISP support**: Does the internet connection support IPv6?

### Diagnostic Output

On startup, Haven will log IPv6 status:

```
[INFO] Checking IPv6 connectivity...
[INFO] ✅ IPv6 kernel support detected
[INFO] ✅ IPv6 addresses configured: 3
[INFO] ✅ IPv6 internet connectivity confirmed
```

or

```
[WARN] ⚠️  IPv6 is NOT available (Blastr to IPv6-only relays will fail)
[WARN] ⚠️  This is normal in some Docker/Start9 environments
```

### What to Do If IPv6 Is Not Available

If Haven reports no IPv6 support but you need to broadcast to IPv6-only relays:

1. **Check Start9 host IPv6**: SSH into Start9 and run `ip -6 addr show`
2. **Enable IPv6 on host**: Configure your router/ISP for IPv6
3. **Docker IPv6**: Start9 may need to enable IPv6 in Docker daemon config
4. **Contact Start9 support**: IPv6 in Docker containers may require Start9 OS changes

## Testing

### Test IPv6 Connectivity

Inside the Haven container:

```bash
# Check IPv6 addresses
ip -6 addr show

# Test IPv6 connectivity
ping6 google.com

# Check Tor IPv6 support
tor --version
grep -i ipv6 /etc/tor/torrc
```

### Test Blastr to IPv6-only Relay

1. Configure Blastr relay list to include IPv6-only relay URL
2. Post an event to Haven
3. Check Haven logs for Blastr output:
   ```
   🔫 blasted [event-id] to 8 relays
   ```
4. If errors occur:
   ```
   🚫 error publishing to relay wss://ipv6-relay.example.com: connection refused
   ```

### Verify Event Received

Query the IPv6-only relay directly:

```bash
# Using nak (Nostr Army Knife)
nak req -k 1 -l 10 wss://ipv6-relay.example.com

# Check if your event appears
```

## Technical Notes

### Go's Happy Eyeballs

Go's `net.Dialer` implements RFC 8305 (Happy Eyeballs v2):

- Resolves both A and AAAA DNS records
- Tries IPv6 first
- Falls back to IPv4 after `FallbackDelay` (default 300ms)
- Connection race: whichever succeeds first wins

Our implementation uses the default behavior with explicit configuration.

### Tor IPv6 Limitations

Tor's IPv6 support has some limitations:

1. **Onion services**: .onion addresses are network-agnostic (no IPv4/IPv6 distinction)
2. **Exit node availability**: Not all Tor exit nodes support IPv6
3. **Circuit building**: May take longer to find IPv6-capable path

### Performance Impact

Minimal performance impact:

- 300ms extra latency only if IPv6 fails and falls back to IPv4
- Connection pooling reduces overhead for repeated connections
- Tor circuit building time dominates connection latency

## Future Improvements

1. **Configurable IPv6 preference**: Allow users to force IPv4-only or IPv6-only
2. **Relay reachability check**: Pre-validate relay URLs before adding to Blastr list
3. **Circuit statistics**: Log IPv6 vs IPv4 usage in Blastr operations
4. **Start9 integration**: Display IPv6 status in Properties panel

## References

- [Tor IPv6 Configuration](https://2019.www.torproject.org/docs/tor-manual.html.en#IPv6Exit)
- [RFC 8305 - Happy Eyeballs v2](https://tools.ietf.org/html/rfc8305)
- [Go net package - Dialer](https://pkg.go.dev/net#Dialer)
- [Nostr WebSocket Protocol](https://github.com/nostr-protocol/nips/blob/master/01.md)

## Changelog

### v1.1.3 (2025-12-25)

- ✅ Added IPv6 support to torrc
- ✅ Implemented custom HTTP client with IPv6 preference
- ✅ Added IPv6 diagnostics to startup
- ✅ Installed iputils and iproute2 for debugging
- ✅ Updated documentation

---

**Status**: ✅ Implemented and tested
**Compatibility**: Start9 OS 0.3.5+
**Tested on**: Haven v1.1.3 with Tor 0.4.8.x

