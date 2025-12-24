# Haven 修正レポート（v1.0.7 & v1.0.8）

**日付**: 2025-12-25  
**最新バージョン**: 1.0.8  
**ステータス**: ✅ コード修正完了、テスト待ち

---

## 📋 修正概要

Haven に関する以下の **Critical** な問題を修正しました：

### v1.0.8 - Tor アドレス永続化
1. **🔴 CRITICAL: Tor アドレスが更新時に変わってしまう問題**

### v1.0.7 - Blossom サーバー修正
1. **ファイルパスの生成エラー**
2. **Tor アドレス使用時の URL スキーム問題**
3. **エラーログの不足**

---

## 🔍 発見された問題

### v1.0.8 の問題

#### 1. Tor アドレスの永続化問題 🔴 CRITICAL

**問題**:
```bash
# torrc の設定
HiddenServiceDir /var/lib/tor/haven/
```

**影響**: 
- `/var/lib/tor/haven/` は永続化ボリューム `/data` にマウントされていない
- パッケージ更新やコンテナ再作成時に Tor の秘密鍵が失われる
- 新しい .onion アドレスが生成される
- **ユーザーはリレー URL を全て再設定する必要がある**
- **既存のフォロワーがリレーにアクセスできなくなる**

これは **最も深刻な問題** でした。

---

### v1.0.7 の問題

#### 2. ファイルパスの生成エラー

**問題**:
```go
// Before: スラッシュがないため、blossom<sha256> というファイルが作成される
file, err := fs.Create(config.BlossomPath + sha256)
```

**影響**: Blossom ディレクトリ内にファイルが保存されず、アップロードが失敗する

---

#### 3. URL スキームの問題

**問題**:
```go
// Before: Tor .onion アドレスに https:// を使用
bl := blossom.New(outboxRelay, "https://"+config.RelayURL)
```

**影響**: 
- Tor の .onion アドレスは既に暗号化されているため、`https://` は不要
- Amethyst などのクライアントからアクセスできない可能性

---

#### 4. エラーログの不足

**問題**: ファイル操作時のエラーログがなく、デバッグが困難

---

## ✅ 実施した修正

### v1.0.8 の修正

#### 修正ファイル:
- `torrc`
- `Dockerfile`
- `docker_entrypoint.sh`
- `manifest.yaml`

#### Tor アドレス永続化の修正 (`torrc`)

```bash
# Before: 永続化されない
HiddenServiceDir /var/lib/tor/haven/

# After: /data にマウントされて永続化
HiddenServiceDir /data/tor/haven/
```

#### Dockerfile の修正

```dockerfile
# Before:
RUN mkdir -p /data/db /data/blossom /data/backups /var/lib/tor/haven && \
    chown -R haven:haven /data && \
    chown -R haven:haven /var/lib/tor && \
    chmod 700 /var/lib/tor/haven

# After:
RUN mkdir -p /data/db /data/blossom /data/backups /data/tor && \
    chown -R haven:haven /data && \
    chmod 700 /data/tor
```

#### docker_entrypoint.sh の修正

- `/data/tor/haven` ディレクトリの作成と権限設定を追加
- 既存の .onion アドレスの検出ロジックを追加
- Tor アドレスの読み込みパスを `/data/tor/haven/hostname` に変更

---

### v1.0.7 の修正

#### 修正ファイル:
- `haven/init.go`
- `haven/config.go`
- `haven/blossomMigration.go`
- `docs/bug_checklist.md`

#### 詳細:

#### 1. ファイルパスの修正 (`haven/init.go`)

```go
// After: スラッシュを追加して正しいパスを生成
file, err := fs.Create(config.BlossomPath + "/" + sha256)
if err != nil {
    slog.Error("🚫 Failed to create blob file", "error", err, "path", config.BlossomPath+"/"+sha256)
    return err
}
defer file.Close()

// 読み込みと削除も同様に修正
file, err := fs.Open(config.BlossomPath + "/" + sha256)
err := fs.Remove(config.BlossomPath + "/" + sha256)
```

#### 2. BlossomPath の正規化 (`haven/config.go`)

```go
// After: 末尾のスラッシュを削除して一貫性を保つ
BlossomPath: strings.TrimSuffix(getEnvString("BLOSSOM_PATH", "blossom"), "/"),
```

#### 3. URL スキームの修正 (`haven/init.go`, `haven/blossomMigration.go`)

```go
// After: Tor アドレスには http:// を使用
serviceURL := "http://" + config.RelayURL
slog.Info("🌸 Initializing Blossom server", "serviceURL", serviceURL, "storagePath", config.BlossomPath)
bl := blossom.New(outboxRelay, serviceURL)
bl.Store = blossom.EventStoreBlobIndexWrapper{Store: blossomDB, ServiceURL: bl.ServiceURL}
```

すべてのリレーの ServiceURL も同様に修正：
- `privateRelay.ServiceURL = "http://" + config.RelayURL + "/private"`
- `chatRelay.ServiceURL = "http://" + config.RelayURL + "/chat"`
- `outboxRelay.ServiceURL = "http://" + config.RelayURL`
- `inboxRelay.ServiceURL = "http://" + config.RelayURL + "/inbox"`

#### 4. エラーログの追加

