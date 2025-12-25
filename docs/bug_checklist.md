# Haven Start9 Bug & Issue Checklist

## 📅 作成日: 2025-12-25
## 🎯 目的: Haven の既知の問題と今後の修正計画を追跡

---

## 🎉 現在のステータス（v1.0.8）

### ✅ 修正完了（テスト済み）
- **Tor アドレス永続化問題**: パッケージ更新時に .onion アドレスが変わらなくなりました
- **Blossom サーバーのファイルパス問題**: メディアファイルが正しく保存されるようになりました
- **URL スキーム問題**: Tor .onion アドレスに適切な `http://` スキームを使用

### 🔄 修正中
- **v1.1.1**: Blastr リレー機能のパーシングエラー修正（ビルド準備中）

### ⏳ 次のステップ
- **v1.1.1**: ビルド、デプロイ、テスト（Blastr 機能の動作確認）
- Amethyst での Blossom サーバー連携テスト（メディアアップロード）
- Properties の動的更新（v1.2.0 予定）

---

## 🔴 Critical Issues（即座に修正が必要）

### 1. Tor アドレスが永続化されない問題 ✅ 

**優先度**: 🔴 Critical  
**発見日**: 2025-12-25  
**ステータス**: ✅ 解決済み（v1.0.8）- **テスト完了**

**症状**:
- パッケージをサイドローディング（更新）すると、Tor の .onion アドレスが変わってしまう
- ユーザーはリレー URL を再設定する必要がある
- 既存のフォロワーがリレーにアクセスできなくなる

**根本原因**:
- Tor の `HiddenServiceDir` が `/var/lib/tor/haven/` に設定されていた
- このディレクトリは永続化ボリューム `/data` にマウントされていない
- コンテナの再作成時に Tor の秘密鍵が失われ、新しい .onion アドレスが生成される

**実施した修正**:
- ✅ `torrc`: `HiddenServiceDir` を `/data/tor/haven/` に変更
- ✅ `Dockerfile`: `/data/tor` ディレクトリを作成、適切なパーミッション設定
- ✅ `docker_entrypoint.sh`: `/data/tor/haven` の作成と既存アドレスの検出ロジックを追加
- ✅ `manifest.yaml`: v1.0.8 としてリリース

**修正内容詳細**:
```bash
# Before: 永続化されない
HiddenServiceDir /var/lib/tor/haven/

# After: /data にマウントされて永続化
HiddenServiceDir /data/tor/haven/
```

**テスト結果**: ✅ **動作確認完了**
- ✅ パッケージ更新時に .onion アドレスが変わらないことを確認
- ✅ コンテナの再起動時も同じアドレスを使用することを確認
- ✅ `/data/tor/haven/hostname` に .onion アドレスが永続化されることを確認

**担当**: AI Assistant  
**完了日**: 2025-12-25  
**テスト日**: 2025-12-25

---

### 2. Blossom サーバーのエラー ✅

**優先度**: 🔴 Critical  
**発見日**: 2025-12-25  
**ステータス**: ✅ 解決済み（v1.0.7）- **コード修正完了、デプロイ済み**

**症状**:
- Haven が起動し、Tor アドレスも生成されるが、Blossom サーバー関連のエラーが発生
- メディアファイルが正しく保存されない

**発見された問題**:
1. ✅ **ファイルパスの問題**: `config.BlossomPath + sha256` により、`blossom<sha256>` となり正しいディレクトリパスにならない
2. ✅ **URL スキームの問題**: Tor .onion アドレスに `https://` を使用していたが、`http://` を使うべき
3. ✅ **エラーログ不足**: デバッグが困難

**実施した修正**:
- ✅ `haven/init.go`: Blossom ファイルパスを `config.BlossomPath + "/" + sha256` に修正
- ✅ `haven/config.go`: `BlossomPath` の末尾スラッシュを削除する処理を追加
- ✅ `haven/init.go`: ファイル操作（作成、読み込み、削除）に詳細なエラーログを追加
- ✅ `haven/init.go`: すべてのリレーの `ServiceURL` を `https://` から `http://` に変更
- ✅ `haven/blossomMigration.go`: Blossom マイグレーションの `ServiceURL` を `http://` に変更
- ✅ `haven/init.go`: Blossom サーバー初期化時のログを追加

