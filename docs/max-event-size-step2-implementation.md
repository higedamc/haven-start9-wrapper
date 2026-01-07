# Max Event Size Implementation (Step 2) - Kind-Specific Limits

## 概要

Haven v1.2.4でのKind別イベントサイズ制限の実装。長文記事（Kind 30023, 30024など）を最大1MBまで対応可能にします。

## 背景

ステップ1で基本制限を128KBに引き上げましたが、Nostrの長文コンテンツプロトコル（NIP-23）には対応しきれていませんでした。

### 問題

| コンテンツ | 文字数 | 必要なサイズ | ステップ1の制限 | 対応状況 |
|-----------|--------|-------------|----------------|---------|
| 通常投稿 | ~10,000文字 | ~30KB | 128KB | ✅ OK |
| 長文記事（英語） | 100,000文字 | ~100KB | 128KB | ✅ OK |
| 長文記事（日本語） | 100,000文字 | ~300KB | 128KB | ❌ NG |
| 超長文記事 | 200,000文字 | ~600KB | 128KB | ❌ NG |

## ステップ2の実装内容

### 🎯 対応するNostr Kind

| Kind | 用途 | 最大サイズ | 理由 |
|------|------|-----------|------|
| **30023** | Long-form Content (記事) | 1MB | NIP-23の標準 |
| **30024** | Long-form Draft (下書き) | 1MB | 記事と同様 |
| **30040** | Long-form Review | 1MB | 長いレビュー記事 |
| **30041** | Long-form Annotation | 1MB | 詳細な注釈 |
| **その他** | 通常投稿・DM等 | 128KB | デフォルト |

### 🔧 新機能

1. **Kind-Specific Limits の有効/無効切り替え**
   - デフォルト: 有効（Private, Outbox, Inbox）
   - Chat Relay: 無効（長文不要）

2. **Long-Form Content Size の設定**
   - デフォルト: 1MB (1,048,576バイト)
   - 範囲: 128KB - 4MB
   - Start9 UIから調整可能

3. **エラーメッセージの改善**
   ```
   旧: error: content is too large: 300000, max is 131072
   新: error: content is too large: 300000, max is 1048576 (kind 30023)
   ```
   Kind番号も表示されるため、デバッグが容易

## 変更されたファイル

### 1. `haven/limits.go`

各リレーの構造体に2つのフィールドを追加：

```go
type PrivateRelayLimits struct {
    // ... 既存のフィールド ...
    MaxLongFormContentSize    int   // 長文コンテンツの最大サイズ
    EnableKindSpecificLimits  bool  // Kind別制限の有効/無効
}
```

デフォルト値：

```go
privateRelayLimits = PrivateRelayLimits{
    // ...
    MaxLongFormContentSize:       getEnvInt("PRIVATE_RELAY_MAX_LONG_FORM_SIZE", 1048576),  // 1MB
    EnableKindSpecificLimits:     getEnvBool("PRIVATE_RELAY_ENABLE_KIND_SPECIFIC_LIMITS", true),
}
```

### 2. `haven/init.go`

Kind別サイズ計算のヘルパー関数を追加：

```go
func getMaxEventSizeForKind(kind int, maxEventSize int, maxLongFormSize int, enableKindSpecific bool) int {
    if !enableKindSpecific {
        return maxEventSize
    }

    switch kind {
    case 30023, 30024: // Long-form content (NIP-23)
        return maxLongFormSize
    case 30040, 30041: // Long-form drafts and reviews
        return maxLongFormSize
    default:
        return maxEventSize
    }
}
```

各リレーのRejectEventで使用：

```go
func(ctx context.Context, event *nostr.Event) (bool, string) {
    eventJSON, _ := event.MarshalJSON()
    eventSize := len(eventJSON)
    maxSize := getMaxEventSizeForKind(
        event.Kind,
        privateRelayLimits.MaxEventSize,
        privateRelayLimits.MaxLongFormContentSize,
        privateRelayLimits.EnableKindSpecificLimits,
    )
    if eventSize > maxSize {
        return true, fmt.Sprintf("error: content is too large: %d, max is %d (kind %d)", 
            eventSize, maxSize, event.Kind)
    }
    return false, ""
}
```

### 3. `scripts/procedures/getConfig.ts`

Start9 UIに2つの設定項目を追加：

```typescript
"enable-kind-specific-limits": {
  "type": "boolean",
  "name": "Enable Kind-Specific Size Limits",
  "description": "Allow larger events for long-form content kinds...",
  "default": true,
},
"max-long-form-content-size": {
  "type": "number",
  "name": "Max Long-Form Content Size (KB)",
  "description": "Maximum event size for long-form content...",
  "default": 1024,  // 1MB
  "range": "[128,4096]",
}
```

