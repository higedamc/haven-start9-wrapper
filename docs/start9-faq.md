# Haven Start9 FAQ (よくある質問)

## 📚 目次

- [一般的な質問](#一般的な質問)
- [技術的な質問](#技術的な質問)
- [トラブルシューティング](#トラブルシューティング)
- [開発者向け質問](#開発者向け質問)
- [Blossom 関連](#blossom-関連)
- [セキュリティ](#セキュリティ)

---

## 一般的な質問

### Q1: Haven とは何ですか？

**A:** Haven (High Availability Vault for Events on Nostr) は、個人用の Nostr リレースイートです。4つの専門化されたリレー（Private、Chat、Inbox、Outbox）と Blossom メディアサーバーを統合しています。

### Q2: なぜ Start9 Server 用にパッケージ化するのですか？

**A:** Start9 Server は self-sovereign なインフラストラクチャを簡単に運用できるプラットフォームです。Haven を Start9 用にパッケージ化することで：
- ワンクリックインストール
- Tor-only 運用（プライバシー保護）
- 自動バックアップ
- Web UI での簡単な設定

が可能になります。

### Q3: Start9 Server がなくても Haven は使えますか？

**A:** はい、Haven は独立したアプリケーションとして動作します。Start9 パッケージは便利なインストール方法の1つです。従来通り、Linux サーバーで直接実行することも可能です。

### Q4: 必要なハードウェアスペックは？

**A:** 最小要件：
- **CPU**: 2コア以上
- **メモリ**: 1GB 以上（推奨: 2GB）
- **ストレージ**: 10GB 以上（データ量により増加）
- **ネットワーク**: Tor 対応

Start9 Server Pure、Raspberry Pi 4、x86_64 PC で動作します。

### Q5: インストールにどれくらい時間がかかりますか？

**A:** 
- **ダウンロード**: 5-10分（ネットワーク速度依存）
- **インストール**: 2-5分
- **初期設定**: 5-10分
- **合計**: 15-25分程度

### Q6: Haven は何に使えますか？

**A:**
1. **Private Relay**: 個人的なメモ、下書き、eCash の保管
2. **Chat Relay**: 信頼できる人との DM
3. **Inbox Relay**: あなた宛のメンション、返信、Zap の受信
4. **Outbox Relay**: 公開投稿の配信
5. **Blossom Server**: 画像・動画のホスティング

---

## 技術的な質問

### Q7: どの Nostr クライアントが対応していますか？

**A:** 主要なクライアントは全て対応：
- ✅ **Amethyst** (Android) - Blossom サポート
- ✅ **Damus** (iOS)
- ✅ **Primal** (Web/Mobile)
- ✅ **Coracle** (Web) - Blossom サポート
- ✅ **nostrudel** (Web) - Blossom サポート

NIP-42 (Auth) と NIP-96 (File Storage) をサポートするクライアントなら全て使用可能です。

### Q8: データベースは何を使っていますか？

**A:** Haven は2つのデータベースエンジンをサポート：

| エンジン | 特徴 | 推奨環境 |
|---------|------|---------|
| **BadgerDB** | デフォルト、高い互換性 | 全般 |
| **LMDB** | 高速、低メモリ使用 | NVMe ドライブ |

設定で切り替え可能です。

### Q9: ストレージはどれくらい必要ですか？

**A:** 使用量の目安：

| データ | サイズ | 備考 |
|-------|--------|------|
| **データベース** | 100MB-10GB | イベント数による |
| **Blossom メディア** | 1GB-100GB | アップロードした画像・動画 |
| **システム** | 500MB | Haven アプリ自体 |

**推奨**: 初期は 10GB、後で拡張可能なストレージ。

### Q10: Web of Trust (WoT) とは何ですか？

**A:** WoT は信頼ネットワークを構築する仕組みです：

```
あなた
 ├─ フォロー1（深度1）
 │   ├─ フォロー1-1（深度2）
 │   └─ フォロー1-2（深度2）
 └─ フォロー2（深度1）
     └─ フォロー2-1（深度2）
```

**Chat Relay** と **Inbox Relay** は WoT で保護され、信頼できる人だけがアクセスできます。

### Q11: Blossom と NIP-96 の違いは？

**A:**
- **NIP-96**: Nostr でファイルストレージを統合するための標準
- **Blossom (BUD-02)**: 具体的な実装仕様

Haven の Blossom サーバーは両方に準拠しています。

### Q12: Tor-only とは何を意味しますか？

**A:** Haven は以下の通り動作します：
- ❌ Clearnet（通常のインターネット）での直接アクセス不可
- ✅ Tor Hidden Service として動作（.onion アドレス）
- ✅ エンドツーエンド暗号化
- ✅ IP アドレスの秘匿

プライバシーとセキュリティが最大化されます。

---

## トラブルシューティング

### Q13: Haven サービスが起動しません

**A:** 以下を確認：

```bash
# 1. ログ確認
start-cli service logs haven

# 2. ステータス確認
start-cli package list | grep haven

# 3. 再起動
start-cli service restart haven

# 4. 設定確認
# Start9 UI → Services → Haven → Config
# OWNER_NPUB が正しいか確認
```

**よくある原因**:
- npub が未設定または間違っている
- ストレージ容量不足
- データベース破損

### Q14: .onion アドレスが取得できません

**A:** Tor Hidden Service の生成には時間がかかる場合があります：

```bash
# 1. Tor ログ確認
start-cli service exec haven cat /var/log/tor/notices.log

# 2. 手動で確認
start-cli service exec haven cat /var/lib/tor/haven/hostname

# 3. 時間待機（初回は最大5分）
```

再起動しても解決しない場合は、Haven を再インストールしてください。

### Q15: Nostr クライアントから接続できません

**A:** チェック項目：

1. **Tor が動作しているか**（クライアント側）
   - Amethyst: Settings → Proxy → Tor を有効化
   - Orbot（Android）がインストールされているか

2. **.onion アドレスが正しいか**
   - Start9 UI → Services → Haven → Properties でコピー

3. **WebSocket プロトコル**
   - `ws://your-address.onion` (HTTP)
   - `wss://` ではなく `ws://` を使用

4. **リレー権限**
   - Private/Chat: 認証が必要（NIP-42）
   - クライアントが Auth をサポートしているか確認

### Q16: メディアアップロードが失敗します

**A:** 確認事項：

```bash
# 1. ストレージ確認
start-cli service exec haven df -h /data/blossom

# 2. ファイルサイズ
# デフォルト制限: 100MB
# Config → Blossom Settings で変更可能

# 3. MIME type
# 許可されているか確認（画像: jpg, png, gif, webp / 動画: mp4, webm）

# 4. 認証
# あなたの nsec で署名されているか（NIP-98）
```

### Q17: データベースが破損しました

**A:** 復旧手順：

```bash
# Option 1: バックアップから復元
# Start9 UI → Services → Haven → Backups → Restore

# Option 2: データベース再構築
start-cli service stop haven
start-cli service exec haven rm -rf /data/db/*
start-cli service start haven

# ⚠️ 注意: データが失われます！
# 事前にバックアップを取ってください
```

### Q18: メモリ使用量が多すぎます

**A:** 最適化方法：

1. **データベースエンジン変更**
   ```
   Config → Database → Engine → LMDB
   ```

2. **WoT 深度を減らす**
   ```
   Config → Chat Relay → WoT Depth → 1
   ```

3. **古いイベント削除**
   ```bash
   # 手動で古いイベントをクリーンアップ
   # （将来のバージョンで自動化予定）
   ```

4. **再起動**
   ```bash
   start-cli service restart haven
   ```

---

## 開発者向け質問

### Q19: Haven のコードをカスタマイズできますか？

**A:** はい！Haven はオープンソース（MIT ライセンス）です：

```bash
# フォーク
git clone --recurse-submodules https://github.com/YOUR_USERNAME/haven-start9-wrapper.git
cd haven-start9-wrapper

# カスタマイズ
vim main.go

# ビルド
go build -o haven .

# Start9 パッケージング
make
```

### Q20: 独自の NIP を Haven に追加するには？

**A:** 手順：

1. **機能実装**
   ```go
   // custom_nip.go
   func handleCustomNIP(relay *khatru.Relay) {
       relay.OnEvent = append(relay.OnEvent, func(ctx context.Context, event *nostr.Event) {
           // カスタムロジック
       })
   }
   ```

2. **init.go に統合**
   ```go
   func initRelays() {
       // ... existing code
       handleCustomNIP(outboxRelay)
   }
   ```

3. **ビルド & テスト**
   ```bash
   go test ./...
   make
   ```

### Q21: ローカル開発環境のセットアップは？

**A:** クイックセットアップ：

```bash
# 1. Haven クローン
git clone --recurse-submodules https://github.com/YOUR_USERNAME/haven-start9-wrapper.git
cd haven-start9-wrapper

# 2. 依存関係インストール
go mod download

# 3. .env 設定
cp .env.example .env
vim .env  # OWNER_NPUB などを設定

# 4. リレーリスト作成
echo '[]' > relays_import.json
echo '[]' > relays_blastr.json

# 5. 実行
go run .
```

アクセス: `ws://localhost:3355`

### Q22: CI/CD パイプラインを構築するには？

**A:** GitHub Actions 例：

```yaml
# .github/workflows/build.yml
name: Build Start9 Package

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup environment
        run: ./prepare.sh
      
      - name: Build package
        run: make
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: haven.s9pk
          path: haven.s9pk
```

### Q23: デバッグログを有効化するには？

**A:** 設定変更：

```
Start9 UI → Services → Haven → Config
→ Advanced Settings
→ Log Level: DEBUG
→ Save
```

または環境変数：

```bash
export HAVEN_LOG_LEVEL=DEBUG
```

ログレベル: `DEBUG` > `INFO` > `WARN` > `ERROR`

---

## Blossom 関連

### Q24: Blossom サーバーの URL は？

**A:** 
```
http://<your-haven-address>.onion
```

Start9 UI → Services → Haven → Properties からコピーできます。

### Q25: Amethyst で Haven の Blossom を使うには？

**A:** 設定手順：

1. **Amethyst を開く**
2. **Settings → Media Servers**
3. **Add Server**
4. **Haven の .onion URL を入力**
   ```
   http://your-address.onion
   ```
5. **Save**

以降、画像アップロード時に Haven が自動的に使用されます。

### Q26: Blossom でサポートされるファイル形式は？

**A:** デフォルト：

| カテゴリ | 形式 |
|---------|------|
| **画像** | JPEG, PNG, GIF, WebP |
| **動画** | MP4, WebM |

Config で追加のフォーマットを許可できます（将来のバージョン）。

### Q27: アップロードしたファイルを削除するには？

**A:** 方法：

1. **クライアントから**（NIP-98 Auth 必要）
   ```
   DELETE http://your-address.onion/<sha256>
   Authorization: Nostr <signed-event>
   ```

2. **Haven UI から**（将来のバージョン）

3. **手動で**
   ```bash
   start-cli service exec haven rm /data/blossom/<sha256>
   ```

### Q28: Blossom のストレージクォータは？

**A:** デフォルトでは無制限ですが、設定可能：

```
Config → Blossom Settings
→ Storage Limit (GB): 50
```

制限に達すると、新規アップロードが拒否されます。

---

## セキュリティ

### Q29: Haven はどれくらい安全ですか？

**A:** セキュリティ対策：

1. **Tor-only**: IP アドレスの秘匿
2. **NIP-42 Auth**: 認証された接続のみ
3. **WoT**: 信頼ネットワークによるスパム防止
4. **暗号署名検証**: 全イベントの署名確認
5. **サンドボックス**: Docker コンテナ内で実行

### Q30: nsec（秘密鍵）を Haven に渡す必要がありますか？

**A:** **いいえ！** Haven は npub（公開鍵）のみを必要とします。

- ✅ **Haven に設定**: npub1...（公開鍵）
- ❌ **絶対に渡さない**: nsec1...（秘密鍵）

秘密鍵は常にクライアント（Amethyst, Damus など）が管理します。

### Q31: バックアップは暗号化されますか？

**A:** 
- **Start9 ネイティブバックアップ**: 自動的に暗号化
- **S3 クラウドバックアップ**: 転送中は暗号化、保存時は S3 の設定次第

推奨: 機密データは常に暗号化バックアップを使用。

### Q32: Haven が侵害された場合は？

**A:** 影響範囲：

| データ | リスク | 対策 |
|-------|--------|------|
| **公開イベント** | 低（既に公開） | - |
| **DM（Kind 4）** | 高（非推奨） | Gift Wrap (Kind 1059) 使用 |
| **Gift Wrap DM** | 低（暗号化済） | - |
| **Blossom ファイル** | 中 | 機密ファイルはアップロードしない |
| **npub** | 低（公開情報） | - |

**重要**: Haven は npub のみを持ち、nsec（秘密鍵）は持ちません。

### Q33: DDoS 攻撃への対策は？

**A:** Haven の防御メカニズム：

1. **Tor Hidden Service**: 直接の IP アドレスを隠蔽
2. **Rate Limiting**: IP ごとの接続・イベント制限
3. **WoT**: 信頼できないユーザーをブロック
4. **Auth 要求**: 認証が必要なエンドポイント

### Q34: ログには何が記録されますか？

**A:** ログ内容：

**記録される**:
- イベント ID
- イベント Kind
- 公開鍵（pubkey）
- タイムスタンプ
- 接続情報（IP はハッシュ化）

**記録されない**:
- イベントの内容
- DM の中身
- 秘密鍵（nsec）
- 個人情報

ログレベルで詳細度を調整可能。

---

## その他

### Q35: Haven のロードマップは？

**A:** 計画中の機能：

**v1.1** (Q1 2025):
- Prometheus メトリクスエクスポート
- Grafana ダッシュボード
- 高度なレート制限
- WoT アルゴリズム改善

**v1.2** (Q2 2025):
- NIP-50 (検索機能)
- NIP-65 (リレーリストメタデータ)
- カスタムポリシー

**v2.0** (Q3 2025):
- ビルトイン Nostr クライアント UI
- アナリティクスダッシュボード
- マルチテナント（オプション）

### Q36: コミュニティに参加するには？

**A:** 
- **GitHub Issues**: https://github.com/bitvora/haven/issues
- **Start9 Community**: https://community.start9.com
- **Nostr**: @bitvora
- **Matrix**: [Start9 Dev Channel](https://matrix.to/#/#start9:matrix.org)

### Q37: Haven に貢献するには？

**A:** 貢献方法：

1. **コード**
   - バグ修正
   - 新機能実装
   - テスト追加

2. **ドキュメント**
   - 翻訳
   - チュートリアル作成
   - FAQ 拡充

3. **テスト**
   - バグレポート
   - ベータテスト
   - パフォーマンステスト

4. **コミュニティ**
   - 質問への回答
   - サポート
   - 普及活動

詳細: [CONTRIBUTING.md](../CONTRIBUTING.md)

### Q38: ライセンスは？

**A:** Haven は **MIT License** です。

- ✅ 商用利用可能
- ✅ 改変可能
- ✅ 配布可能
- ✅ 私的利用可能

詳細: [LICENSE](../LICENSE)

### Q39: Start9 以外のプラットフォームでも動きますか？

**A:** はい！Haven は以下でも動作します：

- **Umbrel**: Docker Compose で実行
- **Raspberry Pi**: 直接インストール
- **VPS**: Linux サーバーで実行
- **Windows/Mac**: Docker Desktop で実行

Start9 パッケージは便利なインストール方法の1つです。

### Q40: 質問がここにありません

**A:** お気軽にお問い合わせください：

1. **GitHub Issues**: https://github.com/bitvora/haven/issues/new
2. **Start9 Forum**: https://community.start9.com
3. **Nostr**: DM を @bitvora に送信

---

## 📝 ドキュメント更新履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0.0 | 2025-12-24 | 初版作成 |

---

## 🔗 関連ドキュメント

- [実装計画書](./start9-packaging-plan.md)
- [技術仕様書](./start9-technical-spec.md)
- [実装チェックリスト](./start9-implementation-checklist.md)
- [クイックスタートガイド](./start9-quickstart.md)

---

**メンテナー**: Oracle + AI Assistant  
**コントリビューター歓迎**: PR を送ってください！

---

_質問がある場合は、遠慮なく Issue を作成してください。_ 🙏