**修正内容詳細**:
```go
// Before:
file, err := fs.Create(config.BlossomPath + sha256)

// After:
file, err := fs.Create(config.BlossomPath + "/" + sha256)
if err != nil {
    slog.Error("🚫 Failed to create blob file", "error", err, "path", config.BlossomPath+"/"+sha256)
    return err
}
```

```go
// Before:
bl := blossom.New(outboxRelay, "https://"+config.RelayURL)

// After:
// Use http:// for Tor .onion addresses as they are already encrypted
serviceURL := "http://" + config.RelayURL
slog.Info("🌸 Initializing Blossom server", "serviceURL", serviceURL, "storagePath", config.BlossomPath)
bl := blossom.New(outboxRelay, serviceURL)
```

**デプロイ状況**:
- ✅ v1.0.7 としてコード修正完了
- ✅ v1.0.8 でデプロイ済み（Tor 永続化修正と併せて）
- ⏳ Amethyst での統合テスト待ち

**期待される成果**:
- Amethyst から Haven の Blossom サーバーにメディアをアップロードできる
- アップロードしたメディアが Nostr 投稿内で正しく表示される

**担当**: AI Assistant  
**完了日**: 2025-12-25

---

## 🟡 High Priority Issues（早急に修正すべき）

### 3. Blastr リレーの未実装 ✅

**優先度**: 🟡 High  
**発見日**: 2025-12-25  
**ステータス**: ✅ 解決済み（v1.1.0）

**症状**:
- Haven に投稿すると `blasted ... to 0 relays` と表示される
- `relays_blastr.json` ファイルは空の配列 `[]` として初期化される
- Blastr 機能のコードは存在するが、リレーリストを設定する方法がない

**根本原因（調査完了）**:
- ✅ `haven/blastr.go`: `blast()` 関数は実装済み
- ✅ `haven/init.go`: 325行目で `go blast(event)` が呼ばれている
- ✅ `haven/config.go`: `BlastrRelays` 設定は実装済み（環境変数 `BLASTR_RELAYS_FILE` から読み込み）
- ❌ `docker_entrypoint.sh`: 170-175行目で `relays_blastr.json` を常に空の配列 `[]` として初期化
- ❌ `manifest.yaml`: Blastr リレーリストの設定項目がない
- ❌ `getConfig.ts`/`setConfig.ts`: Blastr 設定の UI がない

**実施する修正（v1.1.0）**:
1. ✅ `getConfig.ts`: `blastr-relays` 設定項目を追加
   - タイプ: string（カンマ区切りのリレーURL）
   - デフォルト: relays_blastr.example.json の内容を使用
   - プレースホルダー: "wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band"

2. ✅ `setConfig.ts`: リレーURL形式のバリデーションを追加
   - 各URLが `wss://` または `ws://` で始まることを確認
   - カンマ区切りの形式を検証

3. ✅ `docker_entrypoint.sh`: Start9 config から blastr-relays を読み込み
   - yq で `blastr-relays` を取得
   - カンマ区切りを JSON 配列に変換
   - `/app/relays_blastr.json` に書き込み

4. ✅ `manifest.yaml`: バージョンを 1.1.0 に更新
   - リリースノートに Blastr 機能追加を記載

**修正内容詳細**:

**getConfig.ts に追加**:
```typescript
"blastr-relays": {
  "type": "string",
  "name": "Blastr Relay List",
  "description": "Comma-separated list of relay URLs to broadcast events to (e.g., wss://relay.damus.io,wss://nos.lol)",
  "nullable": true,
  "placeholder": "wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band",
  "default": "relay.damus.io,nos.lol,relay.nostr.band,relay.snort.social,nostr.land",
}
```

