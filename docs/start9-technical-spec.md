# Haven Start9 Technical Specification

## 📐 Technical Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Start9 Server OS                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Tor Network Layer                        │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Hidden Service (.onion)                       │  │  │
│  │  │  Port 80 → Container Port 3355                 │  │  │
│  │  └─────────────────┬──────────────────────────────┘  │  │
│  └────────────────────┼─────────────────────────────────┘  │
│                       │                                     │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │           Haven Docker Container                     │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Haven Application (Go)                      │   │  │
│  │  │  ┌────────────┐  ┌────────────┐             │   │  │
│  │  │  │  Private   │  │  Chat      │             │   │  │
│  │  │  │  Relay     │  │  Relay     │             │   │  │
│  │  │  │  (Auth)    │  │  (WoT)     │             │   │  │
│  │  │  └────────────┘  └────────────┘             │   │  │
│  │  │  ┌────────────┐  ┌────────────┐             │   │  │
│  │  │  │  Inbox     │  │  Outbox    │             │   │  │
│  │  │  │  Relay     │  │  Relay     │             │   │  │
│  │  │  │  (WoT)     │  │  (Public)  │             │   │  │
│  │  │  └────────────┘  └────────────┘             │   │  │
│  │  │  ┌──────────────────────────────────────┐   │   │  │
│  │  │  │  Blossom Media Server                │   │   │  │
│  │  │  │  (NIP-96 & BUD-02 compliant)         │   │   │  │
│  │  │  └──────────────────────────────────────┘   │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Database Layer                              │   │  │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐         │   │  │
│  │  │  │Private │  │ Chat   │  │ Inbox  │         │   │  │
│  │  │  │  DB    │  │  DB    │  │  DB    │         │   │  │
│  │  │  └────────┘  └────────┘  └────────┘         │   │  │
│  │  │  ┌────────┐  ┌────────┐                     │   │  │
│  │  │  │Outbox  │  │Blossom │                     │   │  │
│  │  │  │  DB    │  │  DB    │                     │   │  │
│  │  │  └────────┘  └────────┘                     │   │  │
│  │  │  (BadgerDB or LMDB)                          │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Persistent Storage (/data)                  │   │  │
│  │  │  ├── db/                                     │   │  │
│  │  │  │   ├── private/                            │   │  │
│  │  │  │   ├── chat/                               │   │  │
│  │  │  │   ├── inbox/                              │   │  │
│  │  │  │   ├── outbox/                             │   │  │
│  │  │  │   └── blossom/                            │   │  │
│  │  │  ├── blossom/ (media files)                  │   │  │
│  │  │  └── backups/ (optional)                     │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Architecture

### Tor-Only Communication

#### Network Isolation

```
┌─────────────────────────────────────────────┐
│  External Clients (Nostr Clients)          │
│  - Amethyst, Damus, Primal, etc.           │
└──────────────┬──────────────────────────────┘
               │
               │ Tor Network Only
               │ No Clearnet
               ▼
┌─────────────────────────────────────────────┐
│  Tor Hidden Service                         │
│  - .onion address                           │
│  - End-to-end encrypted                     │
└──────────────┬──────────────────────────────┘
               │
               │ localhost:3355
               ▼
┌─────────────────────────────────────────────┐
│  Haven Application                          │
│  - No clearnet bindings                     │
│  - No DNS leaks                             │
└─────────────────────────────────────────────┘
```

### Authentication Layers

| Relay | Auth Method | Access Control |
|-------|-------------|----------------|
| Private | NIP-42 Auth | Owner only (npub verification) |
| Chat | NIP-42 Auth | Web of Trust (WoT) |
| Inbox | None (write) | Web of Trust (write validation) |
| Outbox | None (read) | Owner only (write) |
| Blossom | NIP-98 Auth | Owner only (upload) |

### Web of Trust Implementation

