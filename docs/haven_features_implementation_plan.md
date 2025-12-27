# Haven 機能仕様 & 実装計画書

**作成日**: 2025-12-27  
**最終更新**: 2025-12-27  
**ステータス**: ✅ 最新

---

## 📚 目次

1. [Haven 概要](#-haven-概要)
2. [コアアーキテクチャ](#-コアアーキテクチャ)
3. [4つのリレー機能](#-4つのリレー機能)
4. [Blossom メディアサーバー](#-blossom-メディアサーバー)
5. [Web of Trust (WoT)](#-web-of-trust-wot)
6. [Import 機能](#-import-機能)
7. [Blastr 機能](#-blastr-機能)
8. [バックアップ機能](#-バックアップ機能)
9. [Rate Limiting](#-rate-limiting)
10. [データベース](#-データベース)
11. [設定項目](#-設定項目)
12. [Start9 統合状況](#-start9-統合状況)
13. [今後の実装計画](#-今後の実装計画)

---

## 🎯 Haven 概要

### プロジェクト名
**HAVEN** - High Availability Vault for Events on Nostr

### コンセプト
最も主権的なパーソナル Nostr リレー。eCash、プライベートチャット、ドラフトなどのセンシティブなノートを保存・バックアップするための「賢いリレー」。

### 主要特徴

```
┌─────────────────────────────────────────────────────┐
│                     HAVEN                           │
│  High Availability Vault for Events on Nostr       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🔒 4 Specialized Relays                           │
│  🌸 Blossom Media Server                           │
│  🕸️ Web of Trust Integration                       │
│  📦 Import & Sync                                   │
│  🔫 Blastr Broadcasting                             │
│  ☁️ Cloud Backups                                   │
│  🧅 Tor-Only (Start9)                               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🏛️ コアアーキテクチャ

### システム構成

```
┌──────────────────────────────────────────────────────────┐
│                   Client Applications                    │
│  (Amethyst, Damus, Primal, Coracle, nostrudel, etc.)   │
└────────────────────┬─────────────────────────────────────┘
                     │ WebSocket (wss://)
                     │
┌────────────────────▼─────────────────────────────────────┐
│                Haven Main Process (Go)                   │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Dynamic Relay Handler (main.go)              │    │
│  │  - Route requests to appropriate relay         │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────┬─────────────┬──────────┬──────────┐  │
│  │ Private     │ Chat        │ Inbox    │ Outbox   │  │
│  │ /private    │ /chat       │ /inbox   │ /        │  │
│  │ (Auth)      │ (Auth+WoT)  │ (WoT)    │ (Owner)  │  │
│  └─────────────┴─────────────┴──────────┴──────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Blossom Media Server (blossom.go)              │  │
│  │  - NIP-96 & BUD-02 compliant                    │  │
│  │  - File storage: /data/blossom/                 │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│                Database Layer                            │
│  ┌──────────┬──────────┬──────────┬──────────┬────────┐│
│  │ Private  │ Chat     │ Inbox    │ Outbox   │Blossom ││
│  │ DB       │ DB       │ DB       │ DB       │ DB     ││
│  │ (LMDB/   │ (LMDB/   │ (LMDB/   │ (LMDB/   │(LMDB/  ││
│  │  Badger) │  Badger) │  Badger) │  Badger) │Badger) ││
│  └──────────┴──────────┴──────────┴──────────┴────────┘│
│                                                          │
│  Storage: /data/db/{private,chat,inbox,outbox,blossom}  │
└──────────────────────────────────────────────────────────┘
```

### 技術スタック

| 要素 | 技術 |
|------|------|
| **言語** | Go 1.21+ |
| **リレー実装** | [khatru](https://github.com/fiatjaf/khatru) |
| **データベース** | LMDB (default) / BadgerDB |
| **Nostr ライブラリ** | [go-nostr](https://github.com/nbd-wtf/go-nostr) |
| **Blossom** | [khatru/blossom](https://github.com/fiatjaf/khatru/tree/master/blossom) |
| **クラウドバックアップ** | S3-compatible APIs |
| **コンテナ** | Docker |
| **ネットワーク** | Tor (Start9) |

### ファイルシステム構造 (Start9)

```
/data/
├── db/
│   ├── private/           # Private relay database
│   ├── chat/              # Chat relay database
│   ├── inbox/             # Inbox relay database
│   ├── outbox/            # Outbox relay database
│   └── blossom/           # Blossom metadata database
├── blossom/               # Blossom media files (by SHA256)
│   ├── <sha256_hash_1>
│   ├── <sha256_hash_2>
│   └── ...
├── tor/
│   └── haven/             # Tor hidden service keys (persisted)
│       ├── hostname
│       ├── hs_ed25519_public_key
│       └── hs_ed25519_secret_key
├── logs/
│   ├── haven.log          # Main application log
│   └── import-*.log       # Import session logs
├── config/
│   └── .env               # Configuration file
└── .import-request        # Import flag (when import pending)
```

---

## 🔐 4つのリレー機能

Haven は 4つの専門化されたリレーを1つのプロセスで提供します。

### 1. Private Relay (`/private`)

**目的**: オーナーのみがアクセスできる完全プライベートなリレー

```
┌────────────────────────────────────────────────────┐
│             Private Relay (/private)               │
├────────────────────────────────────────────────────┤
│ アクセス: Owner Only (NIP-42 Auth Required)        │
│ 読み取り: Owner Only                                │
│ 書き込み: Owner Only                                │
├────────────────────────────────────────────────────┤
│ 用途:                                              │
│  - ドラフト (Kind 31234: Draft Long-form)         │
│  - eCash トークン (Kind 7375, 7376)               │
│  - プライベートブックマーク (Kind 10003)           │
│  - プライベートリスト                               │
│  - 任意のプライベートノート                         │
├────────────────────────────────────────────────────┤
│ セキュリティ:                                       │
│  ✅ NIP-42 (Auth) 必須                             │
│  ✅ Owner 以外は読み取り・書き込み拒否              │
│  ✅ Rate limiting                                  │
│  ✅ Empty/Complex filter 制限可能                  │
└────────────────────────────────────────────────────┘
```

**実装ファイル**: `init.go:96-177`

**主要コード**:
```go
privateRelay.RejectFilter = append(privateRelay.RejectFilter, 
  func(ctx context.Context, filter nostr.Filter) (bool, string) {
    authenticatedUser := khatru.GetAuthed(ctx)
    if authenticatedUser == nPubToPubkey(config.OwnerNpub) {
      return false, ""
    }
    return true, "auth-required: this query requires you to be authenticated"
})

privateRelay.RejectEvent = append(privateRelay.RejectEvent, 
  func(ctx context.Context, event *nostr.Event) (bool, string) {
    authenticatedUser := khatru.GetAuthed(ctx)
    if authenticatedUser == nPubToPubkey(config.OwnerNpub) {
      return false, ""
    }
    return true, "auth-required: publishing this event requires authentication"
})
```

### 2. Chat Relay (`/chat`)

**目的**: Web of Trust 内のユーザーとの DM/チャット

```
┌────────────────────────────────────────────────────┐
│              Chat Relay (/chat)                    │
├────────────────────────────────────────────────────┤
│ アクセス: Web of Trust Members (NIP-42 Auth)       │
│ 読み取り: WoT Members                              │
│ 書き込み: WoT Members                              │
├────────────────────────────────────────────────────┤
│ 許可される Kind:                                    │
│  - Kind 14: Chat Message                           │
│  - Kind 1059: Gift Wrap (encrypted DMs)            │
│  - Kind 9, 10, 11, 12: Simple Group kinds          │
│  - Kind 29: Simple Group Metadata                  │
│  - Kind 39, 40, 41: Channel kinds                  │
├────────────────────────────────────────────────────┤
│ Web of Trust 判定:                                 │
│  ✅ Owner のフォローリスト内                        │
│  ✅ フォローリスト内のユーザーから N-hop 以内       │
│  ✅ 最小フォロワー数を満たす                        │
├────────────────────────────────────────────────────┤
│ セキュリティ:                                       │
│  ✅ NIP-42 (Auth) 必須                             │
│  ✅ WoT メンバー以外は拒否                          │
│  ✅ Gift Wrap DM のみ受付 (古い NIP-04 は拒否)     │
│  ✅ Rate limiting                                  │
└────────────────────────────────────────────────────┘
```

**実装ファイル**: `init.go:179-289`

**許可される Event Kinds**:
```go
allowedKinds := []int{
  nostr.KindSimpleGroupChatMessage,         // 14
  nostr.KindSimpleGroupThreadedReply,       // 1111
  nostr.KindSimpleGroupThread,              // 11
  nostr.KindSimpleGroupReply,               // 12
  nostr.KindChannelMessage,                 // 42
  nostr.KindChannelHideMessage,             // 43
  nostr.KindGiftWrap,                       // 1059
  nostr.KindSimpleGroupPutUser,             // 9000
  nostr.KindSimpleGroupRemoveUser,          // 9001
  nostr.KindSimpleGroupEditMetadata,        // 9002
  nostr.KindSimpleGroupDeleteEvent,         // 9005
  nostr.KindSimpleGroupCreateGroup,         // 9006
  nostr.KindSimpleGroupDeleteGroup,         // 9007
  nostr.KindSimpleGroupCreateInvite,        // 9009
  nostr.KindSimpleGroupJoinRequest,         // 9021
  nostr.KindSimpleGroupLeaveRequest,        // 9022
  // Addressable kinds
  nostr.KindSimpleGroupMetadata,            // 39000
  nostr.KindSimpleGroupAdmins,              // 39001
  nostr.KindSimpleGroupMembers,             // 39002
  nostr.KindSimpleGroupRoles,               // 39003
}
```

### 3. Inbox Relay (`/inbox`)

**目的**: オーナー宛のメンション・リアクション・Zap などを自動収集

```
┌────────────────────────────────────────────────────┐
│              Inbox Relay (/inbox)                  │
├────────────────────────────────────────────────────┤
│ 読み取り: Public                                    │
│ 書き込み: WoT Members (with p-tag to owner)        │
├────────────────────────────────────────────────────┤
│ 自動収集される Event:                               │
│  - Kind 1: Text Note (replies)                    │
│  - Kind 6: Repost                                 │
│  - Kind 7: Reaction (likes, emojis)              │
│  - Kind 9735: Zap                                 │
│  - その他 owner を p-tag したイベント              │
├────────────────────────────────────────────────────┤
│ 自動同期:                                          │
│  ✅ Import seed relays から定期的に pull           │
│  ✅ リアルタイム購読 (subscribeInboxAndChat)       │
│  ✅ 重複チェック                                    │
├────────────────────────────────────────────────────┤
│ フィルタリング:                                     │
│  ✅ p-tag に owner pubkey が含まれる                │
│  ✅ WoT メンバーのみ (Gift Wrap は除外)            │
│  ✅ 古い NIP-04 DM は拒否                          │
└────────────────────────────────────────────────────┘
```

**実装ファイル**: `init.go:411-485`, `import.go:166-227`

**自動同期ロジック**:
```go
func subscribeInboxAndChat() {
  ctx := context.Background()
  wdbInbox := eventstore.RelayWrapper{Store: inboxDB}
  wdbChat := eventstore.RelayWrapper{Store: chatDB}
  
  filter := nostr.Filter{
    Tags: nostr.TagMap{
      "p": {nPubToPubkey(config.OwnerNpub)},
    },
    Since: &startTime,
  }
  
  for ev := range pool.SubscribeMany(ctx, config.ImportSeedRelays, filter) {
    if !wotMap[ev.Event.PubKey] && ev.Event.Kind != nostr.KindGiftWrap {
      continue
    }
    
    // Route to inbox or chat based on kind
    if ev.Event.Kind == nostr.KindGiftWrap {
      dbToPublish = wdbChat
    } else {
      dbToPublish = wdbInbox
    }
    
    if !isDuplicate(ctx, dbToPublish, ev.Event) {
      dbToPublish.Publish(ctx, *ev.Event)
    }
  }
}
```

### 4. Outbox Relay (`/`)

**目的**: オーナーのパブリックノートを配信

```
┌────────────────────────────────────────────────────┐
│              Outbox Relay (/)                      │
├────────────────────────────────────────────────────┤
│ 読み取り: Public                                    │
│ 書き込み: Owner Only                                │
├────────────────────────────────────────────────────┤
│ 配信される Event:                                   │
│  - Kind 0: Metadata                               │
│  - Kind 1: Text Note                              │
│  - Kind 3: Contacts                               │
│  - Kind 6: Repost                                 │
│  - Kind 7: Reaction                               │
│  - Kind 10002: Relay List Metadata               │
│  - Kind 30023: Long-form Content                 │
│  - その他全ての owner のパブリックイベント         │
├────────────────────────────────────────────────────┤
│ Blastr 統合:                                        │
│  ✅ 全ての新規イベントを自動ブロードキャスト         │
│  ✅ 設定した複数リレーに同時配信                    │
│  ✅ Tor経由で外部リレーに送信                       │
├────────────────────────────────────────────────────┤
│ Blossom 統合:                                       │
│  ✅ 同じエンドポイントで Blossom API 提供           │
│  ✅ GET/POST /upload                               │
│  ✅ GET /<sha256>                                  │
└────────────────────────────────────────────────────┘
```

**実装ファイル**: `init.go:291-360`

**Blastr 連携**:
```go
outboxRelay.StoreEvent = append(outboxRelay.StoreEvent, 
  outboxDB.SaveEvent, 
  func(ctx context.Context, event *nostr.Event) error {
    go blast(event)  // 非同期でブロードキャスト
    return nil
})
```

---

## 🌸 Blossom メディアサーバー

### 概要

Blossom は Nostr のための分散型メディアホスティングプロトコルです。Haven は完全な Blossom サーバーを統合しています。

```
┌──────────────────────────────────────────────────┐
│          Blossom Media Server                    │
│          (NIP-96 & BUD-02 Compliant)             │
├──────────────────────────────────────────────────┤
│ Endpoints:                                       │
│  - GET  /<sha256>         (Download blob)       │
│  - POST /upload           (Upload blob)         │
│  - GET  /list             (List blobs)          │
│  - DELETE /<sha256>       (Delete blob)         │
├──────────────────────────────────────────────────┤
│ Storage:                                         │
│  - Location: /data/blossom/                     │
│  - Filename: SHA256 hash (no extension)         │
│  - Metadata: Stored in blossomDB                │
├──────────────────────────────────────────────────┤
│ Authentication:                                  │
│  ✅ Upload: Owner only (NIP-98 Auth)            │
│  ✅ Download: Public                             │
│  ✅ Delete: Owner only                           │
├──────────────────────────────────────────────────┤
│ Supported Formats:                               │
│  - Images: jpg, jpeg, png, gif, webp            │
│  - Videos: mp4, mov, avi, mkv                   │
│  - Audio: mp3, wav, ogg, flac                   │
│  - Documents: pdf                                │
│  - Any binary file                               │
└──────────────────────────────────────────────────┘
```

### 実装詳細

**ファイル**: `init.go:362-409`

```go
bl := blossom.New(outboxRelay, serviceURL)
bl.Store = blossom.EventStoreBlobIndexWrapper{
  Store: blossomDB, 
  ServiceURL: bl.ServiceURL,
}

// Upload (Store)
bl.StoreBlob = append(bl.StoreBlob, 
  func(ctx context.Context, sha256 string, ext string, body []byte) error {
    file, err := fs.Create(config.BlossomPath + "/" + sha256)
    if err != nil {
      return err
    }
    defer file.Close()
    
    if _, err := io.Copy(file, bytes.NewReader(body)); err != nil {
      return err
    }
    
    return nil
})

// Download (Load)
bl.LoadBlob = append(bl.LoadBlob, 
  func(ctx context.Context, sha256 string, ext string) (io.ReadSeeker, error) {
    file, err := fs.Open(config.BlossomPath + "/" + sha256)
    if err != nil {
      return nil, err
    }
    return file, nil
})

// Delete
bl.DeleteBlob = append(bl.DeleteBlob, 
  func(ctx context.Context, sha256 string, ext string) error {
    err := fs.Remove(config.BlossomPath + "/" + sha256)
    return err
})

// Access Control
bl.RejectUpload = append(bl.RejectUpload, 
  func(ctx context.Context, event *nostr.Event, size int, ext string) (bool, string, int) {
    if event.PubKey == nPubToPubkey(config.OwnerNpub) {
      return false, ext, size
    }
    return true, "only notes signed by the owner of this relay are allowed", 403
})
```

### クライアント対応状況

| クライアント | Blossom 対応 | ステータス |
|------------|-------------|----------|
| **Amethyst** (Android) | ✅ Full Support | 完全動作確認済み |
| **Damus** (iOS) | ⚠️ Partial | NIP-96 のみ |
| **Primal** | ⚠️ Partial | 画像のみ |
| **Coracle** | ❌ No | - |
| **nostrudel** | ✅ Full Support | 完全動作確認済み |

---

## 🕸️ Web of Trust (WoT)

### 概念

Haven の WoT は、オーナーのソーシャルグラフに基づいてスパムをフィルタリングします。

```
┌──────────────────────────────────────────────────┐
│          Web of Trust Architecture               │
└──────────────────────────────────────────────────┘

Owner (You)
    │
    ├─ Follows (0-hop / Direct Followers)
    │    │
    │    ├─ Alice
    │    ├─ Bob
    │    └─ Charlie
    │
    └─ 1-hop Network (Friends of Friends)
         │
         ├─ Alice follows → Dave, Eve
         ├─ Bob follows → Frank, Grace
         └─ Charlie follows → Hannah, Isaac
         
┌──────────────────────────────────────────────────┐
│ Filtering Criteria:                              │
│  1. Minimum Followers: 3 (configurable)         │
│  2. WoT Depth: 1 (configurable, 0=direct only)  │
│  3. Refresh Interval: 24 hours (configurable)   │
└──────────────────────────────────────────────────┘
```

### 実装

**ファイル**: `wot.go`

```go
var (
  pubkeyFollowerCount = make(map[string]int)  // Follower count per pubkey
  oneHopNetwork       []string                 // 1-hop network pubkeys
  wot                 []string                 // Final WoT list
  wotMap              map[string]bool          // Fast lookup map
)

func refreshTrustNetwork() {
  // 1. Fetch owner's follow list (Kind 3)
  filter := nostr.Filter{
    Authors: []string{ownerPubkey},
    Kinds:   []int{nostr.KindFollowList},
  }
  
  events := pool.FetchMany(ctx, config.ImportSeedRelays, filter)
  for ev := range events {
    for contact := range ev.Event.Tags.FindAll("p") {
      pubkeyFollowerCount[contact[1]]++
      appendOneHopNetwork(contact[1])
    }
  }
  
  // 2. Fetch follow lists of 1-hop network
  for i := 0; i < len(oneHopNetwork); i += 100 {
    filter = nostr.Filter{
      Authors: oneHopNetwork[i:end],
      Kinds:   []int{nostr.KindFollowList, nostr.KindRelayListMetadata},
    }
    
    events := pool.FetchMany(ctx, config.ImportSeedRelays, filter)
    for ev := range events {
      for contact := range ev.Tags.FindAll("p") {
        pubkeyFollowerCount[contact[1]]++
      }
    }
  }
  
  // 3. Filter by minimum followers
  updateWoTMap()
}

func updateWoTMap() {
  wotMapTmp := make(map[string]bool)
  
  for pubkey, count := range pubkeyFollowerCount {
    if count >= config.ChatRelayMinimumFollowers {
      wotMapTmp[pubkey] = true
      appendPubkeyToWoT(pubkey)
    }
  }
  
  wotMap = wotMapTmp
}
```

### 設定項目

| 項目 | 環境変数 | デフォルト値 | 説明 |
|------|---------|------------|------|
| **WoT Depth** | `CHAT_RELAY_WOT_DEPTH` | `0` | 0=direct, 1=1-hop, 2=2-hop |
| **Minimum Followers** | `CHAT_RELAY_MINIMUM_FOLLOWERS` | `0` | 最小フォロワー数 |
| **Refresh Interval** | `CHAT_RELAY_WOT_REFRESH_INTERVAL_HOURS` | `0` (disabled) | WoT 更新間隔 |
| **Fetch Timeout** | `WOT_FETCH_TIMEOUT_SECONDS` | `30` | フェッチタイムアウト |

### 使用箇所

1. **Chat Relay** (`/chat`)
   - 読み取り・書き込み: WoT メンバーのみ
   - Gift Wrap (Kind 1059) は例外

2. **Inbox Relay** (`/inbox`)
   - 書き込み: WoT メンバーのみ (p-tag に owner)
   - Gift Wrap は例外

```go
// Chat relay filter check
chatRelay.RejectFilter = append(chatRelay.RejectFilter, 
  func(ctx context.Context, filter nostr.Filter) (bool, string) {
    authenticatedUser := khatru.GetAuthed(ctx)
    
    if !wotMap[authenticatedUser] {
      return true, "you must be in the web of trust to chat with the relay owner"
    }
    
    return false, ""
})

// Inbox relay event check
inboxRelay.RejectEvent = append(inboxRelay.RejectEvent, 
  func(ctx context.Context, event *nostr.Event) (bool, string) {
    if !wotMap[event.PubKey] {
      return true, "you must be in the web of trust to post to this relay"
    }
    
    if event.Kind == nostr.KindEncryptedDirectMessage {
      return true, "only gift wrapped DMs are supported"
    }
    
    if event.Tags.FindWithValue("p", inboxRelay.Info.PubKey) != nil {
      return false, ""
    }
    
    return true, "you can only post notes if you've tagged the owner of this relay"
})
```

---

## 📦 Import 機能

### 概要

Haven は過去のノートを外部リレーからインポートする機能を提供します。

```
┌──────────────────────────────────────────────────┐
│              Import Architecture                 │
└──────────────────────────────────────────────────┘

1. Owner Notes Import (importOwnerNotes)
   ┌─────────────────────────────────────┐
   │ Import Seed Relays                  │
   │  - relay.damus.io                   │
   │  - nos.lol                          │
   │  - relay.snort.social               │
   │  - ...                              │
   └─────────────────┬───────────────────┘
                     │
                     │ Filter: authors=[owner_npub]
                     │         since=IMPORT_START_DATE
                     │         until=start+10days
                     ▼
              ┌─────────────┐
              │ Owner Notes │──→ Outbox DB
              └─────────────┘

2. Tagged Notes Import (importTaggedNotes)
   ┌─────────────────────────────────────┐
   │ Import Seed Relays                  │
   └─────────────────┬───────────────────┘
                     │
                     │ Filter: #p=[owner_npub]
                     │         (all history)
                     ▼
              ┌──────────────────┐
              │ Tagged Notes     │
              │  - Replies       │──→ Inbox DB
              │  - Reactions     │
              │  - Zaps          │
              │  - Gift Wraps    │──→ Chat DB
              └──────────────────┘

3. Continuous Sync (subscribeInboxAndChat)
   ┌─────────────────────────────────────┐
   │ Import Seed Relays                  │
   └─────────────────┬───────────────────┘
                     │
                     │ Subscribe: #p=[owner_npub]
                     │            since=now-5min
                     ▼
              ┌──────────────────┐
              │ Real-time Events │
              │  (auto-imported) │
              └──────────────────┘
```

### 実装詳細

**ファイル**: `import.go`

#### 1. Owner Notes Import

```go
func importOwnerNotes() {
  wdb := eventstore.RelayWrapper{Store: outboxDB}
  
  startTime, _ := time.Parse(layout, config.ImportStartDate)
  endTime := startTime.Add(240 * time.Hour)  // 10 days batch
  
  for {
    filter := nostr.Filter{
      Authors: []string{nPubToPubkey(config.OwnerNpub)},
      Since:   &startTimestamp,
      Until:   &endTimestamp,
    }
    
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    
    events := pool.FetchMany(ctx, config.ImportSeedRelays, filter)
    for ev := range events {
      if err := wdb.Publish(ctx, *ev.Event); err != nil {
        log.Println("error importing note", ev.ID, ":", err)
      }
    }
    
    startTime = startTime.Add(240 * time.Hour)
    endTime = endTime.Add(240 * time.Hour)
    
    if startTime.After(time.Now()) {
      break
    }
  }
}
```

**特徴**:
- 10日ごとのバッチ処理
- タイムアウト設定可能
- 進捗ログ
- 失敗カウント

#### 2. Tagged Notes Import

```go
func importTaggedNotes() {
  wdbInbox := eventstore.RelayWrapper{Store: inboxDB}
  wdbChat := eventstore.RelayWrapper{Store: chatDB}
  
  filter := nostr.Filter{
    Tags: nostr.TagMap{
      "p": {nPubToPubkey(config.OwnerNpub)},
    },
  }
  
  ctx, cancel := context.WithTimeout(context.Background(), timeout)
  defer cancel()
  
  events := pool.FetchMany(ctx, config.ImportSeedRelays, filter)
  for ev := range events {
    // WoT check
    if !wotMap[ev.PubKey] && ev.Kind != nostr.KindGiftWrap {
      continue
    }
    
    // Route to appropriate DB
    dbToWrite := wdbInbox
    if ev.Kind == nostr.KindGiftWrap {
      dbToWrite = wdbChat
    }
    
    if err := dbToWrite.Publish(ctx, *ev.Event); err != nil {
      log.Println("error importing tagged note", ev.ID, ":", err)
    }
  }
}
```

**特徴**:
- 全履歴を一度に取得
- WoT フィルタリング
- Gift Wrap は Chat DB へ
- タイムアウト設定可能

#### 3. Continuous Sync

```go
func subscribeInboxAndChat() {
  ctx := context.Background()
  wdbInbox := eventstore.RelayWrapper{Store: inboxDB}
  wdbChat := eventstore.RelayWrapper{Store: chatDB}
  
  startTime := nostr.Timestamp(time.Now().Add(-time.Minute * 5).Unix())
  filter := nostr.Filter{
    Tags: nostr.TagMap{
      "p": {nPubToPubkey(config.OwnerNpub)},
    },
    Since: &startTime,
  }
  
  for ev := range pool.SubscribeMany(ctx, config.ImportSeedRelays, filter) {
    // WoT check
    if !wotMap[ev.Event.PubKey] && ev.Event.Kind != nostr.KindGiftWrap {
      continue
    }
    
    // Duplicate check
    if isDuplicate(ctx, dbToPublish, ev.Event) {
      continue
    }
    
    // Route and publish
    dbToPublish := wdbInbox
    if ev.Event.Kind == nostr.KindGiftWrap {
      dbToPublish = wdbChat
    }
    
    if err := dbToPublish.Publish(ctx, *ev.Event); err != nil {
      log.Println("error importing tagged note", ev.Event.ID)
    }
    
    // Log notification
    switch ev.Event.Kind {
    case nostr.KindTextNote:
      log.Println("📰 new note in your inbox")
    case nostr.KindReaction:
      log.Println(ev.Event.Content, "new reaction in your inbox")
    case nostr.KindZap:
      log.Println("⚡️ new zap in your inbox")
    case nostr.KindGiftWrap:
      log.Println("🎁🔒️✉️ new gift-wrapped message in your chat relay")
    }
  }
}
```

### Start9 統合

**Action**: `import-notes` (manifest.yaml:203-245)

```yaml
actions:
  import-notes:
    name: Import Past Notes
    description: |
      Configure Haven to import your past notes and mentions on next restart.
    warning: |
      ⚠️ IMPORTANT: After running this action, you MUST restart Haven!
    implementation:
      type: docker
      image: main
      entrypoint: docker_entrypoint.sh
      args: ["import-notes"]
```

**フロー**:
1. ユーザーが Start9 UI で "Import Past Notes" アクション実行
2. `.import-request` フラグファイル作成
3. Haven を再起動
4. `docker_entrypoint.sh` が `--import` フラグ付きで Haven を起動
5. Import 実行
6. 完了後、Haven は通常モードで自動再起動

### 設定項目

| 項目 | 環境変数 | デフォルト値 | 説明 |
|------|---------|------------|------|
| **Start Date** | `IMPORT_START_DATE` | - | インポート開始日 (YYYY-MM-DD) |
| **Owner Notes Timeout** | `IMPORT_OWNER_NOTES_FETCH_TIMEOUT_SECONDS` | `30` | Owner ノート取得タイムアウト |
| **Tagged Notes Timeout** | `IMPORT_TAGGED_NOTES_FETCH_TIMEOUT_SECONDS` | `120` | Tagged ノート取得タイムアウト |
| **Query Interval** | `IMPORT_QUERY_INTERVAL_SECONDS` | `360000` | 定期クエリ間隔 (未使用) |
| **Seed Relays** | `IMPORT_SEED_RELAYS_FILE` | - | インポート元リレーリスト (JSON) |
| **Inbox Pull Interval** | `INBOX_PULL_INTERVAL_SECONDS` | `3600` | Inbox 同期間隔 |

---

## 🔫 Blastr 機能

### 概要

Blastr は Haven の Outbox に投稿されたノートを自動的に複数の外部リレーにブロードキャストする機能です。

```
┌──────────────────────────────────────────────────┐
│              Blastr Architecture                 │
└──────────────────────────────────────────────────┘

Client
  │
  │ WebSocket Publish
  ▼
┌─────────────────┐
│ Outbox Relay    │
│    (/)          │
└────────┬────────┘
         │
         ├─ Save to outboxDB
         │
         └─ blast(event) ──┐
                           │
                           ▼
              ┌────────────────────────────┐
              │  Blastr Relay Pool         │
              │  (config.BlastrRelays)     │
              └────────────────────────────┘
                           │
                ┌──────────┼──────────┐
                ▼          ▼          ▼
           relay.damus.io  nos.lol  relay.snort.social
              (IPv4)     (IPv6)       (Tor)
```

### 実装

**ファイル**: `blastr.go`

```go
func blast(ev *nostr.Event) {
  ctx := context.Background()
  
  for _, url := range config.BlastrRelays {
    // Extended timeout for Tor connections (15 seconds)
    ctx, cancel := context.WithTimeout(ctx, time.Second*15)
    
    relay, err := pool.EnsureRelay(url)
    if err != nil {
      cancel()
      log.Println("error connecting to relay", relay, err)
      continue
    }
    
    if err := relay.Publish(ctx, *ev); err != nil {
      log.Println("🚫 error publishing to relay", relay, err)
    }
    
    cancel()
  }
  
  log.Println("🔫 blasted", ev.ID, "to", len(config.BlastrRelays), "relays")
}
```

**特徴**:
- 非同期実行 (`go blast(event)`)
- 15秒タイムアウト (Tor 対応)
- IPv6 サポート
- エラーハンドリング
- ログ出力

### 統合ポイント

**ファイル**: `init.go:324-327`

```go
outboxRelay.StoreEvent = append(outboxRelay.StoreEvent, 
  outboxDB.SaveEvent,
  func(ctx context.Context, event *nostr.Event) error {
    go blast(event)  // 非同期でブロードキャスト
    return nil
})
```

### 設定

**Start9 UI**: Config > Blastr Relay List (CSV format)

```
relay.damus.io,nos.lol,relay.snort.social,relay.nostr.band,nostr.mom,relay.primal.net,offchain.pub,nostr.bitcoiner.social
```

**環境変数**: `BLASTR_RELAYS_FILE` → `relays_blastr.json`

```json
[
  "wss://relay.damus.io",
  "wss://nos.lol",
  "wss://relay.snort.social",
  "wss://relay.nostr.band",
  "wss://nostr.mom",
  "wss://relay.primal.net",
  "wss://offchain.pub",
  "wss://nostr.bitcoiner.social"
]
```

### IPv6 サポート

**実装** (v1.1.3):
- Tor 設定: `ClientUseIPv6 1`, `ClientPreferIPv6ORPort 1`, `IPv6Exit 1`
- Go の Happy Eyeballs v2 (RFC 8305) による自動フォールバック
- IPv6 優先、300ms 後に IPv4 にフォールバック

---

## ☁️ バックアップ機能

### 概要

Haven はデータベースを定期的に S3 互換ストレージにバックアップします。

```
┌──────────────────────────────────────────────────┐
│           Backup Architecture                    │
└──────────────────────────────────────────────────┘

Haven Process
  │
  │ Every BACKUP_INTERVAL_HOURS
  ▼
┌─────────────────┐
│ backupDatabase()│
└────────┬────────┘
         │
         │ 1. ZIP database
         │    db/ → db.zip
         ▼
    ┌──────────┐
    │  db.zip  │
    └────┬─────┘
         │
         │ 2. Upload to cloud
         ▼
┌─────────────────────────┐
│  S3-Compatible Storage  │
│  - AWS S3               │
│  - GCP Cloud Storage    │
│  - DigitalOcean Spaces  │
│  - Wasabi               │
│  - Backblaze B2         │
│  - MinIO                │
└─────────────────────────┘
         │
         │ 3. Delete local db.zip
         ▼
       (Done)
```

### 実装

**ファイル**: `backup.go`

```go
func backupDatabase() {
  if config.BackupProvider == "none" || config.BackupProvider == "" {
    log.Println("🚫 no backup provider set")
    return
  }
  
  ticker := time.NewTicker(time.Duration(config.BackupIntervalHours) * time.Hour)
  defer ticker.Stop()
  
  zipFileName := "db.zip"
  
  for {
    select {
    case <-ticker.C:
      // 1. ZIP the database
      if err := ZipDirectory("db", zipFileName); err != nil {
        log.Println("🚫 error zipping database folder:", err)
        continue
      }
      
      // 2. Upload to cloud
      switch config.BackupProvider {
      case "s3":
        S3Upload(zipFileName)
      case "aws":
        AwsUpload(zipFileName)  // Deprecated
      case "gcp":
        GCPBucketUpload(zipFileName)  // Deprecated
      default:
        log.Println("🚫 we only support AWS, GCP, and S3 at this time")
      }
    }
  }
}
```

#### S3 Upload

```go
func S3Upload(zipFileName string) {
  // Create MinIO client (S3-compatible)
  client, err := minio.New(endpoint, &minio.Options{
    Creds:  credentials.NewStaticV4(accessKey, secret, ""),
    Region: region,
    Secure: secure,
  })
  
  // Upload file
  file, err := os.Open(zipFileName)
  defer file.Close()
  
  fileInfo, _ := file.Stat()
  
  _, err = client.PutObject(
    context.Background(),
    bucketName,
    zipFileName,
    file,
    fileInfo.Size(),
    minio.PutObjectOptions{
      ContentType: "application/octet-stream",
    },
  )
  
  // Delete local file
  os.Remove(zipFileName)
}
```

#### ZIP Database

```go
func ZipDirectory(sourceDir, zipFileName string) error {
  file, err := os.Create(zipFileName)
  defer file.Close()
  
  w := zip.NewWriter(file)
  defer w.Close()
  
  walker := func(path string, info os.FileInfo, err error) error {
    if info.IsDir() {
      return nil
    }
    
    file, err := os.Open(path)
    defer file.Close()
    
    f, err := w.Create(path)
    _, err = io.Copy(f, file)
    
    return nil
  }
  
  err = filepath.Walk(sourceDir, walker)
  return nil
}
```

### 設定項目

| 項目 | 環境変数 | デフォルト値 | 説明 |
|------|---------|------------|------|
| **Backup Provider** | `BACKUP_PROVIDER` | `none` | `s3`, `aws`, `gcp`, `none` |
| **Backup Interval** | `BACKUP_INTERVAL_HOURS` | `24` | バックアップ間隔 (時間) |
| **S3 Access Key** | `S3_ACCESS_KEY_ID` | - | S3 アクセスキー |
| **S3 Secret Key** | `S3_SECRET_KEY` | - | S3 シークレットキー |
| **S3 Endpoint** | `S3_ENDPOINT` | - | S3 エンドポイント |
| **S3 Region** | `S3_REGION` | - | S3 リージョン |
| **S3 Bucket** | `S3_BUCKET_NAME` | - | S3 バケット名 |

### Start9 での利用

Start9 ではバックアップは **Start9 の内蔵バックアップシステム** を使用します。Haven のクラウドバックアップは無効化されています (`BACKUP_PROVIDER=none`)。

Start9 バックアップ:
- `manifest.yaml:backup.create` で定義
- Duplicity を使用
- Start9 のバックアップ先 (外部 HDD, NAS, etc.) に保存

---

## 🚧 Rate Limiting

### 概要

Haven は IP ベースのレート制限を実装しています。

### アーキテクチャ

```
┌──────────────────────────────────────────────────┐
│          Rate Limiting Architecture              │
└──────────────────────────────────────────────────┘

Client Request
     │
     ▼
┌─────────────────┐
│ Connection      │───→ Connection Rate Limiter
│ Established     │     (per IP, per minute)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Event Published │───→ Event Rate Limiter
│                 │     (per IP, per minute)
└─────────────────┘
```

### 実装

**ファイル**: `limits.go`, `init.go`

#### Token Bucket Algorithm

Haven は Khatru のポリシーを使用:
- `policies.EventIPRateLimiter`
- `policies.ConnectionRateLimiter`

```go
// Event rate limiting
privateRelay.RejectEvent = append(privateRelay.RejectEvent,
  policies.EventIPRateLimiter(
    tokensPerInterval,  // 新規トークン数
    interval,           // 補充間隔 (分)
    maxTokens,          // 最大トークン数
  ),
)

// Connection rate limiting
privateRelay.RejectConnection = append(privateRelay.RejectConnection,
  policies.ConnectionRateLimiter(
    tokensPerInterval,  // 新規トークン数
    interval,           // 補充間隔 (分)
    maxTokens,          // 最大トークン数
  ),
)
```

### デフォルト設定

| Relay | Event Tokens/Min | Event Max | Conn Tokens/Min | Conn Max |
|-------|-----------------|-----------|----------------|----------|
| **Private** | 50 | 100 | 3 | 9 |
| **Chat** | 50 | 100 | 3 | 9 |
| **Inbox** | 10 | 20 | 3 | 9 |
| **Outbox** | 10 | 100 | 3 | 9 |

### フィルター制限

```go
type RelayLimits struct {
  EventIPLimiterTokensPerInterval        int
  EventIPLimiterInterval                 int
  EventIPLimiterMaxTokens                int
  AllowEmptyFilters                      bool   // 空フィルター許可
  AllowComplexFilters                    bool   // 複雑フィルター許可
  ConnectionRateLimiterTokensPerInterval int
  ConnectionRateLimiterInterval          int
  ConnectionRateLimiterMaxTokens         int
}
```

**Empty Filter**: `{}` (全イベント取得)  
**Complex Filter**: 複数の `authors`, `kinds`, `#e`, `#p` など

```go
if !privateRelayLimits.AllowEmptyFilters {
  privateRelay.RejectFilter = append(privateRelay.RejectFilter, 
    policies.NoEmptyFilters)
}

if !privateRelayLimits.AllowComplexFilters {
  privateRelay.RejectFilter = append(privateRelay.RejectFilter, 
    policies.NoComplexFilters)
}
```

### カスタマイズ

**環境変数例**:

```bash
# Private Relay
PRIVATE_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL=50
PRIVATE_RELAY_EVENT_IP_LIMITER_INTERVAL=1
PRIVATE_RELAY_EVENT_IP_LIMITER_MAX_TOKENS=100
PRIVATE_RELAY_ALLOW_EMPTY_FILTERS=true
PRIVATE_RELAY_ALLOW_COMPLEX_FILTERS=true
PRIVATE_RELAY_CONNECTION_RATE_LIMITER_TOKENS_PER_INTERVAL=3
PRIVATE_RELAY_CONNECTION_RATE_LIMITER_INTERVAL=5
PRIVATE_RELAY_CONNECTION_RATE_LIMITER_MAX_TOKENS=9

# Chat Relay
CHAT_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL=50
CHAT_RELAY_EVENT_IP_LIMITER_INTERVAL=1
CHAT_RELAY_EVENT_IP_LIMITER_MAX_TOKENS=100
CHAT_RELAY_ALLOW_EMPTY_FILTERS=false
CHAT_RELAY_ALLOW_COMPLEX_FILTERS=false
...
```

---

## 💾 データベース

### サポート

Haven は 2つのデータベースエンジンをサポートします:

1. **LMDB** (Lightning Memory-Mapped Database) - デフォルト
2. **BadgerDB** - 代替オプション

### アーキテクチャ

```
┌──────────────────────────────────────────────────┐
│            Database Architecture                 │
└──────────────────────────────────────────────────┘

DBBackend Interface
    │
    ├─ Init() error
    ├─ Close()
    ├─ CountEvents(ctx, filter) (int64, error)
    ├─ DeleteEvent(ctx, evt) error
    ├─ QueryEvents(ctx, filter) (chan *nostr.Event, error)
    ├─ SaveEvent(ctx, evt) error
    ├─ ReplaceEvent(ctx, evt) error
    └─ Serial() []byte
         │
         ├─────────────────┬─────────────────┐
         │                 │                 │
    ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
    │  LMDB   │      │ BadgerDB│      │ (Future)│
    │ Backend │      │ Backend │      │         │
    └─────────┘      └─────────┘      └─────────┘
```

### 実装

**ファイル**: `init.go:42-71`

```go
type DBBackend interface {
  Init() error
  Close()
  CountEvents(ctx context.Context, filter nostr.Filter) (int64, error)
  DeleteEvent(ctx context.Context, evt *nostr.Event) error
  QueryEvents(ctx context.Context, filter nostr.Filter) (chan *nostr.Event, error)
  SaveEvent(ctx context.Context, evt *nostr.Event) error
  ReplaceEvent(ctx context.Context, evt *nostr.Event) error
  Serial() []byte
}

func newDBBackend(path string) DBBackend {
  switch config.DBEngine {
  case "lmdb":
    return newLMDBBackend(path)
  case "badger":
    return &badger.BadgerBackend{
      Path: path,
    }
  default:
    return newLMDBBackend(path)
  }
}

func newLMDBBackend(path string) *lmdb.LMDBBackend {
  return &lmdb.LMDBBackend{
    Path:    path,
    MapSize: config.LmdbMapSize,
  }
}
```

### データベース初期化

```go
func initRelays() {
  if err := privateDB.Init(); err != nil {
    panic(err)
  }
  
  if err := chatDB.Init(); err != nil {
    panic(err)
  }
  
  if err := outboxDB.Init(); err != nil {
    panic(err)
  }
  
  if err := inboxDB.Init(); err != nil {
    panic(err)
  }
  
  if err := blossomDB.Init(); err != nil {
    panic(err)
  }
  
  // ... relay configuration ...
}
```

### LMDB vs BadgerDB

| 特徴 | LMDB | BadgerDB |
|------|------|----------|
| **パフォーマンス** | ⚡ Very Fast (NVMe) | ⚡ Fast |
| **メモリ使用** | 🟢 Low | 🟡 Medium |
| **ディスク使用** | 🟢 Efficient | 🟡 More overhead |
| **Map Size** | ⚠️ 要設定 | ✅ Auto-expand |
| **プラットフォーム** | Linux, macOS, Windows | All |
| **マイグレーション** | ⚠️ Breaking changes | ⚠️ Breaking changes |

### 設定項目

| 項目 | 環境変数 | デフォルト値 | 説明 |
|------|---------|------------|------|
| **DB Engine** | `DB_ENGINE` | `lmdb` | `lmdb` or `badger` |
| **LMDB Map Size** | `LMDB_MAPSIZE` | `0` (auto) | LMDB のマップサイズ (bytes) |

### LMDB Map Size

**重要**: LMDB は事前に最大データベースサイズを設定する必要があります。

```bash
# デフォルト: 273 GB (自動計算)
LMDB_MAPSIZE=0

# カスタム: 100 GB
LMDB_MAPSIZE=107374182400

# Windows/macOS: 空きディスク容量より小さい値を設定
LMDB_MAPSIZE=10737418240  # 10 GB
```

**ガイドライン**:
- Linux: デフォルト (0) で OK
- macOS: 空きディスク容量の 50% 以下
- Windows: 空きディスク容量の 50% 以下
- 大規模データベース: 必要に応じて増加

---

## ⚙️ 設定項目

### 完全な設定項目リスト

#### 基本設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Owner Npub** | `OWNER_NPUB` | - | ✅ | リレーオーナーの npub |
| **Relay URL** | `RELAY_URL` | - | ✅ | リレーの URL (Tor: .onion) |
| **Relay Port** | `RELAY_PORT` | `3355` | - | リレーのポート |
| **Relay Bind Address** | `RELAY_BIND_ADDRESS` | `0.0.0.0` | - | バインドアドレス |
| **Log Level** | `HAVEN_LOG_LEVEL` | `INFO` | - | `DEBUG`, `INFO`, `WARN`, `ERROR` |

#### データベース設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **DB Engine** | `DB_ENGINE` | `lmdb` | - | `lmdb` or `badger` |
| **LMDB Map Size** | `LMDB_MAPSIZE` | `0` | - | LMDB マップサイズ (bytes) |

#### Blossom 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Blossom Path** | `BLOSSOM_PATH` | `blossom` | - | メディアファイル保存パス |

#### Private Relay 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Name** | `PRIVATE_RELAY_NAME` | - | ✅ | リレー名 |
| **Npub** | `PRIVATE_RELAY_NPUB` | - | ✅ | リレーの npub |
| **Description** | `PRIVATE_RELAY_DESCRIPTION` | - | ✅ | リレーの説明 |
| **Icon** | `PRIVATE_RELAY_ICON` | - | - | リレーのアイコン URL |

#### Chat Relay 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Name** | `CHAT_RELAY_NAME` | - | ✅ | リレー名 |
| **Npub** | `CHAT_RELAY_NPUB` | - | ✅ | リレーの npub |
| **Description** | `CHAT_RELAY_DESCRIPTION` | - | ✅ | リレーの説明 |
| **Icon** | `CHAT_RELAY_ICON` | - | - | リレーのアイコン URL |
| **WoT Depth** | `CHAT_RELAY_WOT_DEPTH` | `0` | - | WoT 深さ (0=direct, 1=1-hop) |
| **WoT Refresh Interval** | `CHAT_RELAY_WOT_REFRESH_INTERVAL_HOURS` | `0` | - | WoT 更新間隔 (時間) |
| **Minimum Followers** | `CHAT_RELAY_MINIMUM_FOLLOWERS` | `0` | - | 最小フォロワー数 |

#### Inbox Relay 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Name** | `INBOX_RELAY_NAME` | - | ✅ | リレー名 |
| **Npub** | `INBOX_RELAY_NPUB` | - | ✅ | リレーの npub |
| **Description** | `INBOX_RELAY_DESCRIPTION` | - | ✅ | リレーの説明 |
| **Icon** | `INBOX_RELAY_ICON` | - | - | リレーのアイコン URL |
| **Pull Interval** | `INBOX_PULL_INTERVAL_SECONDS` | `3600` | - | Inbox 同期間隔 (秒) |

#### Outbox Relay 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Name** | `OUTBOX_RELAY_NAME` | - | ✅ | リレー名 |
| **Npub** | `OUTBOX_RELAY_NPUB` | - | ✅ | リレーの npub |
| **Description** | `OUTBOX_RELAY_DESCRIPTION` | - | ✅ | リレーの説明 |
| **Icon** | `OUTBOX_RELAY_ICON` | - | - | リレーのアイコン URL |

#### Import 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Start Date** | `IMPORT_START_DATE` | - | - | インポート開始日 (YYYY-MM-DD) |
| **Owner Notes Timeout** | `IMPORT_OWNER_NOTES_FETCH_TIMEOUT_SECONDS` | `30` | - | Owner ノート取得タイムアウト |
| **Tagged Notes Timeout** | `IMPORT_TAGGED_NOTES_FETCH_TIMEOUT_SECONDS` | `120` | - | Tagged ノート取得タイムアウト |
| **Query Interval** | `IMPORT_QUERY_INTERVAL_SECONDS` | `360000` | - | 定期クエリ間隔 |
| **Seed Relays File** | `IMPORT_SEED_RELAYS_FILE` | - | - | インポート元リレーリスト |

#### Blastr 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Blastr Relays File** | `BLASTR_RELAYS_FILE` | - | - | Blastr リレーリスト |

#### WoT 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Fetch Timeout** | `WOT_FETCH_TIMEOUT_SECONDS` | `30` | - | WoT フェッチタイムアウト |

#### Backup 設定

| 項目 | 環境変数 | デフォルト値 | 必須 | 説明 |
|------|---------|------------|------|------|
| **Backup Provider** | `BACKUP_PROVIDER` | `none` | - | `s3`, `aws`, `gcp`, `none` |
| **Backup Interval** | `BACKUP_INTERVAL_HOURS` | `24` | - | バックアップ間隔 (時間) |
| **S3 Access Key** | `S3_ACCESS_KEY_ID` | - | - | S3 アクセスキー |
| **S3 Secret Key** | `S3_SECRET_KEY` | - | - | S3 シークレットキー |
| **S3 Endpoint** | `S3_ENDPOINT` | - | - | S3 エンドポイント |
| **S3 Region** | `S3_REGION` | - | - | S3 リージョン |
| **S3 Bucket** | `S3_BUCKET_NAME` | - | - | S3 バケット名 |

#### Rate Limiting 設定 (各リレーごと)

**Private Relay**:
- `PRIVATE_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL` (default: `50`)
- `PRIVATE_RELAY_EVENT_IP_LIMITER_INTERVAL` (default: `1`)
- `PRIVATE_RELAY_EVENT_IP_LIMITER_MAX_TOKENS` (default: `100`)
- `PRIVATE_RELAY_ALLOW_EMPTY_FILTERS` (default: `true`)
- `PRIVATE_RELAY_ALLOW_COMPLEX_FILTERS` (default: `true`)
- `PRIVATE_RELAY_CONNECTION_RATE_LIMITER_TOKENS_PER_INTERVAL` (default: `3`)
- `PRIVATE_RELAY_CONNECTION_RATE_LIMITER_INTERVAL` (default: `5`)
- `PRIVATE_RELAY_CONNECTION_RATE_LIMITER_MAX_TOKENS` (default: `9`)

**Chat Relay**:
- `CHAT_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL` (default: `50`)
- `CHAT_RELAY_EVENT_IP_LIMITER_INTERVAL` (default: `1`)
- `CHAT_RELAY_EVENT_IP_LIMITER_MAX_TOKENS` (default: `100`)
- `CHAT_RELAY_ALLOW_EMPTY_FILTERS` (default: `false`)
- `CHAT_RELAY_ALLOW_COMPLEX_FILTERS` (default: `false`)
- `CHAT_RELAY_CONNECTION_RATE_LIMITER_TOKENS_PER_INTERVAL` (default: `3`)
- `CHAT_RELAY_CONNECTION_RATE_LIMITER_INTERVAL` (default: `3`)
- `CHAT_RELAY_CONNECTION_RATE_LIMITER_MAX_TOKENS` (default: `9`)

**Inbox Relay**:
- `INBOX_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL` (default: `10`)
- `INBOX_RELAY_EVENT_IP_LIMITER_INTERVAL` (default: `1`)
- `INBOX_RELAY_EVENT_IP_LIMITER_MAX_TOKENS` (default: `20`)
- `INBOX_RELAY_ALLOW_EMPTY_FILTERS` (default: `false`)
- `INBOX_RELAY_ALLOW_COMPLEX_FILTERS` (default: `false`)
- `INBOX_RELAY_CONNECTION_RATE_LIMITER_TOKENS_PER_INTERVAL` (default: `3`)
- `INBOX_RELAY_CONNECTION_RATE_LIMITER_INTERVAL` (default: `1`)
- `INBOX_RELAY_CONNECTION_RATE_LIMITER_MAX_TOKENS` (default: `9`)

**Outbox Relay**:
- `OUTBOX_RELAY_EVENT_IP_LIMITER_TOKENS_PER_INTERVAL` (default: `10`)
- `OUTBOX_RELAY_EVENT_IP_LIMITER_INTERVAL` (default: `60`)
- `OUTBOX_RELAY_EVENT_IP_LIMITER_MAX_TOKENS` (default: `100`)
- `OUTBOX_RELAY_ALLOW_EMPTY_FILTERS` (default: `false`)
- `OUTBOX_RELAY_ALLOW_COMPLEX_FILTERS` (default: `false`)
- `OUTBOX_RELAY_CONNECTION_RATE_LIMITER_TOKENS_PER_INTERVAL` (default: `3`)
- `OUTBOX_RELAY_CONNECTION_RATE_LIMITER_INTERVAL` (default: `1`)
- `OUTBOX_RELAY_CONNECTION_RATE_LIMITER_MAX_TOKENS` (default: `9`)

---

## 🎯 Start9 統合状況

### 現在の実装状況 (v1.1.5)

| 機能 | 実装状況 | Start9 対応 | 備考 |
|------|---------|-----------|------|
| **Private Relay** | ✅ 完了 | ✅ 完全対応 | NIP-42 Auth 完全動作 |
| **Chat Relay** | ✅ 完了 | ✅ 完全対応 | WoT + Auth 完全動作 |
| **Inbox Relay** | ✅ 完了 | ✅ 完全対応 | 自動同期動作確認済み |
| **Outbox Relay** | ✅ 完了 | ✅ 完全対応 | Blastr 統合済み |
| **Blossom Server** | ✅ 完了 | ✅ 完全対応 | Amethyst で動作確認 |
| **Web of Trust** | ✅ 完了 | ✅ 完全対応 | 自動更新動作 |
| **Import (Owner)** | ✅ 完了 | ✅ 完全対応 | Action 実装済み |
| **Import (Tagged)** | ✅ 完了 | ✅ 完全対応 | Action 実装済み |
| **Import (Continuous)** | ✅ 完了 | ✅ 完全対応 | バックグラウンド動作 |
| **Blastr** | ✅ 完了 | ✅ 完全対応 | IPv6 + Tor 対応 |
| **Cloud Backup** | ✅ 完了 | ⚠️ 無効化 | Start9 内蔵バックアップ使用 |
| **Tor Integration** | ✅ 完了 | ✅ 完全対応 | .onion 固定化済み |
| **Config UI** | ✅ 完了 | ✅ 完全対応 | 全設定項目対応 |
| **Health Check** | ✅ 完了 | ✅ 完全対応 | Web interface チェック |
| **Properties** | ✅ 完了 | ✅ 完全対応 | .onion address 表示 |

### Start9 固有の実装

#### 1. Tor 統合

**実装**: `docker_entrypoint.sh`, `torrc`

```bash
# Start Tor
echo "Starting Tor..."
/usr/local/bin/tor -f /etc/tor/torrc &

# Wait for Tor to generate .onion address
while [ ! -f /data/tor/haven/hostname ]; do
    echo "Waiting for Tor hidden service to initialize..."
    sleep 1
done

ONION_ADDRESS=$(cat /data/tor/haven/hostname)
echo "Tor hidden service: $ONION_ADDRESS"
```

**Tor 設定** (`torrc`):
```
HiddenServiceDir /data/tor/haven/
HiddenServicePort 80 127.0.0.1:3355
ClientUseIPv6 1
ClientPreferIPv6ORPort 1
IPv6Exit 1
```

#### 2. Config Management

**Get Config**: `scripts/procedures/getConfig.ts`
**Set Config**: `scripts/procedures/setConfig.ts`

Start9 UI と Haven の `.env` 設定を双方向同期。

#### 3. Import Action

**実装**: `docker_entrypoint.sh`

```bash
if [ "$1" = "import-notes" ]; then
    echo "Setting up import request..."
    touch /data/.import-request
    echo "Import will run on next Haven restart."
    exit 0
fi

# Check if import is requested
if [ -f /data/.import-request ]; then
    echo "Import requested, starting Haven in import mode..."
    rm /data/.import-request
    
    cd /haven
    ./haven --import
    
    echo "Import complete, restarting in normal mode..."
fi
```

#### 4. Properties Display

**実装**: `scripts/procedures/properties.ts`

```typescript
export const properties: T.ExpectedExports.properties = async (effects) => {
  const onionAddress = await effects.readFile({
    path: '/data/tor/haven/hostname',
    volumeId: 'main',
  })

  return {
    'Haven Relay': {
      type: 'string',
      value: `${onionAddress.trim()}`,
      description: 'Your private Nostr relay .onion address',
      copyable: true,
      qr: true,
      masked: false,
    },
    // ... more properties
  }
}
```

---

## 🚀 今後の実装計画

### 近日実装予定

#### 1. NIP-50 (Search) サポート

**概要**: Haven にテキスト検索機能を追加

```
┌──────────────────────────────────────────────────┐
│         NIP-50 Search Architecture               │
└──────────────────────────────────────────────────┘

Client
  │
  │ REQ ["search", {"search": "bitcoin", ...}]
  ▼
┌─────────────────┐
│ Search Handler  │
└────────┬────────┘
         │
         ▼
    ┌──────────┐
    │ FTS Index│
    │ (SQLite) │
    └──────────┘
         │
         ▼
    ┌──────────┐
    │ Results  │
    └──────────┘
```

**実装予定**:
- Full-text search index (SQLite FTS5)
- Private/Chat/Inbox/Outbox 全リレーで検索可能
- 検索クエリ: `{"search": "keyword", "kinds": [1], ...}`

**優先度**: 🔴 High

#### 2. GUI Dashboard (Start9 LAUNCH UI)

**概要**: Start9 の LAUNCH UI ボタンでアクセスできる Web ダッシュボード

**機能**:
- リレー統計 (イベント数、接続数)
- WoT 統計 (メンバー数、ネットワークサイズ)
- Blossom 統計 (ファイル数、ストレージ使用量)
- Import 履歴
- ログビューアー

**優先度**: 🟡 Medium

#### 3. WoT 自動更新

**概要**: 定期的に WoT を更新

**現状**: 手動または再起動時のみ  
**実装予定**: 設定した間隔で自動更新 (`CHAT_RELAY_WOT_REFRESH_INTERVAL_HOURS`)

**優先度**: 🟢 Low (設定は既に存在)

#### 4. Database Migration Tool

**概要**: LMDB ↔ BadgerDB 間の移行ツール

**実装予定**:
- コマンドラインツール: `./haven --migrate-db lmdb badger`
- Start9 Action として統合

**優先度**: 🟢 Low

#### 5. Multi-User Support

**概要**: 複数ユーザーの Haven インスタンスをサポート

**実装予定**:
- ユーザーごとの設定
- ユーザーごとの WoT
- 共有 Inbox (オプション)

**優先度**: ⚪ Future

---

## 📚 参考資料

### Nostr NIPs

- [NIP-01: Basic protocol flow](https://github.com/nostr-protocol/nips/blob/master/01.md)
- [NIP-04: Encrypted Direct Message](https://github.com/nostr-protocol/nips/blob/master/04.md) (Deprecated)
- [NIP-42: Authentication](https://github.com/nostr-protocol/nips/blob/master/42.md)
- [NIP-50: Search Capability](https://github.com/nostr-protocol/nips/blob/master/50.md) (未実装)
- [NIP-59: Gift Wrap](https://github.com/nostr-protocol/nips/blob/master/59.md)
- [NIP-65: Relay List Metadata](https://github.com/nostr-protocol/nips/blob/master/65.md)
- [NIP-96: HTTP File Storage Integration](https://github.com/nostr-protocol/nips/blob/master/96.md)
- [NIP-98: HTTP Auth](https://github.com/nostr-protocol/nips/blob/master/98.md)

### Blossom Specs

- [BUD-01: Blossom Drive Upload](https://github.com/hzrd149/blossom/blob/master/buds/01.md)
- [BUD-02: Blob Descriptor Event](https://github.com/hzrd149/blossom/blob/master/buds/02.md)

### Haven リポジトリ

- [Haven Main Repo](https://github.com/bitvora/haven)
- [Haven Start9 Wrapper](https://github.com/bitvora/haven-start9-wrapper)

### ライブラリ

- [Khatru](https://github.com/fiatjaf/khatru) - Nostr relay framework
- [go-nostr](https://github.com/nbd-wtf/go-nostr) - Nostr client library
- [eventstore](https://github.com/fiatjaf/eventstore) - Database backends

---

## 📝 更新履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-12-27 | 1.0.0 | 初版作成 |

---

**Haven** - High Availability Vault for Events on Nostr  
Built with ❤️ by the Nostr community