### 4. `scripts/procedures/setConfig.sh`

KB→バイト変換を追加：

```bash
export ENABLE_KIND_SPECIFIC_LIMITS="$(echo "$CONFIG" | yq '.enable-kind-specific-limits // "true"')"
LONG_FORM_MAX_KB="$(echo "$CONFIG" | yq '.max-long-form-content-size // "1024"')"
export MAX_LONG_FORM_CONTENT_SIZE="$((LONG_FORM_MAX_KB * 1024))"
```

### 5. `docker_entrypoint.sh`

環境変数の設定とリレー別の適用：

```bash
# Kind-Specific Event Size Limits
PRIVATE_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=${ENABLE_KIND_SPECIFIC_LIMITS:-true}
CHAT_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=false  # Chatは不要
OUTBOX_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=${ENABLE_KIND_SPECIFIC_LIMITS:-true}
INBOX_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=${ENABLE_KIND_SPECIFIC_LIMITS:-true}

PRIVATE_RELAY_MAX_LONG_FORM_SIZE=${MAX_LONG_FORM_CONTENT_SIZE:-1048576}
CHAT_RELAY_MAX_LONG_FORM_SIZE=${MAX_LONG_FORM_CONTENT_SIZE:-1048576}
OUTBOX_RELAY_MAX_LONG_FORM_SIZE=${MAX_LONG_FORM_CONTENT_SIZE:-1048576}
INBOX_RELAY_MAX_LONG_FORM_SIZE=${MAX_LONG_FORM_CONTENT_SIZE:-1048576}
```

## デフォルト設定

| リレー | 通常イベント | 長文コンテンツ | Kind別制限 |
|--------|------------|--------------|-----------|
| **Private** | 128KB | 1MB | ✅ 有効 |
| **Chat** | 128KB | 1MB | ❌ 無効 |
| **Outbox** | 128KB | 1MB | ✅ 有効 |
| **Inbox** | 128KB | 1MB | ✅ 有効 |

### Chat RelayでKind別制限を無効にする理由

- DMやチャットメッセージに長文記事は不要
- シンプルな制限の方がパフォーマンスが良い
- セキュリティ的にも制限が厳しい方が安全

## 対応可能なコンテンツサイズ

### ステップ2での対応範囲

| シナリオ | 文字数 | サイズ | Kind | 対応状況 |
|---------|--------|--------|------|---------|
| 短文投稿 | 10,000 | ~30KB | 1 | ✅ OK (128KB) |
| 中文投稿 | 50,000 | ~150KB | 1 | ✅ OK (128KB) |
| 長文記事（英語） | 100,000 | ~100KB | 30023 | ✅ OK (1MB) |
| 長文記事（日本語） | 100,000 | ~300KB | 30023 | ✅ OK (1MB) |
| 超長文記事（日本語） | 200,000 | ~600KB | 30023 | ✅ OK (1MB) |
| 大規模記事（日本語） | 300,000 | ~900KB | 30023 | ✅ OK (1MB) |
| 極大記事 | 350,000+ | 1MB+ | 30023 | ⚠️ 要設定変更 |

### 1MBで保存できるコンテンツ量

- **英語**: 約1,000,000文字
- **日本語**: 約330,000文字
- **日英混在**: 約500,000文字

→ 実用上、ほぼすべての長文記事に対応可能

## 動作例

### 例1: 通常の短文投稿（Kind 1）

```
イベントサイズ: 5KB
Kind: 1
制限: 128KB (通常イベント)
結果: ✅ 成功
```

### 例2: 日本語の長文記事（Kind 30023）

```
イベントサイズ: 300KB
Kind: 30023
制限: 1MB (長文コンテンツ)
結果: ✅ 成功
```

### 例3: Kind別制限を無効にした場合

```
イベントサイズ: 300KB
Kind: 30023
制限: 128KB (通常イベント - Kind別無効)
結果: ❌ エラー: content is too large: 300000, max is 131072 (kind 30023)
```

## Start9 UI での設定方法

### 1. Kind-Specific Limits を有効にする（推奨）

```
Services → Haven → Config
↓
☑ Enable Kind-Specific Size Limits (checked)
```

これにより、長文記事が自動的に1MBまで対応

### 2. Long-Form Content Sizeを変更

```
Max Long-Form Content Size (KB): 1024
↓
変更例: 2048 (2MB)
```

非常に長い記事や画像を多く含む記事の場合に増やす