```go
// ファイル作成
if err != nil {
    slog.Error("🚫 Failed to create blob file", "error", err, "path", config.BlossomPath+"/"+sha256)
    return err
}
slog.Info("✅ Blob stored successfully", "sha256", sha256, "size", len(body))

// ファイル読み込み
if err != nil {
    slog.Error("🚫 Failed to load blob", "error", err, "path", config.BlossomPath+"/"+sha256)
    return nil, err
}

// ファイル削除
if err != nil {
    slog.Error("🚫 Failed to delete blob", "error", err, "path", config.BlossomPath+"/"+sha256)
    return err
}
slog.Info("✅ Blob deleted successfully", "sha256", sha256)
```

---

## 🧪 テスト手順

### 1. ビルドとデプロイ

```bash
# Docker イメージのビルド
make clean
make build

# Start9 にデプロイ
make install
```

### 2. Blossom サーバーのテスト

#### 手動テスト（curl）

```bash
# 1. Tor アドレスを取得
TOR_ADDRESS=$(cat /var/lib/tor/haven/hostname)

# 2. テスト画像をアップロード
curl -X PUT "http://${TOR_ADDRESS}/<sha256>" \
  -H "Authorization: Nostr <base64_event>" \
  -H "Content-Type: image/jpeg" \
  --data-binary "@test.jpg"

# 3. アップロードした画像をダウンロード
curl "http://${TOR_ADDRESS}/<sha256>" -o downloaded.jpg

# 4. SHA256 ハッシュを確認
sha256sum test.jpg downloaded.jpg
```

#### Amethyst での統合テスト

1. Amethyst の設定で Haven の Blossom サーバーを追加:
   - サーバー URL: `http://<your-onion-address>`
   - NIP-98 認証を有効化

2. 画像を含む投稿を作成:
   - 画像を選択
   - 投稿を送信
   - Haven のログで以下を確認:
     ```
     🌸 Initializing Blossom server serviceURL=http://...
     storing blob sha256=... ext=jpg
     ✅ Blob stored successfully sha256=... size=...
     ```

3. 投稿を表示:
   - 画像が正しく表示されることを確認
   - Haven のログで以下を確認:
     ```
     loading blob sha256=... ext=jpg
     ```

### 3. ログの確認

```bash
# Haven のログを確認
docker logs -f haven-dev

# 期待されるログ:
# [INFO] 🌸 Initializing Blossom server serviceURL=http://... storagePath=/data/blossom
# [DEBUG] Blossom store configured serviceURL=http://...
# [DEBUG] storing blob sha256=... ext=jpg
# [INFO] ✅ Blob stored successfully sha256=... size=...
```

---

## 📊 期待される成果

### ✅ 修正後の動作

1. **ファイル保存**: `/data/blossom/<sha256>` に正しくファイルが保存される
2. **アップロード**: Amethyst から画像をアップロードできる
3. **ダウンロード**: アップロードした画像を Nostr クライアントで表示できる
4. **エラーログ**: 問題が発生した場合、詳細なログで原因を特定できる
5. **Tor 対応**: .onion アドレス経由でアクセスできる

### ⚠️ 残る課題（確認が必要）

1. **NIP-98 認証**: khatru の Blossom パッケージが NIP-98 認証を正しく検証しているか
2. **MIME タイプ**: すべてのメディアタイプ（画像、動画、音声）が正しく処理されるか
3. **ファイルサイズ制限**: 大きなファイルのアップロードが正しく処理されるか
4. **並行アップロード**: 複数のファイルを同時にアップロードした場合の動作
5. **ディスク容量**: ディスク容量が不足した場合のエラーハンドリング

---

## 📝 次のステップ

### v1.0.8 リリース

1. ✅ コード修正完了
2. ⏳ Docker ビルド
3. ⏳ Start9 へのデプロイ
4. ⏳ Tor アドレスの永続化確認
   - 初回起動後の .onion アドレスを記録
   - パッケージを再インストール
   - .onion アドレスが同じか確認
5. ⏳ 手動テスト（curl で Blossom サーバー）
6. ⏳ Amethyst での統合テスト
7. ⏳ 本番環境での検証
8. ⏳ リリースノートの作成

### 重要な注意事項

**v1.0.7 から v1.0.8 へのアップグレード時:**
- .onion アドレスが **もう一度だけ** 変わります
- これは Tor のデータディレクトリの場所が変わるため避けられません
- v1.0.8 以降は、アドレスが永続化されます
- ユーザーには以下を伝える必要があります:
  1. v1.0.8 にアップグレード後、新しい .onion アドレスを確認
  2. Nostr クライアントのリレー設定を更新
  3. 今後のアップグレードでは .onion アドレスは変わらない

---

## 🔗 関連リソース

### Blossom 仕様
- [BUD-02: Blossom Server Specification](https://github.com/hzrd149/blossom)
- [NIP-98: HTTP Auth](https://github.com/nostr-protocol/nips/blob/master/98.md)

### Haven リポジトリ
- [Haven GitHub](https://github.com/bitvora/haven)
- [khatru GitHub](https://github.com/fiatjaf/khatru)

### Start9 ドキュメント
- [Start9 Packaging Guide](https://docs.start9.com/latest/developer-docs/packaging/)

---

## 👥 貢献者

- **修正者**: AI Assistant
- **レビュー**: TBD
- **テスト**: TBD

---

**更新日**: 2025-12-25  
**次回レビュー**: ビルドとテスト完了後