```go
// wot.go - WoT Graph Structure
type WoTGraph struct {
    owner    string              // Owner pubkey
    depth    int                 // Follow depth (1-3)
    trusted  map[string]bool     // Trusted pubkeys
    mutex    sync.RWMutex        // Thread-safe access
}

// Algorithm
func (w *WoTGraph) BuildTrustNetwork() {
    // 1. Fetch owner's follow list (kind 3)
    follows := fetchFollowList(w.owner)
    
    // 2. Add direct follows
    for _, pubkey := range follows {
        w.trusted[pubkey] = true
    }
    
    // 3. Recursively fetch up to depth
    if w.depth > 1 {
        for pubkey := range w.trusted {
            secondOrder := fetchFollowList(pubkey)
            for _, pk := range secondOrder {
                w.trusted[pk] = true
            }
        }
    }
    
    // 4. Apply minimum followers filter
    for pubkey := range w.trusted {
        if !meetsMinimumFollowers(pubkey) {
            delete(w.trusted, pubkey)
        }
    }
}
```

---

## 📡 Nostr Relay Implementation

### Relay Endpoints

| Endpoint | Protocol | Purpose | Auth Required |
|----------|----------|---------|---------------|
| `/` | WebSocket | Outbox Relay | No (read), Yes (write) |
| `/private` | WebSocket | Private Relay | Yes (read & write) |
| `/chat` | WebSocket | Chat Relay | Yes (read & write) |
| `/inbox` | WebSocket | Inbox Relay | No (write), WoT validated |

### NIP Compliance

| NIP | Title | Support |
|-----|-------|---------|
| NIP-01 | Basic Protocol | ✅ Full |
| NIP-02 | Follow List | ✅ Full |
| NIP-04 | Encrypted DM (deprecated) | ⚠️ Gift Wrap only |
| NIP-09 | Event Deletion | ✅ Full |
| NIP-11 | Relay Info | ✅ Full |
| NIP-20 | Command Results | ✅ Full |
| NIP-42 | Authentication | ✅ Full |
| NIP-59 | Gift Wrap | ✅ Full |
| NIP-96 | HTTP File Storage | ✅ Full (Blossom) |

### Event Flow Example

#### Publishing to Outbox (with Blastr)

```
┌───────────┐
│  Client   │
└─────┬─────┘
      │ 1. Send EVENT
      ▼
┌─────────────────┐
│ Outbox Relay    │
│ ┌─────────────┐ │
│ │ Verify Auth │ │ 2. Check signature
│ │ (owner?)    │ │
│ └─────────────┘ │
└─────┬───────────┘
      │ 3. Store in DB
      ▼
┌─────────────────┐
│  Database       │
│  (outbox/)      │
└─────────────────┘
      │
      │ 4. Broadcast
      ▼
┌─────────────────┐
│  Blastr         │ 5. Send to multiple
│  (async)        │    relay networks
└─────────────────┘
```

#### Receiving to Inbox (with WoT)

```
┌───────────┐
│  Client   │
└─────┬─────┘
      │ 1. Send EVENT (with p-tag)
      ▼
┌─────────────────┐
│  Inbox Relay    │
│ ┌─────────────┐ │
│ │ Check WoT   │ │ 2. Verify sender in WoT
│ │ & p-tag     │ │    and owner is tagged
│ └─────────────┘ │
└─────┬───────────┘
      │ 3. Accept or Reject
      ▼
┌─────────────────┐
│  Database       │
│  (inbox/)       │
└─────────────────┘
```

---

## 🌸 Blossom Server Implementation

### BUD-02 Compliance

#### Endpoints

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/upload` | POST | Upload file | NIP-98 |
| `/<sha256>` | GET | Get file | None |
| `/list/<pubkey>` | GET | List files | Optional |
| `/<sha256>` | DELETE | Delete file | NIP-98 |

### Upload Flow

```
┌──────────────┐
│   Client     │
│  (Amethyst)  │
└──────┬───────┘
       │ 1. Calculate SHA256
       │ 2. Sign auth event (NIP-98)
       ▼
