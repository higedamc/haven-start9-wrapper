# Nostr Event Size Calculation

## 概要
Nostrイベントのサイズ計算と、大きなcontentフィールドが全体サイズに与える影響を分析します。

## Nostrイベントの構造

```json
{
  "id": "32文字のイベントID（64文字hex）",
  "pubkey": "32バイトの公開鍵（64文字hex）",
  "created_at": 1234567890,
  "kind": 1,
  "tags": [],
  "content": "ここにコンテンツが入る",
  "sig": "64バイトの署名（128文字hex）"
}
```

### 固定オーバーヘッド

| フィールド | サイズ |
|-----------|--------|
| id | 64文字（64バイト） |
| pubkey | 64文字（64バイト） |
| created_at | 10-11文字（~11バイト） |
| kind | 1-5文字（~5バイト） |
| sig | 128文字（128バイト） |
| JSON構造（括弧、カンマ、引用符など） | ~50バイト |
| **固定オーバーヘッド合計** | **~322バイト** |

### tagsフィールド

- 空の場合: `"tags": []` = 10バイト
- タグがある場合: 各タグで20-100バイト程度追加

## UTF-8エンコーディングのバイト数

| 文字種 | バイト/文字 | 例 |
|--------|------------|-----|
| ASCII（英数字、記号） | 1バイト | `Hello, World!` |
| 日本語（ひらがな・カタカナ） | 3バイト | `こんにちは` |
| 日本語（漢字） | 3バイト | `日本語` |
| 絵文字 | 3-4バイト | `😀🎉` |
| CJK文字（中国語、韓国語） | 3バイト | `你好`, `안녕` |

## 10万文字のイベントサイズ計算

### ケース1: 全て英数字（最小）

```
content文字数: 100,000文字
contentバイト数: 100,000バイト × 1 = 100,000バイト
固定オーバーヘッド: 322バイト
tags（空）: 10バイト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合計: 100,332バイト ≈ 98.0 KB
```

### ケース2: 全て日本語（最大）

```
content文字数: 100,000文字
contentバイト数: 100,000文字 × 3 = 300,000バイト
固定オーバーヘッド: 322バイト
tags（空）: 10バイト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合計: 300,332バイト ≈ 293.3 KB
```

### ケース3: 日英混在（実際的）

```
英語50%: 50,000文字 × 1バイト = 50,000バイト
日本語50%: 50,000文字 × 3バイト = 150,000バイト
contentバイト数合計: 200,000バイト
固定オーバーヘッド: 322バイト
tags（空）: 10バイト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合計: 200,332バイト ≈ 195.6 KB
```

### ケース4: 絵文字多用

```
テキスト80,000文字 × 2バイト平均 = 160,000バイト
絵文字20,000文字 × 4バイト = 80,000バイト
contentバイト数合計: 240,000バイト
固定オーバーヘッド: 322バイト
tags（空）: 10バイト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
合計: 240,332バイト ≈ 234.7 KB
```

## 実際のNostrイベントサイズ例

### 現在のエラー例（65,628バイト）

```
65,628バイト ÷ 3 = 約21,876文字（全て日本語の場合）
65,628バイト ÷ 1 = 約65,628文字（全て英語の場合）
実際的には: 約30,000-40,000文字の日英混在コンテンツ
```

## Nostr NIPsでの推奨値

### NIP-1946提案（まだマージされていない）

```json
{
  "limitation": {
    "max_message_length": 16384,
    "max_content_length": 8192
  }
}
```

- `max_message_length`: WebSocketメッセージ全体の最大バイト数（16KB）
- `max_content_length`: contentフィールドの最大**文字数**（8,192文字）

### 主要リレーの実際の制限

| リレー | 制限 | 備考 |
|--------|------|------|
| damus.io | 64KB | 一般的な制限 |
| nos.lol | 128KB | やや寛容 |
| nostr.wine | 256KB | プレミアム |
| relay.nostr.band | 512KB | 大きめ |

## Nostrでの長文コンテンツの扱い

### Kind別の想定サイズ