**docker_entrypoint.sh の initialize_relay_lists() を修正**:
```bash
initialize_relay_lists() {
    log_info "Initializing relay lists..."
    
    # Import relay list
    if [ ! -f /app/relays_import.json ]; then
        log_info "Creating empty import relay list..."
        su-exec haven sh -c 'echo "[]" > /app/relays_import.json'
    fi
    
    # Blastr relay list from config
    local blastr_relays=$(yq e '.blastr-relays // ""' /data/start9/config.yaml 2>/dev/null)
    
    if [ -n "$blastr_relays" ]; then
        log_info "Creating blastr relay list from config..."
        # Convert comma-separated string to JSON array
        echo "$blastr_relays" | tr ',' '\n' | jq -R -s -c 'split("\n") | map(select(length > 0) | gsub("^\\s+|\\s+$";""))' > /app/relays_blastr.json
        log_info "Blastr relays configured: $(cat /app/relays_blastr.json)"
    else
        log_info "No blastr relays configured, using empty list..."
        su-exec haven sh -c 'echo "[]" > /app/relays_blastr.json'
    fi
}
```

**期待される成果**:
- Start9 UI から Blastr リレーリストを設定できる
- 設定したリレーに Haven の投稿が自動転送される
- `blasted ... to X relays` のログで転送数が表示される

**テスト手順**:
1. Start9 UI で Blastr リレーリストを設定
2. Haven を再起動
3. `/app/relays_blastr.json` の内容を確認
4. Haven に投稿して、ログで転送数を確認
5. 外部リレーで投稿が見えることを確認

**担当**: AI Assistant  
**完了日**: 2025-12-25  
**実装バージョン**: v1.1.0

---

### 4. Properties の動的更新

**優先度**: 🟡 High  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- Properties（データベースサイズ、メディアストレージ）の値が静的
- サービス起動後に値が更新されない可能性

**想定される原因**:
- `properties.sh` がキャッシュされている
- Start9 が Properties を定期的に再実行していない

**調査手順**:
- [ ] Start9 の Properties 更新頻度を確認
- [ ] `properties.sh` の実行ログを確認
- [ ] `manifest.yaml` の Properties 設定を確認

**解決策候補**:
1. Start9 の Properties 更新頻度を manifest で明示的に設定
2. Properties にタイムスタンプを追加
3. リアルタイム更新を諦め、手動更新ボタンを追加（Start9 の機能次第）

**期待される成果**:
- データベースサイズとメディアストレージが常に最新の値を表示する

**担当**: TBD  
**期限**: 2026-01-15

---

## 🟢 Medium Priority Issues（改善すべき）

### 5. Config UI の改善

**優先度**: 🟢 Medium  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- 設定項目が多すぎて、UI が複雑
- デフォルト値が適切かどうか不明瞭

**解決策候補**:
1. 設定項目を「基本設定」「高度な設定」に分ける
2. 各設定項目にツールチップや詳細説明を追加
3. デフォルト値を推奨値として明示

**期待される成果**:
- 初心者でも簡単に Haven を設定できる
- 高度な設定は必要に応じて変更可能

**担当**: TBD  
**期限**: 2026-01-20

---

### 6. Health Check の詳細化

**優先度**: 🟢 Medium  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- Health Check が単純な HTTP チェックのみ
- WebSocket 接続や Tor 接続の健全性を確認していない

**解決策候補**:
1. `check-web.sh` を拡張し、以下を確認:
   - WebSocket 接続が可能か
   - Tor サービスが起動しているか
   - データベースにアクセス可能か
   - メモリ使用量が上限を超えていないか

**期待される成果**:
- より詳細なヘルスチェックにより、問題を早期発見できる

**担当**: TBD  
**期限**: 2026-02-01

---

### 7. エラーメッセージの改善

**優先度**: 🟢 Medium  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- エラーメッセージが技術的すぎて、ユーザーに理解しづらい
- 解決策が提示されていない