┌─────────────────────────┐
│  POST /upload           │
│  Authorization: Nostr   │
│  Content-Type: image/*  │
└──────────┬──────────────┘
           │ 3. Verify signature
           ▼
┌─────────────────────────┐
│  Haven Blossom Server   │
│  ┌───────────────────┐  │
│  │ Validate:         │  │
│  │ - Auth (owner?)   │  │
│  │ - File size       │  │
│  │ - MIME type       │  │
│  │ - SHA256 match    │  │
│  └───────────────────┘  │
└──────────┬──────────────┘
           │ 4. Store file
           ▼
┌─────────────────────────┐
│  Filesystem             │
│  /data/blossom/<sha256> │
└──────────┬──────────────┘
           │
           │ 5. Store metadata
           ▼
┌─────────────────────────┐
│  Database               │
│  (blossom/)             │
│  - sha256               │
│  - size                 │
│  - type                 │
│  - uploaded             │
└──────────┬──────────────┘
           │ 6. Return URL
           ▼
┌─────────────────────────┐
│  Response               │
│  {                      │
│    "url": "http://...   │
│           .onion/<sha>" │
│  }                      │
└─────────────────────────┘
```

### File Storage Structure

```
/data/blossom/
├── abc123...  (image/jpeg, uploaded 2025-01-15)
├── def456...  (video/mp4, uploaded 2025-01-16)
└── ghi789...  (image/png, uploaded 2025-01-17)

Metadata in database:
{
  "sha256": "abc123...",
  "type": "image/jpeg",
  "size": 1048576,
  "uploaded": 1705334400,
  "pubkey": "owner-pubkey"
}
```

### Content-Type Detection

```go
import "github.com/liamg/magic"

func detectContentType(data []byte) string {
    // Use magic number detection
    detected := magic.Detect(data)
    
    // Whitelist check
    allowed := map[string]bool{
        "image/jpeg": true,
        "image/png": true,
        "image/gif": true,
        "image/webp": true,
        "video/mp4": true,
        "video/webm": true,
    }
    
    if allowed[detected] {
        return detected
    }
    
    return "application/octet-stream"
}
```

---

## 🐳 Docker Implementation

### Multi-Stage Build Optimization

```dockerfile
# Stage 1: Builder
FROM golang:1.24-alpine AS builder
WORKDIR /build
# Optimize layer caching
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Build with optimizations
RUN CGO_ENABLED=1 \
    GOOS=linux \
    go build -ldflags="-s -w" \
    -o haven .

# Stage 2: Runtime (minimal)
FROM alpine:latest
# Install only runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tor \
    tini
# Security: non-root user
RUN adduser -D -u 1000 haven
USER haven
```

**Image Size Targets**:
- Builder stage: ~1.5GB (temporary)
- Final image: <300MB (compressed)
- Runtime memory: 100-500MB (depending on database size)

### Environment Variables

| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `OWNER_NPUB` | string | - | ✅ | Owner's Nostr public key |
| `TOR_ADDRESS` | string | auto | ✅ | .onion address |
| `DB_ENGINE` | enum | badger | ❌ | Database engine (badger/lmdb) |
| `LMDB_MAPSIZE` | int64 | 0 | ❌ | LMDB map size (bytes) |
| `CHAT_RELAY_WOT_DEPTH` | int | 2 | ❌ | WoT follow depth |
| `BACKUP_PROVIDER` | enum | none | ❌ | Backup provider (none/s3) |
| `LOG_LEVEL` | enum | INFO | ❌ | Log level (DEBUG/INFO/WARN/ERROR) |

### Volume Mounts

```yaml
volumes:
  main:
    type: data
    path: /data
    subpaths:
      db: /data/db
      blossom: /data/blossom
      backups: /data/backups
```

---

## ⚙️ Configuration Management

### Start9 Config Schema

```yaml
# Simplified config.yaml structure
owner-npub:
  type: string
  name: Nostr Public Key
  description: Your npub1... public key
  nullable: false
  pattern: "^npub1[a-z0-9]{58}$"
  copyable: true

database:
  type: object
  name: Database Settings
  spec:
    engine:
      type: enum
      name: Database Engine
      values: [badger, lmdb]
      default: badger
    
    lmdb-mapsize:
      type: number
      name: LMDB Map Size (GB)
      nullable: true
      range: [1, 1000]
      default: 273
      depends-on:
        engine: lmdb

relays:
  type: object
  name: Relay Configuration
  spec:
    private:
      type: object
      spec:
        name:
          type: string
          default: "Haven Private"
        description:
          type: string
          default: "My private relay"
    
    chat:
      type: object
      spec:
        name:
          type: string
          default: "Haven Chat"
        wot-depth:
          type: number
          range: [1, 3]
          default: 2
        wot-refresh-hours:
          type: number
          range: [1, 168]
          default: 24

blossom:
  type: object
  name: Media Server Settings
  spec:
    enabled:
      type: boolean
      default: true
    max-file-size:
      type: number
      name: Max File Size (MB)
      range: [1, 1000]
      default: 100
    allowed-types:
      type: list
      name: Allowed MIME Types
      subtype: string
      default:
        - image/jpeg
        - image/png
        - image/gif
        - image/webp
        - video/mp4
        - video/webm

backup:
  type: object
  name: Backup Settings
  spec:
    enabled:
      type: boolean
      default: false
    provider:
      type: enum
      values: [none, s3]
      default: none
      depends-on:
        enabled: true
    interval-hours:
      type: number
      range: [1, 168]
      default: 24
    s3:
      type: object
      nullable: true
      depends-on:
        provider: s3
      spec:
        endpoint:
          type: string
        region:
          type: string
        bucket:
          type: string
        access-key:
          type: string
          masked: true
        secret-key:
          type: string
          masked: true
```

### Dynamic Properties Display

```yaml
# properties.yaml
version: 2
data:
  Status:
    type: string
    value: "Running"
    description: Service health status
    qr: false
  
  Tor Address:
    type: string
    value: "<generated>.onion"
    description: Your Tor hidden service address
    copyable: true
    qr: true
  
  Relay URLs:
    type: object
    value:
      Outbox:
        type: string
        value: "ws://<generated>.onion"
        copyable: true
      Private:
        type: string
        value: "ws://<generated>.onion/private"
        copyable: true
      Chat:
        type: string
        value: "ws://<generated>.onion/chat"
        copyable: true
      Inbox:
        type: string
        value: "ws://<generated>.onion/inbox"
        copyable: true
  
  Blossom Server:
    type: string
    value: "http://<generated>.onion"
    description: Media server URL for NIP-96 clients
    copyable: true
    qr: true
  
  Storage:
    type: object
    value:
      Database:
        type: string
        value: "1.2 GB"
        description: Total database size
      Media Files:
        type: string
        value: "147 files (3.5 GB)"
        description: Blossom media storage
  
  Web of Trust:
    type: object
    value:
      Trusted Pubkeys:
        type: string
        value: "1,247"
      Last Updated:
        type: string
        value: "2025-12-24 10:30 UTC"
      Next Refresh:
        type: string
        value: "2025-12-25 10:30 UTC"
```

---

## 🧪 Testing Strategy

### Unit Tests

```go
// wot_test.go
func TestWebOfTrust_BuildGraph(t *testing.T) {
    wot := &WoTGraph{
        owner: "test-pubkey",
        depth: 2,
        trusted: make(map[string]bool),
    }
    
    wot.BuildTrustNetwork()
    
    assert.True(t, len(wot.trusted) > 0)
    assert.True(t, wot.IsTrusted("direct-follow"))
}

// blossom_test.go
func TestBlossom_Upload(t *testing.T) {
    data := []byte("test image")
    sha256 := calculateSHA256(data)
    
    err := blossomServer.StoreBlob(ctx, sha256, "jpg", data)
    
    assert.NoError(t, err)
    assert.FileExists(t, "/data/blossom/" + sha256)
}
```

### Integration Tests

```bash
#!/bin/bash
# test-relays.sh

ONION_ADDRESS=$1

echo "Testing Haven relays at ${ONION_ADDRESS}..."

# Test Outbox (should be readable)
echo "Testing Outbox relay..."
curl -sf --socks5-hostname 127.0.0.1:9050 \
  "http://${ONION_ADDRESS}" | grep -q "Haven"

# Test Private (should require auth)
echo "Testing Private relay..."
wscat --socks5 127.0.0.1:9050 \
  -c "ws://${ONION_ADDRESS}/private" \
  -x '["REQ","test",{}]' | grep -q "auth-required"

# Test Blossom (should be accessible)
echo "Testing Blossom server..."
curl -sf --socks5-hostname 127.0.0.1:9050 \
  -H "Accept: application/nostr+json" \
  "http://${ONION_ADDRESS}/.well-known/nostr/nip96.json"

echo "All tests passed!"
```

### Load Testing

```bash
# Load test with websocat
parallel -j 10 \
  'websocat --socks5 127.0.0.1:9050 ws://$ONION/.onion' \
  ::: $(seq 1 100)

# Blossom upload stress test
for i in {1..100}; do
  dd if=/dev/urandom of=test_$i.jpg bs=1M count=1
  curl --socks5-hostname 127.0.0.1:9050 \
    -X POST "http://$ONION_ADDRESS/upload" \
    -F "file=@test_$i.jpg" \
    -H "Authorization: Nostr $AUTH_EVENT"
done
```

---

## 📊 Performance Considerations

### Database Performance

| Engine | Read Speed | Write Speed | Memory Usage | Best For |
|--------|-----------|-------------|--------------|----------|
| BadgerDB | Fast | Fast | Medium | General use, broad compatibility |
| LMDB | Very Fast | Very Fast | Low | NVMe drives, high performance |

### Memory Management

```go
// Optimize BadgerDB for limited memory
db := badger.Open(badger.DefaultOptions(path).
    WithValueLogFileSize(64 << 20).  // 64MB value log
    WithMaxTableSize(8 << 20).       // 8MB SSTable
    WithNumMemtables(2).             // Reduce memtables
    WithNumLevelZeroTables(2))

// LMDB map size calculation
// Available disk: 100GB → Set map size: 90GB
// Available disk: 10GB → Set map size: 8GB
mapSize := availableDisk * 0.9
```

### Connection Limits

```yaml
# Rate limiting configuration
limits:
  connections-per-ip:
    tokens-per-interval: 10
    interval-minutes: 1
    max-tokens: 100
  
  events-per-ip:
    tokens-per-interval: 30
    interval-minutes: 1
    max-tokens: 300
  
  ws-message-size: 524288  # 512KB
  ws-read-timeout: 10s
  ws-write-timeout: 10s
```

---

## 🔄 Backup & Recovery

### Backup Strategies

#### 1. Start9 Native Backup

```yaml
backup:
  create:
    type: docker
    image: compat
    entrypoint: compat
    args: [duplicity, create, /mnt/backup, /data]
    mounts:
      BACKUP: /mnt/backup
      main: /data
```

#### 2. Cloud Backup (S3)

```go
func backupToS3() error {
    // 1. Create tar archive
    archive := createTarGz("/data/db")
    
    // 2. Upload to S3
    s3Client.Upload(&s3.PutObjectInput{
        Bucket: aws.String(config.S3Bucket),
        Key:    aws.String(fmt.Sprintf("haven-backup-%s.tar.gz", time.Now().Format("20060102-150405"))),
        Body:   archive,
    })
    
    // 3. Cleanup old backups (keep last 7 days)
    cleanupOldBackups(7)
    
    return nil
}
```

### Recovery Process

```bash
# Manual recovery from S3 backup
#!/bin/bash

# 1. Download backup
aws s3 cp s3://bucket/haven-backup-latest.tar.gz ./

# 2. Stop service
start-cli service stop haven

# 3. Extract backup
tar -xzf haven-backup-latest.tar.gz -C /embassy-data/package-data/haven/

# 4. Start service
start-cli service start haven
```

---

## 🐛 Debugging & Monitoring

### Logging Levels

```go
// Structured logging with slog
slog.Debug("WebSocket connection opened", "ip", remoteAddr)
slog.Info("Event stored", "id", event.ID, "kind", event.Kind)
slog.Warn("Rate limit exceeded", "ip", remoteAddr, "limit", limit)
slog.Error("Database error", "error", err)
```

### Metrics Collection

```go
type Metrics struct {
    EventsReceived   int64
    EventsStored     int64
    EventsRejected   int64
    BlobsUploaded    int64
    BlobsServed      int64
    WsConnections    int64
    AuthSuccess      int64
    AuthFailures     int64
    WoTSize          int64
}

// Expose via /metrics endpoint (optional)
func metricsHandler(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(metrics)
}
```

### Health Checks

```bash
#!/bin/bash
# check-web.sh - Health check script

# Check HTTP response
if ! curl -sf http://localhost:3355 > /dev/null; then
    echo '{"status":"error","message":"HTTP not responding"}'
    exit 1
fi

# Check WebSocket
if ! wscat -c ws://localhost:3355 --execute '["REQ","health",{}]' 2>/dev/null; then
    echo '{"status":"error","message":"WebSocket not responding"}'
    exit 1
fi

# Check database
if ! [ -d /data/db/outbox ]; then
    echo '{"status":"error","message":"Database not initialized"}'
    exit 1
fi

# Check Tor
if ! [ -f /var/lib/tor/haven/hostname ]; then
    echo '{"status":"error","message":"Tor hidden service not ready"}'
    exit 1
fi

echo '{"status":"success","message":"All checks passed"}'
exit 0
```

---

## 🚨 Error Handling

### Error Categories

```go
// Domain-specific errors
type HavenError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details map[string]interface{} `json:"details,omitempty"`
}

const (
    ErrAuthRequired    = "AUTH_REQUIRED"
    ErrNotInWoT        = "NOT_IN_WOT"
    ErrInvalidEvent    = "INVALID_EVENT"
    ErrRateLimited     = "RATE_LIMITED"
    ErrStorageFull     = "STORAGE_FULL"
    ErrInvalidFile     = "INVALID_FILE"
    ErrFileTooLarge    = "FILE_TOO_LARGE"
    ErrDatabaseError   = "DATABASE_ERROR"
)

// Graceful degradation
func handleError(err error) {
    switch {
    case errors.Is(err, database.ErrClosed):
        // Attempt reconnection
        reconnectDatabase()
    case errors.Is(err, network.ErrTimeout):
        // Log and continue
        slog.Warn("Network timeout", "error", err)
    default:
        // Critical error - log and potentially restart
        slog.Error("Critical error", "error", err)
        notifyAdmin(err)
    }
}
```

---

## 📈 Future Enhancements

### Roadmap

#### v1.1 (Q1 2025)
- [ ] Prometheus metrics exporter
- [ ] Grafana dashboard template
- [ ] Advanced rate limiting (per-pubkey)
- [ ] Improved WoT algorithm (PageRank-based)

#### v1.2 (Q2 2025)
- [ ] NIP-50 (Search capability)
- [ ] NIP-65 (Relay list metadata)
- [ ] Custom relay policies via config
- [ ] Multi-tenant support (optional)

#### v2.0 (Q3 2025)
- [ ] Built-in Nostr client UI
- [ ] Advanced analytics dashboard
- [ ] Automated relay discovery
- [ ] Federation with other Haven instances

---

## 🤝 Contributing

### Development Setup

```bash
# Clone repository
git clone https://github.com/bitvora/haven-start9-wrapper.git
cd haven-start9-wrapper-start9-wrapper

# Install dependencies
./prepare.sh

# Build Docker image
make docker-images.tar

# Run tests
make test

# Build package
make

# Install on Start9
make install
```

### Code Style

- Go: `gofmt` + `golangci-lint`
- Shell: `shellcheck`
- YAML: `yamllint`
- Markdown: `markdownlint`

### Pull Request Checklist

- [ ] Tests pass
- [ ] Documentation updated
- [ ] Changelog entry added
- [ ] Version bumped (if needed)
- [ ] Start9 SDK verification passes

---

## 📝 License

MIT License - See [LICENSE](../LICENSE) file

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-12-24  
**Maintainer**: Oracle + AI Assistant

---

_For implementation questions, refer to [start9-packaging-plan.md](./start9-packaging-plan.md)_