| Kind | 用途 | 一般的なサイズ | 最大想定 |
|------|------|---------------|---------|
| 1 | 短文投稿（Twitter風） | 1-10KB | 64KB |
| 30023 | 長文記事（ブログ） | 10-100KB | **500KB-1MB** |
| 30024 | ドラフト記事 | 10-100KB | **500KB-1MB** |
| 4 | 暗号化DM | 1-10KB | 64KB |
| 1063 | ブックレビュー | 5-50KB | 256KB |

### ⚠️ 重要な考察

**Kind 30023（長文記事）では10万文字は現実的**

- ブログ記事やドキュメント
- 技術記事
- 小説や創作物

**問題：Havenは現在Kind別の制限がない**

```go
// 現在の実装
privateRelay.RejectEvent = append(privateRelay.RejectEvent,
    policies.RejectEventsWithBase64Media,
    policies.EventIPRateLimiter(...),
)

// ❌ Kind別のサイズ制限がない
// ❌ 全てのKindで同じ64KB制限（デフォルト）
```

## Havenへの推奨対応

### 1. リレー別の基本制限

```go
// Private Relay: 最も寛容（個人用）
MaxEventSize: 512KB (524,288バイト)

// Chat Relay: 標準（DM用）
MaxEventSize: 128KB (131,072バイト)

// Outbox/Inbox: 柔軟（公開投稿）
MaxEventSize: 256KB (262,144バイト)
```

### 2. Kind別の特別扱い（推奨）

```go
// 長文系Kind
case 30023, 30024: // 長文記事、ドラフト
    maxSize = 1048576 // 1MB

// ブログ・レビュー系
case 1063: // ブックレビュー
    maxSize = 524288 // 512KB

// 通常投稿
case 1: // 短文投稿
    maxSize = 131072 // 128KB

// DM
case 4: // 暗号化DM
    maxSize = 131072 // 128KB

// デフォルト
default:
    maxSize = 262144 // 256KB
```

### 3. 設定例（manifest.yaml）

```yaml
max-event-size-private:
  type: number
  name: Max Event Size - Private Relay
  description: |
    Maximum event size in bytes for Private Relay.
    Note: Long-form content (kind 30023/30024) may require 500KB-1MB.
  nullable: false
  default: 524288  # 512KB
  range: "[65536,2097152]"  # 64KB - 2MB
  units: bytes

enable-kind-specific-limits:
  type: boolean
  name: Enable Kind-Specific Size Limits
  description: |
    Allow larger events for long-form content kinds (30023, 30024).
    If enabled, long-form articles can be up to 1MB.
  nullable: false
  default: true
```

## 実装例

```go
// limits.go
type RelayLimits struct {
    MaxEventSize              int
    MaxLongFormContentSize    int  // Kind 30023, 30024用
    EnableKindSpecificLimits  bool
}

// init.go
func getMaxEventSizeForKind(kind int, limits RelayLimits) int {
    if !limits.EnableKindSpecificLimits {
        return limits.MaxEventSize
    }
    
    switch kind {
    case 30023, 30024: // Long-form content
        return limits.MaxLongFormContentSize
    default:
        return limits.MaxEventSize
    }
}

// RejectEvent hookに追加
relay.RejectEvent = append(relay.RejectEvent, func(ctx context.Context, event *nostr.Event) (bool, string) {
    maxSize := getMaxEventSizeForKind(event.Kind, privateRelayLimits)
    eventSize := len(event.Content) + 322 // オーバーヘッド
    
    if eventSize > maxSize {
        return true, fmt.Sprintf("event too large: %d bytes, max is %d", eventSize, maxSize)
    }
    return false, ""
})
```

## まとめ

### 10万文字のイベントサイズ

| シナリオ | サイズ |
|---------|--------|
| 全て英語 | **~98 KB** |
| 日英混在（実際的） | **~196 KB** |
| 全て日本語 | **~293 KB** |
| 絵文字多用 | **~235 KB** |

### 推奨事項

1. ✅ **Private Relay**: 512KB（長文記事対応）
2. ✅ **Kind別制限**: 30023/30024は1MBまで許可
3. ✅ **設定可能**: Start9 UIから調整可能に
4. ✅ **監視**: 大きなイベントをログで追跡

### セキュリティ考慮

- 個人リレー（認証必須）なのでDoSリスクは低い
- ディスク容量の監視を推奨
- 必要に応じてイベント削除機能を実装

---

**作成日**: 2025-01-07
**Haven Version**: 1.2.3

