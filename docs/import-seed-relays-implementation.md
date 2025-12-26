# Import Seed Relays Implementation Guide

## 概要

Haven の Import Seed Relays 機能を Start9 パッケージに統合するための実装ガイドです。この機能により、ユーザーは外部リレーから過去のノートやメッセージをインポートし、Haven リレーに同期できます。

## Import Seed Relays の主要機能

### コア機能
1. **リレー接続テスト**: 設定された Import Seed Relays への接続を検証
2. **オーナーノートのインポート**: ユーザーが投稿した過去のノートを取得
3. **タグ付きノートのインポート**: ユーザーが言及されたノート（リプライ、リアクション、Zap等）を取得
4. **リアルタイムサブスクリプション**: 新しいメンション/リプライをリアルタイムで監視
5. **Web of Trust フィルタリング**: 信頼ネットワーク外のスパムをフィルタ

### インポート対象イベント
- Kind 1: テキストノート
- Kind 4: 暗号化DM
- Kind 6: リポスト
- Kind 7: リアクション
- Kind 1059: GiftWrap メッセージ（NIP-17）
- Kind 9735: Zap

---

## 実装工程

### 1. IMPORT_SEED_RELAYS_FILE の設定

**目的**: ユーザーがインポート元リレーのリストを管理できるようにする

#### 1.1 Config Schema の拡張

`manifest.yaml` の config セクションに追加：

```yaml
import-seed-relays:
  type: list
  subtype: string
  name: Import Seed Relays
  description: >
    List of Nostr relays to import your past notes and mentions from.
    These relays will be used to fetch your historical data and monitor for new mentions.
  warning: >
    Using too many relays may slow down the import process. 
    It's recommended to use 5-15 reliable relays.
  default:
    - "wss://relay.damus.io"
    - "wss://nos.lol"
    - "wss://relay.nostr.band"
    - "wss://relay.snort.social"
    - "wss://relay.primal.net"
    - "wss://nostr.mom"
    - "wss://relay.nos.social"
    - "wss://wot.utxo.one"
    - "wss://nostrelites.org"
    - "wss://wot.nostr.party"
  nullable: false
  changeWarning: >
    Changing import seed relays will affect future imports and real-time monitoring.
    Existing imported data will not be affected.
```

#### 1.2 設定ファイルの生成

`scripts/procedures/setConfig.ts` での処理：

```typescript
// Import Seed Relays の設定
const importSeedRelays = effects.config?.['import-seed-relays'] || defaultRelays;

// relays_import.json ファイルを生成
await $`echo ${JSON.stringify(importSeedRelays, null, 2)} > /haven/relays_import.json`;
```

#### 1.3 環境変数の設定

`docker_entrypoint.sh` での環境変数設定：

```bash
export IMPORT_SEED_RELAYS_FILE="/haven/relays_import.json"
```

#### 1.4 バリデーション

- 各リレーURLが有効な形式（ws:// or wss://）であることを確認
- 最小1つ、最大50個程度のリレーを許可
- 重複URLを除外

---

### 2. リレーリストの編集機能

**目的**: ユーザーが簡単にリレーを追加・削除・編集できるUI/UX

#### 2.1 UI コンポーネント設計

Config ページでのリスト型UI：
- ✅ 各リレーURLを表示
- ➕ 新しいリレーを追加するボタン
- ❌ 個別リレーを削除するボタン
- 📝 インラインで編集可能
- 🔄 デフォルトリストに戻すボタン

#### 2.2 推奨リレーリストの提供

プリセット機能：
```yaml
# UI で選択可能なプリセット
presets:
  minimal:
    - "wss://relay.damus.io"
    - "wss://relay.primal.net"
    - "wss://nos.lol"
  
  balanced:
    - "wss://relay.damus.io"
    - "wss://nos.lol"
    - "wss://relay.nostr.band"
    - "wss://relay.snort.social"
    - "wss://relay.primal.net"
    - "wss://nostr.mom"
    - "wss://relay.nos.social"
  
  wot-focused:
    - "wss://wot.utxo.one"
    - "wss://wot.nostr.party"
    - "wss://wot.sovbit.host"
    - "wss://wot.girino.org"
    - "wss://relay.damus.io"
    - "wss://relay.primal.net"
  
  maximum:
    # すべてのデフォルトリレー（20個程度）
```

