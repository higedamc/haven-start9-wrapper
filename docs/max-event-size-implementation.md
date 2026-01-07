# Max Event Size Implementation (Step 1)

## 概要

Haven v1.2.4で実装された、イベントサイズ制限の設定機能です。現在発生している「content is too large: 65628, max is 65535」エラーを解決するため、基本制限を64KBから128KBに引き上げました。

## 実装内容

### 変更されたファイル

#### 1. `haven/limits.go`

各リレーのLimit構造体に`MaxEventSize`フィールドを追加：

```go
type PrivateRelayLimits struct {
    // ... 既存のフィールド ...
    MaxEventSize  int  // 新規追加
}
```

デフォルト値を設定（全リレー共通で128KB = 131072バイト）：

```go
privateRelayLimits = PrivateRelayLimits{
    // ...
    MaxEventSize: getEnvInt("PRIVATE_RELAY_MAX_EVENT_SIZE", 131072), // 128KB
}
```

#### 2. `haven/init.go`

各リレーの`RejectEvent`にサイズチェックのポリシーを追加：

```go
privateRelay.RejectEvent = append(privateRelay.RejectEvent,
    // ... 既存のポリシー ...
    func(ctx context.Context, event *nostr.Event) (bool, string) {
        eventJSON, _ := event.MarshalJSON()
        eventSize := len(eventJSON)
        if eventSize > privateRelayLimits.MaxEventSize {
            return true, fmt.Sprintf("error: content is too large: %d, max is %d", 
                eventSize, privateRelayLimits.MaxEventSize)
        }
        return false, ""
    },
)
```

`fmt`パッケージのインポートを追加。

#### 3. `scripts/procedures/getConfig.ts`

Start9 UIに4つの設定項目を追加：

- **Private Relay - Max Event Size**: デフォルト 128KB (範囲: 64KB-2048KB)
- **Chat Relay - Max Event Size**: デフォルト 128KB (範囲: 64KB-512KB)
- **Outbox Relay - Max Event Size**: デフォルト 128KB (範囲: 64KB-1024KB)
- **Inbox Relay - Max Event Size**: デフォルト 128KB (範囲: 64KB-1024KB)

UIではKB単位で表示・設定されます。

#### 4. `scripts/procedures/setConfig.sh`

UI設定（KB）をバイト単位に変換して環境変数にexport：

```bash
PRIVATE_MAX_KB="$(echo "$CONFIG" | yq '.private-relay-max-event-size // "128"')"
export PRIVATE_RELAY_MAX_EVENT_SIZE="$((PRIVATE_MAX_KB * 1024))"
```

#### 5. `docker_entrypoint.sh`

`generate_env_file()`関数と`main()`関数の両方に、MaxEventSizeの設定を追加。

- KB→バイト変換処理
- デフォルト値: 131072バイト (128KB)

## デフォルト設定値

| リレー | サイズ (KB) | サイズ (バイト) | 理由 |
|--------|------------|----------------|------|
| Private | 128KB | 131,072 | 個人用途で柔軟性を持たせる |
| Chat | 128KB | 131,072 | DMも長文の可能性あり |
| Outbox | 128KB | 131,072 | 公開投稿、将来の長文対応 |
| Inbox | 128KB | 131,072 | 受信イベント用 |

### 現在のエラーとの比較

```
現在のエラー: 65,628バイト
旧制限: 65,535バイト (64KB)
新制限: 131,072バイト (128KB)

→ 約2倍に拡大、エラーは解消される
```

## イベントサイズの計算方法

Nostrイベント全体のJSONサイズを測定：

```go
eventJSON, _ := event.MarshalJSON()
eventSize := len(eventJSON)
```

これには以下が含まれます：

- `id` (64バイト)
- `pubkey` (64バイト)
- `created_at` (11バイト)
- `kind` (1-5バイト)
- `tags` (可変)
- `content` (可変)
- `sig` (128バイト)
- JSON構造のオーバーヘッド (~50バイト)

## ユーザーへの影響

### ✅ メリット

1. **現在のエラーが解消される**
   - 65,628バイトのイベントが通るようになる
   - 中程度の長文投稿が可能

2. **設定可能**
   - Start9 UIから各リレーの制限を調整可能
   - 必要に応じてさらに引き上げ可能

3. **後方互換性**
   - 既存の設定は影響を受けない
   - デフォルト値で動作

### ⚠️ 注意点

1. **さらに大きなイベントは未対応**
   - Kind 30023（長文記事）で10万文字の日本語投稿 (約293KB) はまだ制限を超える
   - ステップ2で Kind 別制限を実装予定

2. **ディスク容量**
   - より大きなイベントを保存できるため、ディスク使用量が増加する可能性
   - 個人リレーでは通常問題にならない

## テスト方法

### 1. ビルドテスト

```bash
cd haven
go build
```

### 2. 設定テスト

Start9 UIで設定を変更：

1. Services → Haven → Config
2. "Private Relay - Max Event Size" を確認 (デフォルト: 128)
3. 必要に応じて変更（例: 256KB）
4. Save して Haven を再起動

### 3. 実際のイベント送信テスト

1. Nostrクライアント（Amethystなど）で Havenに接続
2. 約60,000文字の長文を投稿
3. エラーが出ないことを確認

## ✅ ステップ2完了：Kind別のサイズ制限

Kind別のサイズ制限を実装しました：

```go
// 長文記事 (Kind 30023, 30024, 30040, 30041): 1MB (デフォルト)
// 通常投稿 (Kind 1): 128KB
// DM (Kind 4): 128KB
// その他: 各リレーのMaxEventSize
```

これにより、10万文字の日本語記事（約293KB）も対応可能になりました。

**詳細ドキュメント**: `max-event-size-step2-implementation.md`

## トラブルシューティング

### エラー: "content is too large: X, max is 131072"

→ 131,072バイト (128KB) を超えるイベントを送信しています。

**対処法:**
1. Start9 UI で該当リレーの Max Event Size を増やす（例: 256KB）
2. Kind 30023（長文記事）の場合は、ステップ2の実装を待つ

### 設定が反映されない

1. Haven サービスを再起動
2. `/data/start9/config.yaml` に設定が保存されているか確認
3. Havenログで `MaxEventSize` の値を確認

```bash
# ログ確認
docker logs haven-container | grep -i "relay limits"
```

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-01-07 | v1.2.4 (予定) | 初回実装（Step 1: 基本制限を128KBに引き上げ） |

---

**実装者ノート:**

- Step 1 は現在のエラーを即座に解消することが目的
- Step 2 で Kind別制限を実装し、長文記事（1MB）に対応予定
- Step 3 で Start9 UI からの詳細設定を追加予定


