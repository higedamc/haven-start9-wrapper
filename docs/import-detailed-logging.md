# Import Detailed Logging - Implementation Guide

## 概要

Haven の Import Notes 機能に詳細なログ出力機能を実装しました。これにより、インポートプロセスの進捗、統計情報、エラーをリアルタイムで確認できます。

## 実装内容

### 1. カラーログ出力

色分けされたログレベルで見やすさを向上：

- **🟢 GREEN [INFO]**: 一般情報
- **🟡 YELLOW [WARN]**: 警告メッセージ
- **🔴 RED [ERROR]**: エラーメッセージ
- **🔵 CYAN [DEBUG]**: デバッグ情報
- **🔵 BLUE [PROGRESS]**: 進捗情報
- **🟢 GREEN [SUCCESS]**: 成功メッセージ

### 2. 詳細な設定情報ログ

インポート開始時に以下の情報を表示：

```
=============================================
   Haven Import Notes - Detailed Log
=============================================

[INFO] Import started at: 2025-12-27 15:30:00
[INFO] Log file: /data/logs/import-20251227-153000.log

=========================================
Import Configuration
=========================================
[INFO] Owner NPub: npub1abc...xyz (部分表示)
[INFO] Start Date: 2024-01-01
[INFO] Owner Notes Timeout: 30s
[INFO] Tagged Notes Timeout: 120s
[INFO] Seed Relays: 10 configured

[DEBUG] Relay list:
[DEBUG]   - wss://relay.damus.io
[DEBUG]   - wss://nos.lol
[DEBUG]   - wss://relay.primal.net
[DEBUG]   ... (続く)

=========================================
Time Range Analysis
=========================================
[INFO] Days to import: ~730 days
[INFO] Estimated batches: ~73 (10 days each)
[INFO] Estimated time: 36-73 minutes
```

### 3. リアルタイム進捗追跡

各バッチの処理状況をリアルタイムで表示：

```
[PROGRESS] Testing connection to seed relays...
[DEBUG] ✓ Connected: wss://relay.damus.io
[DEBUG] ✓ Connected: wss://nos.lol
[SUCCESS] All seed relays connected successfully!

[PROGRESS] Batch 1/73 (1%) - 15 notes from 2024-01-01 to 2024-01-10
[DEBUG] Total so far: 15 notes | ETA: ~35m

[PROGRESS] Batch 2/73 (3%) - 23 notes from 2024-01-11 to 2024-01-20
[DEBUG] Total so far: 38 notes | ETA: ~34m

[PROGRESS] Batch 3/73 (4%) - 0 notes (No notes for 2024-01-21 to 2024-01-30)
[DEBUG] Total so far: 38 notes | ETA: ~33m
```

### 4. 進捗インジケーター

- **バッチ番号**: 現在のバッチ / 総バッチ数
- **進捗パーセンテージ**: (現在のバッチ / 総バッチ) × 100
- **累計ノート数**: これまでにインポートしたノートの合計
- **推定残り時間 (ETA)**: 平均処理時間から計算

### 5. エラー・タイムアウトの詳細ログ

```
[WARN] ✗ Failed: wss://relay.example.com (接続失敗したリレー)
[WARN] Note import error (total errors: 3)
[WARN] Timeout occurred - consider increasing timeout values
```

### 6. タグ付きノートインポートの進捗

```
[PROGRESS] Starting tagged notes import (mentions, replies, reactions, zaps)...
[SUCCESS] Tagged notes import complete! Total: 234 notes
```

### 7. 詳細な統計サマリー

インポート完了時に包括的なレポートを表示：

```
=========================================
Import Summary
=========================================
[INFO] Completion time: 2025-12-27 16:15:23
[INFO] Duration: 45m 23s

[INFO] Results:
[INFO]   • Owner notes imported: 1,234
[INFO]   • Tagged notes imported: 567
[INFO]   • Total notes imported: 1,801
[WARN]   • Failed imports: 5

[INFO] Storage locations:
[INFO]   • Owner notes → Outbox relay
[INFO]   • Tagged notes → Inbox relay
[INFO]   • Gift wraps → Chat relay

[INFO] Next steps:
[INFO]   1. Restart Haven in normal mode
[INFO]   2. Connect your Nostr client
[INFO]   3. Verify imported notes are visible
=========================================

[SUCCESS] ✅ Import completed successfully!
[INFO] Full log saved to: /data/logs/import-20251227-153000.log

result: success
message: Import completed: 1,801 notes (1,234 owner + 567 tagged) in 45m 23s. Log: /data/logs/import-20251227-153000.log
```

## ログファイルの保存

各インポートセッションのログは自動的に保存されます：

- **保存先**: `/data/logs/import-YYYYMMDD-HHMMSS.log`
- **形式**: タイムスタンプ付きファイル名
- **内容**: すべてのログメッセージ（色コードなし）

例：
```
/data/logs/import-20251227-153000.log
/data/logs/import-20251228-090000.log
```

## docker_entrypoint.sh のログ拡張