#### 2.3 リレー接続テスト機能

設定保存前にリレーの接続性をテスト：
- WebSocket接続のテスト
- レスポンスタイムの測定
- 到達不可能なリレーに警告表示

---

### 3. IMPORT_START_DATE の設定

**目的**: ユーザーが過去のどの時点からノートをインポートするか指定

#### 3.1 Config Schema

```yaml
import-start-date:
  type: string
  name: Import Start Date
  description: >
    The date from which to start importing your past notes (YYYY-MM-DD format).
    Only used when running the manual import action.
    Earlier dates will import more data but take longer.
  warning: >
    Importing data from very old dates may take a long time and consume significant resources.
    Start with a recent date (e.g., last 1-2 years) and extend if needed.
  default: "2024-01-01"
  nullable: false
  pattern: '^\d{4}-\d{2}-\d{2}$'
  patternDescription: "Date in YYYY-MM-DD format (e.g., 2024-01-01)"
```

#### 3.2 日付バリデーション

```typescript
// setConfig.ts でのバリデーション
const importStartDate = effects.config?.['import-start-date'];

// 日付形式の検証
if (!/^\d{4}-\d{2}-\d{2}$/.test(importStartDate)) {
  throw new Error("Import start date must be in YYYY-MM-DD format");
}

// 日付の妥当性チェック
const startDate = new Date(importStartDate);
if (isNaN(startDate.getTime())) {
  throw new Error("Invalid date provided");
}

// 未来の日付でないことを確認
if (startDate > new Date()) {
  throw new Error("Import start date cannot be in the future");
}

// あまりにも古い日付（例: 2010年以前）に警告
if (startDate < new Date('2010-01-01')) {
  console.warn("Warning: Import start date is very old. This may take a very long time.");
}
```

#### 3.3 UI 推奨設定

プリセット日付オプション：
- **Last 3 months**: 最近3ヶ月
- **Last 6 months**: 最近6ヶ月
- **Last 1 year**: 最近1年
- **Last 2 years**: 最近2年
- **Since 2024**: 2024年1月1日から
- **Custom**: カスタム日付

#### 3.4 環境変数の設定

```bash
export IMPORT_START_DATE="${IMPORT_START_DATE}"
```

---

### 4. タイムアウト設定のカスタマイズ

**目的**: ネットワーク環境に応じてタイムアウト値を調整可能にする

#### 4.1 Config Schema

```yaml
import-owner-notes-timeout:
  type: number
  name: Owner Notes Import Timeout
  description: >
    Timeout in seconds for fetching your own notes from each time window (10 days).
    Increase if you have a slow connection or many notes to import.
  default: 30
  range: "[10,300]"
  units: seconds
  nullable: false

import-tagged-notes-timeout:
  type: number
  name: Tagged Notes Import Timeout
  description: >
    Timeout in seconds for fetching notes that mention you.
    This may take longer as it searches across all events.
  default: 120
  range: "[30,600]"
  units: seconds
  nullable: false

import-query-interval:
  type: number
  name: Import Query Interval
  description: >
    Interval in seconds between import queries (not used in current version).
    Reserved for future periodic import functionality.
  default: 360000
  range: "[3600,604800]"
  units: seconds
  nullable: false
```

#### 4.2 推奨値

ネットワーク状況に応じた推奨値：

| 接続速度 | Owner Notes Timeout | Tagged Notes Timeout |
|---------|---------------------|----------------------|
| 高速（>100Mbps） | 30秒 | 120秒 |
| 中速（10-100Mbps） | 60秒 | 240秒 |
| 低速（<10Mbps） | 120秒 | 300秒 |
| Tor経由 | 180秒 | 480秒 |

#### 4.3 環境変数の設定

```bash
export IMPORT_OWNER_NOTES_FETCH_TIMEOUT_SECONDS="${IMPORT_OWNER_NOTES_TIMEOUT}"
export IMPORT_TAGGED_NOTES_FETCH_TIMEOUT_SECONDS="${IMPORT_TAGGED_NOTES_TIMEOUT}"
export IMPORT_QUERY_INTERVAL_SECONDS="${IMPORT_QUERY_INTERVAL}"
```

#### 4.4 動的調整（将来的な拡張）

- タイムアウト発生時に自動的に値を増加
- 成功率に基づいて最適値を学習
- ユーザーに推奨値を提案