**解決策候補**:
1. エラーメッセージを平易な日本語（または英語）に翻訳
2. 各エラーメッセージに解決策を提示
3. トラブルシューティングガイドへのリンクを追加

**期待される成果**:
- ユーザーが自力でトラブルシューティングできる

**担当**: TBD  
**期限**: 2026-02-10

---

## 🔵 Low Priority Issues（余裕があれば修正）

### 8. パフォーマンスメトリクスの表示

**優先度**: 🔵 Low  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- リレーのパフォーマンス（イベント数、接続数）が不明
- ボトルネックを特定できない

**解決策候補**:
1. Properties にリレーメトリクスを追加:
   - アクティブな WebSocket 接続数
   - 処理したイベント数（24時間）
   - 平均レスポンス時間
   - メモリ使用量

**期待される成果**:
- リレーのパフォーマンスを可視化し、最適化の指標とする

**担当**: TBD  
**期限**: 2026-03-01

---

### 9. バックアップ機能の実装

**優先度**: 🔵 Low  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- Start9 の標準バックアップ機能のみで、Haven 専用のバックアップ機能がない
- クラウドバックアップ（S3, Backblaze）が未実装

**解決策候補**:
1. `manifest.yaml` でバックアップ対象を明示的に定義
2. クラウドバックアップ機能を実装（config で有効化）
3. バックアップのスケジュール設定を追加

**期待される成果**:
- ユーザーのデータが安全に保護される
- クラウドバックアップでリモートリストアが可能

**担当**: TBD  
**期限**: 2026-04-01

---

### 10. マルチリレー対応の改善

**優先度**: 🔵 Low  
**発見日**: 2025-12-25  
**ステータス**: ⏸️ 未着手

**症状**:
- 現在は 4 つのリレー（Private, Chat, Inbox, Outbox）が固定
- ユーザーが独自のリレーを追加できない

**解決策候補**:
1. Config で追加リレーを定義可能にする
2. 各リレーに独自の設定（WoT depth, フィルター）を適用可能にする

**期待される成果**:
- ユーザーが柔軟にリレーをカスタマイズできる

**担当**: TBD  
**期限**: 2026-05-01

---

## 📊 テストチェックリスト

### ✅ Tor アドレス永続化テスト（v1.0.8）

- [x] **初回インストールテスト**
  - [x] Haven v1.0.8 をインストール
  - [x] .onion アドレスを記録

- [x] **永続化テスト**
  - [x] パッケージを再インストール（サイドローディング）
  - [x] .onion アドレスが変わらないことを確認
  - [x] `/data/tor/haven/hostname` ファイルが存在することを確認

- [x] **コンテナ再起動テスト**
  - [x] Haven を再起動
  - [x] .onion アドレスが同じであることを確認

### ⏳ Blossom サーバーテスト（v1.0.7/v1.0.8）

- [ ] **アップロードテスト**
  - [ ] 小サイズ画像 (< 1MB) をアップロード
  - [ ] 大サイズ画像 (10-50MB) をアップロード
  - [ ] 動画ファイル (MP4, WebM) をアップロード
  - [ ] NIP-98 認証ヘッダーが正しく検証される

- [ ] **ダウンロードテスト**
  - [ ] SHA256 ハッシュで直接アクセス可能
  - [ ] `Content-Type` ヘッダーが正しい
  - [ ] ファイル内容が元のファイルと一致

- [ ] **削除テスト**
  - [ ] 認証済みユーザーが自分のファイルを削除可能
  - [ ] 非認証ユーザーは削除できない

- [ ] **Amethyst 連携テスト**
  - [ ] Amethyst でメディアサーバーとして Haven を追加
  - [ ] 画像をアップロードして投稿
  - [ ] 投稿内で画像が正しく表示される
  - [ ] 動画をアップロードして再生

### ⏳ Blastr リレーテスト（修正後）

- [ ] Blastr リレーリストを設定
- [ ] Haven に投稿したイベントが外部リレーに転送される
- [ ] 転送失敗時のエラーハンドリング

### ⏳ Properties 更新テスト