### 3. 特定のリレーだけ制限を厳しくしたい場合

現在の実装では、環境変数を直接編集する必要があります：

```bash
# docker_entrypoint.shで設定
PRIVATE_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=false
```

将来的にUIから設定可能にする予定（ステップ3）

## エラーハンドリング

### エラーメッセージの改善

#### ステップ1のエラー

```
error: content is too large: 300000, max is 131072
```

→ Kindが不明で、どの制限に引っかかったのか不明確

#### ステップ2のエラー

```
error: content is too large: 300000, max is 1048576 (kind 30023)
```

→ Kind 30023（長文記事）であることが明確
→ 最大サイズも表示されるため、デバッグが容易

## トラブルシューティング

### Q1: 長文記事が保存できない

**確認事項:**
1. Kind-Specific Limits が有効か？
2. イベントのKindは 30023 または 30024 か？
3. イベントサイズが1MBを超えていないか？

**対処法:**
- UI で "Max Long-Form Content Size" を増やす（例: 2048KB）

### Q2: 通常投稿でエラーが出る

**原因:**
Kind 1（通常投稿）は128KB制限が適用されます。

**対処法:**
- 長文を投稿したい場合は、Nostrクライアントで Kind 30023（記事）として投稿
- または、"Private Relay - Max Event Size" を増やす

### Q3: Chat RelayでKind 30023が投稿できない

**原因:**
Chat Relayは Kind別制限が無効（CHAT_RELAY_ENABLE_KIND_SPECIFIC_LIMITS=false）

**理由:**
DMやチャットに長文記事は不要なため、意図的に制限を厳しくしています

**対処法:**
- Outbox Relay または Private Relay を使用

## パフォーマンスへの影響

### メモリ使用量

- イベントサイズチェックは軽量（JSON シリアライズのみ）
- メモリへの影響は最小限

### データベースサイズ

- 1MBのイベントを1,000件保存: 約1GB
- 個人リレーでは通常問題なし
- 必要に応じてディスク容量を監視

### ネットワーク帯域

- Tor経由のため、大きなイベントの同期に時間がかかる可能性
- しかし、長文記事の投稿頻度は低いため、実用上は問題なし

## セキュリティ考慮事項

### DoS攻撃対策

1. **認証必須**
   - Private, Chat, Inbox Relayは認証必須
   - 自分だけが大きなイベントを保存可能

2. **Outbox Relayの保護**
   - 自分のnpubで署名されたイベントのみ受け入れ
   - 第三者が大きなイベントを送信できない

3. **レート制限**
   - EventIPRateLimiterが引き続き機能
   - 短時間に大量のイベントを送信できない

### ディスク容量管理

- 定期的なバックアップを推奨
- Start9のディスク容量アラートを設定

## 次のステップ（Step 3 - 将来の拡張）

### UI からのリレー別設定

現在は全リレーで共通の設定ですが、将来的には：

```typescript
"private-relay-enable-kind-specific-limits": boolean,
"chat-relay-enable-kind-specific-limits": boolean,
"outbox-relay-enable-kind-specific-limits": boolean,
"inbox-relay-enable-kind-specific-limits": boolean,
```

各リレーごとに個別設定可能に。

### 追加のKind対応

```go
case 30078: // Application-specific data
case 31234: // Custom kind
```

必要に応じて他のKindも追加。

### 動的な制限調整

```go
// 時間帯によって制限を変える
if isBusinessHours() {
    return maxEventSize
} else {
    return maxLongFormSize
}
```

## まとめ

### ✅ ステップ2で実現したこと

1. **長文記事の完全サポート**
   - Kind 30023, 30024で最大1MB
   - 日本語で約33万文字に対応

2. **柔軟な設定**
   - Kind別制限の有効/無効切り替え
   - 長文サイズの調整（128KB～4MB）

3. **改善されたエラーメッセージ**
   - Kind番号の表示
   - 明確な制限値の表示

4. **パフォーマンスとセキュリティのバランス**
   - 通常投稿は128KB（軽量）
   - 長文記事のみ1MB（柔軟）

### 📊 ステップ1との比較

| 項目 | ステップ1 | ステップ2 |
|------|----------|----------|
| 通常投稿（Kind 1） | 128KB | 128KB |
| 長文記事（Kind 30023） | 128KB | **1MB** |
| 日本語記事の文字数 | ~42,000字 | **~330,000字** |
| Kind別制限 | ❌ なし | ✅ あり |
| 設定可能性 | 固定値のみ | リレー・Kind別 |

---

**変更履歴**

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-01-07 | v1.2.4 (予定) | Kind別サイズ制限の実装 |