---

### 5. 手動インポート実行のアクション

**目的**: ユーザーがワンクリックで過去データのインポートを実行できるようにする

#### 5.1 Action の定義

`manifest.yaml` の actions セクションに追加：

```yaml
actions:
  import-notes:
    name: Import Past Notes
    description: >
      Import your past notes and mentions from the configured seed relays.
      This is a one-time manual operation that will:
      1. Fetch all your notes from the specified start date
      2. Import notes that mention you
      3. Store them in your Haven relay
      
      This may take several minutes to hours depending on:
      - How far back your import start date is
      - How many notes you have published
      - The configured timeout values
      - Network speed and relay responsiveness
    warning: >
      This operation can take a long time and consume significant resources.
      Make sure you have:
      - Set an appropriate import start date
      - Configured reliable seed relays
      - Allocated enough timeout values
      
      The import will run in the foreground and you'll see progress in the logs.
      Do not interrupt the process once started.
    allowed-statuses:
      - running
    implementation:
      type: docker
      image: main
      system: true
      entrypoint: import-notes
      args: []
      mounts:
        - data: /haven
      io-format: json
```

#### 5.2 インポートスクリプトの作成

`scripts/procedures/importNotes.sh`:

```bash
#!/bin/bash

set -e

IMPORT_LOG="/haven/logs/import-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /haven/logs

echo "Starting import process..." | tee -a "$IMPORT_LOG"
echo "Import start date: ${IMPORT_START_DATE}" | tee -a "$IMPORT_LOG"
echo "Import seed relays: ${IMPORT_SEED_RELAYS_FILE}" | tee -a "$IMPORT_LOG"

# Haven を --import フラグ付きで実行
cd /haven
./haven --import 2>&1 | tee -a "$IMPORT_LOG"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Import completed successfully!" | tee -a "$IMPORT_LOG"
else
    echo "🚫 Import failed with exit code $EXIT_CODE" | tee -a "$IMPORT_LOG"
    exit $EXIT_CODE
fi
```

#### 5.3 TypeScript Action Implementation

`scripts/procedures/importNotes.ts`:

```typescript
import { types as T } from "../deps.ts";

export const importNotes: T.ExpectedExports.importNotes = {
  "import-notes": {
    name: "Import Past Notes",
    warning: "This operation may take a long time. Check logs for progress.",
    "allowed-statuses": ["running"],
    implementation: async (effects, duration) => {
      await effects.info("Starting note import process...");
      
      // Config値を取得
      const startDate = await effects.getConfig("import-start-date");
      const seedRelays = await effects.getConfig("import-seed-relays");
      const ownerTimeout = await effects.getConfig("import-owner-notes-timeout");
      const taggedTimeout = await effects.getConfig("import-tagged-notes-timeout");
      
      await effects.info(`Importing from ${startDate}`);
      await effects.info(`Using ${seedRelays.length} seed relays`);
      await effects.info(`Timeout: Owner=${ownerTimeout}s, Tagged=${taggedTimeout}s`);
      
      // Haven コンテナ内で import を実行
      const result = await effects.exec({
        command: ["/haven/haven", "--import"],
        cwd: "/haven",
      });
      
      if (result.exitCode === 0) {
        await effects.success("Import completed successfully!");
      } else {
        await effects.error(`Import failed with exit code ${result.exitCode}`);
        throw new Error("Import process failed");
      }
      
      return {
        message: "Import process completed. Check logs for details.",
        value: null,
        qr: false,
      };
    },
  },
};
```

#### 5.4 UI での表示

Actions ページでの表示内容：

**タイトル**: Import Past Notes

**説明**:
```
Import your historical notes and mentions from Nostr relays.

Current Configuration:
• Start Date: 2024-01-01
• Seed Relays: 10 relays configured
• Owner Notes Timeout: 30 seconds
• Tagged Notes Timeout: 120 seconds

Estimated Time: 10-60 minutes (depends on amount of data)

This action will:
1. Connect to your import seed relays
2. Fetch all your published notes since the start date
3. Import mentions, replies, reactions, and zaps
4. Store everything in your Haven relay

⚠️ Warning: This may take a long time. Monitor the logs for progress.
```

#### 5.5 進捗モニタリング

ログ出力の改善：
- 進捗パーセンテージの表示
- 処理済みバッチ数 / 総バッチ数
- インポートされたノート数のカウント
- 推定残り時間