Haven 起動時にもインポート設定の詳細を表示：

```
==========================================
  Running in IMPORT MODE
==========================================
[INFO] Import configuration:
[INFO]   • Start date: 2024-01-01
[INFO]   • Owner timeout: 30s
[INFO]   • Tagged timeout: 120s
[INFO]   • Seed relays: 10

[DEBUG] Configured import relays:
[DEBUG]     → wss://relay.damus.io
[DEBUG]     → wss://nos.lol
[DEBUG]     ... (続く)

[INFO] This may take a long time depending on:
[INFO]   • Amount of historical data
[INFO]   • Number of seed relays
[INFO]   • Network speed

[INFO] Starting import process...
==========================================
```

## 実装ファイル

### 変更ファイル

1. **`scripts/procedures/importNotes.sh`**
   - カラーログ関数の追加
   - 詳細な設定情報の表示
   - リアルタイム進捗パーサー
   - 統計サマリーの生成

2. **`docker_entrypoint.sh`**
   - import relays 初期化時の詳細ログ
   - インポートモード時の設定表示
   - リレーリストの詳細出力

## ログの読み方

### 正常なインポートの流れ

1. **設定の検証** → 全ての設定が正しく読み込まれる
2. **リレー接続テスト** → 全てのリレーに接続成功
3. **オーナーノートインポート** → バッチごとに進捗表示
4. **タグ付きノートインポート** → メンション等のインポート
5. **完了サマリー** → 統計情報と次のステップ

### トラブルシューティング

#### タイムアウトが多発

```
[WARN] Timeout occurred - consider increasing timeout values
```

**対処法**: Config でタイムアウト値を2倍に増やす

#### リレー接続失敗

```
[WARN] ✗ Failed: wss://relay.example.com
```

**対処法**: 接続できないリレーを Config から削除

#### ノートが見つからない

```
[DEBUG] Batch 5/73 - No notes for 2024-02-01 to 2024-02-10
```

**説明**: その期間にノートを投稿していない（正常な動作）

#### インポートエラー

```
[WARN] Note import error (total errors: 3)
```

**対処法**: ログファイルで詳細を確認し、Haven の動作ログをチェック

## パフォーマンス指標

実際のインポート時間の目安：

| データ量 | 期間 | リレー数 | 推定時間 |
|---------|------|---------|---------|
| 小規模 | 3ヶ月 | 5-10 | 5-15分 |
| 中規模 | 1年 | 5-10 | 15-45分 |
| 大規模 | 2年+ | 10-15 | 45分-2時間 |
| 超大規模 | 5年+ | 10-15 | 2-5時間 |

*実際の時間は以下の要因により変動します：*
- 投稿したノート数
- リレーの応答速度
- ネットワーク速度
- タイムアウト設定

## モニタリング方法

### Start9 UI から

1. **Services** → **Haven** → **Logs**
2. Import 実行中のログをリアルタイムで確認

### SSH 経由

```bash
# リアルタイムでログを監視
tail -f /data/logs/import-*.log

# 最新のインポートログを表示
ls -lt /data/logs/import-*.log | head -1 | xargs cat

# 統計情報のみ抽出
grep -E "\[SUCCESS\]|\[PROGRESS\]|Import Summary" /data/logs/import-*.log
```

## ログレベルの調整

Haven のログレベルを変更してより詳細な情報を取得：

**Config で設定:**
- `DEBUG`: 最も詳細（全てのリレー通信を表示）
- `INFO`: 標準（推奨）
- `WARN`: 警告とエラーのみ
- `ERROR`: エラーのみ

## 将来の拡張

### フェーズ2
- [ ] Web UI での進捗バー表示
- [ ] リアルタイム WebSocket 通知
- [ ] グラフィカルな統計チャート
- [ ] インポート履歴の保存と比較

### フェーズ3
- [ ] Prometheus メトリクスのエクスポート
- [ ] アラート機能（失敗率が高い場合）
- [ ] 自動リトライ機能
- [ ] インポート速度の最適化提案

## トラブルシューティングチェックリスト

インポートに問題がある場合：

- [ ] Import Start Date が設定されているか
- [ ] Import Seed Relays が設定されているか（最低1つ）
- [ ] リレーに接続できているか（ログで確認）
- [ ] タイムアウト値が適切か（Tor経由は長めに設定）
- [ ] ディスク容量は十分か
- [ ] Haven が正常に起動しているか
- [ ] ログファイルでエラーの詳細を確認

## まとめ

この詳細ログ実装により、Haven のインポートプロセスが完全に可視化されました：

✅ **リアルタイム進捗追跡** - バッチごとの進捗とETA
✅ **詳細な統計情報** - 成功/失敗数、所要時間
✅ **エラー診断** - 問題の特定と解決方法の提示
✅ **パフォーマンス監視** - リレー接続状況、処理速度
✅ **完全な監査証跡** - タイムスタンプ付きログファイル

これにより、ユーザーはインポートの進行状況を正確に把握し、問題が発生した場合も迅速に対処できます。