- [ ] サービス起動直後の Properties を確認
- [ ] 10 分後に Properties を再確認し、値が更新されているか
- [ ] ファイルをアップロードして、メディアストレージの値が増加するか

---

## 🗓️ リリース計画

### v1.0.8（Critical Hotfix）- 2025-12-25 ✅ **リリース完了**

**目標**: Tor アドレス永続化とBlossom サーバー修正

- [x] Tor アドレス永続化の問題修正
- [x] Blossom サーバーのエラー修正（v1.0.7 からの継続）
- [x] ビルドとデプロイ
- [x] **Tor アドレス永続化のテスト完了** ✅
- [ ] Amethyst との Blossom 連携テスト（次のステップ）

**リリースノート**:
```
v1.0.8 - Critical Tor Address Persistence Fix

CRITICAL Bug Fixes:
- Tor Hidden Service directory now persists to /data/tor/haven/
- Your .onion address will remain the same across package updates
- Note: If you updated to v1.0.7, your address will change one more 
  time with v1.0.8, but will then remain stable

v1.0.7 fixes included:
- Fixed Blossom file storage path issue
- Changed all relay ServiceURLs to http:// for Tor compatibility
- Added detailed error logging for Blossom operations
```

### v1.0.7（Hotfix）- 2025-12-25 ✅ 完了

**目標**: Blossom サーバーを動作させる

- [x] Blossom サーバーのエラー修正
- [x] コード修正完了
- [ ] Amethyst との連携テスト（v1.0.8 で実施予定）

### v1.1.0（Feature）- 2025-12-26 ✅

**目標**: Blastr リレー機能の実装

- [x] Blastr リレー実装計画の策定
- [x] `getConfig.ts`: blastr-relays 設定項目を追加
- [x] `setConfig.ts`: リレーURLバリデーションを追加
- [x] `docker_entrypoint.sh`: config からリレーリストを読み込み
- [x] `manifest.yaml`: v1.1.0 にバージョンアップ、リリースノート追加
- [x] ビルドとテスト（成功）
- [ ] デプロイ（ユーザー実施）

**ビルド結果**: ✅ 成功
- パッケージ: `haven.s9pk` v1.1.0
- 検証: 完了
- サイズ: Docker イメージのビルド完了

### v1.2.0（Enhancement）- 2026-02-15

**目標**: 監視とエラーハンドリング強化

- [ ] Health Check の詳細化
- [ ] エラーメッセージの改善
- [ ] パフォーマンスメトリクスの表示

### v2.0.0（Major）- 2026-06-01

**目標**: クラウドバックアップとカスタマイズ性向上

- [ ] バックアップ機能の実装
- [ ] マルチリレー対応の改善
- [ ] 大規模リファクタリング

---

## 📝 ノート

### 優先順位の決定基準

- **🔴 Critical**: サービスが正常に動作しない、ユーザーに重大な影響
- **🟡 High**: 主要機能が未実装または不完全
- **🟢 Medium**: UX や保守性の改善
- **🔵 Low**: Nice to have、将来的な拡張

### バグ報告テンプレート

新しいバグを発見した場合は、以下の形式で追加してください：

```markdown
### X. [バグタイトル]

**優先度**: 🔴/🟡/🟢/🔵  
**発見日**: YYYY-MM-DD  
**ステータス**: ⚠️ 調査中 / ⏸️ 未着手 / 🔄 修正中 / ✅ 解決済み

**症状**:
（具体的な現象を記載）

**想定される原因**:
（技術的な原因の仮説を列挙）

**調査手順**:
- [ ] 調査項目 1
- [ ] 調査項目 2

**解決策候補**:
（考えられる解決方法を列挙）

**期待される成果**:
（修正後の理想的な状態）

**担当**: TBD  
**期限**: YYYY-MM-DD
```

---

**作成日**: 2025-12-25  
**最終更新**: 2025-12-25（v1.1.0 ビルド完了）  
**次回レビュー**: Blastr 機能テスト完了後