```bash
# ログ例
📦 Import Progress: [=====>    ] 50% (5/10 batches)
📊 Imported: 1,234 owner notes, 567 tagged notes
⏱️  Estimated time remaining: 5 minutes
```

#### 5.6 エラーハンドリング

- タイムアウト発生時の再試行オプション
- 部分的な成功でも結果を保存
- 失敗したリレーのリスト表示
- ユーザーへの対処方法の提案

---

## テスト計画

### 6.1 単体テスト

- [ ] リレーURL形式のバリデーション
- [ ] 日付形式のバリデーション
- [ ] タイムアウト値の範囲チェック
- [ ] 設定ファイル生成の正確性

### 6.2 統合テスト

- [ ] Config変更 → 設定ファイル生成 → Haven起動の流れ
- [ ] 手動インポートアクションの実行
- [ ] 複数リレーからのインポート成功
- [ ] 一部リレー障害時の挙動

### 6.3 エンドツーエンドテスト

- [ ] 新規インストール → 設定 → インポート実行
- [ ] 異なる日付範囲でのインポート
- [ ] 大量データ（10,000+ ノート）のインポート
- [ ] ネットワーク障害時の復旧

### 6.4 パフォーマンステスト

- [ ] 1年分のデータインポート時間測定
- [ ] 5年分のデータインポート時間測定
- [ ] メモリ使用量の監視
- [ ] ディスクI/O負荷の測定

---

## トラブルシューティング

### よくある問題と解決方法

#### 1. インポートが完了しない
**原因**: タイムアウト値が小さすぎる  
**解決**: タイムアウト値を2倍に増やして再試行

#### 2. 一部のリレーに接続できない
**原因**: リレーがダウンしているか、ネットワーク問題  
**解決**: 接続できないリレーをリストから削除

#### 3. 重複したノートがインポートされる
**原因**: Haven の重複チェック機能が正しく動作していない  
**解決**: データベースの整合性をチェック（将来の機能）

#### 4. メモリ不足エラー
**原因**: 大量のデータを一度にインポート  
**解決**: Import Start Date をより最近の日付に設定

---

## セキュリティ考慮事項

### 1. リレーURLの検証
- 悪意のあるURLの拒否
- ローカルIPアドレスへの接続を禁止
- SSL/TLS検証の強制（wss:// のみ許可）

### 2. データの検証
- インポートされたイベントの署名検証
- Web of Trust フィルタリングの適用
- 不正なイベントの拒否

### 3. レート制限
- リレーへのリクエスト頻度の制限
- サービス拒否攻撃の防止

---

## 今後の拡張機能

### フェーズ2（将来）
- [ ] 定期的な自動インポート（スケジュール機能）
- [ ] インポート進捗のリアルタイム表示（WebSocket）
- [ ] インポート履歴の記録と管理
- [ ] 選択的インポート（特定のKindのみ）
- [ ] インポートデータのエクスポート機能

### フェーズ3（将来）
- [ ] リレーパフォーマンスの自動測定と最適化
- [ ] AI推薦によるリレー選択
- [ ] 差分インポート（新しいデータのみ）
- [ ] マルチスレッド並列インポート

---

## 参考資料

- Haven Import 実装: `/haven/import.go`
- Haven Config 実装: `/haven/config.go`
- Haven Main エントリーポイント: `/haven/main.go`
- Start9 Manifest Schema: `manifest.yaml`
- Nostr Protocol: https://github.com/nostr-protocol/nips

---

## 実装チェックリスト

### 必須機能
- [ ] 1. Import Seed Relays 設定（Config Schema）
- [ ] 2. リレーリスト編集UI
- [ ] 3. Import Start Date 設定
- [ ] 4. タイムアウト設定
- [ ] 5. 手動インポートアクション

### ドキュメント
- [x] 実装ガイドの作成
- [ ] ユーザーマニュアルの更新
- [ ] トラブルシューティングガイド
- [ ] API/Config リファレンス

### テスト
- [ ] 単体テスト
- [ ] 統合テスト
- [ ] E2Eテスト
- [ ] パフォーマンステスト

### デプロイ
- [ ] manifest.yaml への追加
- [ ] スクリプトの実装
- [ ] Docker イメージの更新
- [ ] リリースノートの作成

