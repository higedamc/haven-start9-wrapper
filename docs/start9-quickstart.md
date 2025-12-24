# Haven Start9 Quick Start Guide

## 🚀 TL;DR - 最速スタート

```bash
# 1. プロジェクトクローン
git clone --recurse-submodules https://github.com/YOUR_USERNAME/haven-start9-wrapper.git
cd haven-start9-wrapper

# 2. Start9 ブランチ作成
git checkout -b feature/start9-packaging

# 3. 必要なファイルを追加（このガイドを参照）

# 4. ビルド
make

# 5. インストール（Start9 が必要）
start-cli package install haven.s9pk
```

---

## 📁 ディレクトリ構造

実装完了後のディレクトリ構造：

```
haven/
├── .github/
│   └── workflows/
│       └── build.yml                    # CI/CD
├── assets/
│   └── compat/
│       ├── config_get.sh                # 設定取得スクリプト
│       ├── config_set.sh                # 設定保存スクリプト
│       ├── properties.sh                # プロパティ表示
│       └── check-web.sh                 # ヘルスチェック
├── docs/
│   ├── build.md                         # 既存
│   ├── verify.md                        # 既存
│   ├── start9-packaging-plan.md         # 実装計画書（新規）
│   ├── start9-technical-spec.md         # 技術仕様書（新規）
│   ├── start9-implementation-checklist.md # チェックリスト（新規）
│   └── start9-quickstart.md             # このファイル
├── templates/
│   ├── index.html
│   └── static/
├── Dockerfile                           # Docker イメージ定義（新規）
├── docker_entrypoint.sh                 # エントリポイント（新規）
├── torrc                                # Tor 設定（新規）
├── manifest.yaml                        # Start9 マニフェスト（新規）
├── instructions.md                      # ユーザー向け説明（新規）
├── icon.png                             # アイコン（新規）
├── Makefile                             # ビルド自動化（新規）
├── prepare.sh                           # ビルド環境準備（新規）
├── go.mod
├── go.sum
├── *.go                                 # Go ソースコード
├── LICENSE
└── README.md
```

---

## 🛠️ 開発環境セットアップ

### 必須ツール

```bash
# 1. Docker & Docker Buildx
docker --version  # Docker version 20.10+
docker buildx version

# 2. Go
go version  # go1.24+

# 3. Start9 SDK
start-sdk --version

# 4. yq (YAML processor)
yq --version

# 5. Git
git --version
```

### ツールインストール（Ubuntu/Debian）

```bash
# Docker
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER

# Docker Buildx
docker buildx install
docker buildx create --use

# Go
wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Start9 SDK
git clone https://github.com/Start9Labs/start-os.git
cd start-os && git submodule update --init --recursive
make sdk
start-sdk init

# yq
sudo wget -qO /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Start9 Server テスト環境

```bash
# オプション 1: 物理デバイス
# - Start9 Server Pure
# - DIY x86/ARM デバイス

# オプション 2: 仮想マシン
# VirtualBox/QEMU で StartOS をインストール
```

---

## 📝 実装ステップ

### Step 1: Dockerfile 作成

```bash
# ファイル作成
touch Dockerfile

# 内容を start9-packaging-plan.md から参照してコピー
```

**重要ポイント**:
- マルチステージビルド（builder + runtime）
- Alpine Linux ベース
- Tor インストール
- 非 root ユーザー（haven）
- Tini エントリポイント

### Step 2: docker_entrypoint.sh 作成

```bash
# ファイル作成
touch docker_entrypoint.sh
chmod +x docker_entrypoint.sh

# 内容を start9-packaging-plan.md から参照してコピー
```

**重要ポイント**:
- 環境変数バリデーション
- `.env` ファイル動的生成
- Tor 起動と .onion アドレス取得
- SIGTERM ハンドリング

### Step 3: manifest.yaml 作成

```bash
# ファイル作成
touch manifest.yaml

# 内容を start9-packaging-plan.md から参照してコピー
```

**重要ポイント**:
- パッケージ ID: `haven`
- バージョン: 現在の Haven バージョンと同期
- Tor インターフェース定義
- ボリュームマウント: `/data`

### Step 4: instructions.md 作成

```bash
# ファイル作成
touch instructions.md

# 内容を start9-packaging-plan.md から参照してコピー
```

**重要ポイント**:
- 初心者にも分かりやすい説明
- Amethyst 設定例
- トラブルシューティング

### Step 5: アセットファイル作成

```bash
# アイコン
# 256x256px PNG ファイルを用意
cp /path/to/your/icon.png ./icon.png

# Config スクリプト
mkdir -p assets/compat
touch assets/compat/config_get.sh
touch assets/compat/config_set.sh
touch assets/compat/properties.sh
touch assets/compat/check-web.sh
chmod +x assets/compat/*.sh
```

### Step 6: Makefile 作成

```bash
# ファイル作成
touch Makefile

# 内容を start9-packaging-plan.md から参照してコピー
```

### Step 7: prepare.sh 作成

```bash
# ファイル作成
touch prepare.sh
chmod +x prepare.sh

# 内容を start9-packaging-plan.md から参照してコピー
```

---

## 🔨 ビルドプロセス

### 初回ビルド

```bash
# 1. 環境準備
./prepare.sh

# 2. Docker イメージビルド
make docker-images.tar

# 3. パッケージング
make

# 4. 検証
make verify
```

### ビルド出力

```
haven.s9pk              # インストール可能なパッケージ
docker-images.tar       # Docker イメージ
```

### トラブルシューティング

```bash
# ビルドエラー時
make clean
./prepare.sh
make

# Docker キャッシュクリア
docker system prune -a

# SDK 問題
start-sdk init
start-sdk --version
```

---

## 🧪 テスト

### ローカルテスト

```bash
# Docker イメージテスト
docker run -it --rm \
  -e OWNER_NPUB=npub1... \
  -e TOR_ADDRESS=test.onion \
  -v $(pwd)/test-data:/data \
  haven:latest

# エントリポイントテスト
docker run -it --rm \
  haven:latest \
  /bin/sh
```

### Start9 インストールテスト

```bash
# サイドロード
# Start9 UI → System → Sideload Service
# → haven.s9pk をアップロード

# または CLI
start-cli auth login
start-cli package install haven.s9pk

# ステータス確認
start-cli package list
start-cli service logs haven
```

### Tor 接続テスト

```bash
# .onion アドレス取得
# Start9 UI → Services → Haven → Properties

# Tor 経由でアクセス
torsocks curl http://<your-address>.onion

# WebSocket テスト
wscat --socks5 127.0.0.1:9050 \
  -c ws://<your-address>.onion \
  -x '["REQ","test",{"limit":1}]'
```

---

## 🐛 デバッグ

### ログ確認

```bash
# Start9 CLI
start-cli service logs haven

# Docker コンテナ内
start-cli service exec haven /bin/sh
tail -f /var/log/haven.log
```

### よくある問題

#### 1. Tor アドレスが生成されない

```bash
# Tor サービス確認
docker exec -it haven_main ps aux | grep tor

# Tor ログ確認
docker exec -it haven_main cat /var/log/tor/notices.log

# 手動起動
docker exec -it haven_main tor -f /etc/tor/torrc
```

#### 2. データベース初期化失敗

```bash
# 権限確認
docker exec -it haven_main ls -la /data/db

# 手動初期化
docker exec -it haven_main /app/haven --help
```

#### 3. メモリ不足

```bash
# メモリ使用量確認
docker stats haven_main

# コンテナ再起動
start-cli service restart haven
```

---

## 📦 デプロイ

### GitHub リリース

```bash
# 1. バージョンタグ作成
git tag -a v1.0.0 -m "Initial Start9 release"
git push origin v1.0.0

# 2. GitHub Release 作成
# - Release notes 記入
# - haven.s9pk 添付
# - checksums.txt 添付
```

### Start9 Community Registry

```bash
# 1. Registry fork
gh repo fork start9labs/registry

# 2. パッケージ追加
cd registry
mkdir -p packages/haven
cp /path/to/haven/{manifest.yaml,icon.png,instructions.md} packages/haven/

# 3. Pull Request
git checkout -b add-haven
git add packages/haven
git commit -m "Add Haven service package"
git push origin add-haven
gh pr create
```

---

## 🎯 チェックポイント

実装の各段階で確認すべきこと：

### Checkpoint 1: ビルド成功

- [ ] `make` コマンドがエラーなく完了
- [ ] `haven.s9pk` ファイルが生成される
- [ ] `start-sdk verify` が成功

### Checkpoint 2: インストール成功

- [ ] Start9 にサイドロードできる
- [ ] サービスが起動する
- [ ] ログにエラーがない

### Checkpoint 3: Tor 接続成功

- [ ] .onion アドレスが生成される
- [ ] Tor 経由でアクセスできる
- [ ] WebSocket 接続できる

### Checkpoint 4: 機能確認

- [ ] 4つのリレーすべてアクセス可能
- [ ] Blossom アップロードできる
- [ ] Amethyst で使用できる

---

## 💡 Tips & Best Practices

### コード変更時

```bash
# Haven コード修正後
make clean
make
start-cli package upgrade haven.s9pk
```

### バージョン管理

```bash
# manifest.yaml のバージョンと Git タグを同期
# 例: manifest.yaml の version: 1.0.1 → git tag v1.0.1
```

### パフォーマンス最適化

```bash
# イメージサイズ削減
docker image ls haven:latest

# 不要なレイヤー削除
# Dockerfile で RUN コマンドを結合
```

### セキュリティ

```bash
# 脆弱性スキャン
docker scan haven:latest

# 依存関係更新
go get -u
go mod tidy
```

---

## 🔗 有用なリンク

### Start9 関連

- [Packaging Documentation](https://docs.start9.com/0.3.5.x/developer-docs/packaging.html)
- [Start SDK GitHub](https://github.com/Start9Labs/start-os)
- [Community Registry](https://github.com/start9labs/registry)
- [Community Forum](https://community.start9.com)

### Haven 関連

- [Haven GitHub](https://github.com/bitvora/haven)
- [Haven Issues](https://github.com/bitvora/haven/issues)

### Nostr 関連

- [NIPs Repository](https://github.com/nostr-protocol/nips)
- [NIP-96 (File Storage)](https://github.com/nostr-protocol/nips/blob/master/96.md)
- [Blossom Spec](https://github.com/hzrd149/blossom)

### ツール

- [Docker Documentation](https://docs.docker.com)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [wscat](https://github.com/websockets/wscat)

---

## 🆘 ヘルプが必要？

### コミュニティサポート

- **Start9 Community**: https://community.start9.com
- **Haven GitHub Issues**: https://github.com/bitvora/haven/issues
- **Matrix Dev Channel**: [Start9 Matrix](https://matrix.to/#/#start9:matrix.org)

### よくある質問

詳細は `start9-faq.md` を参照してください。

---

## 🎓 次のステップ

1. ✅ `start9-packaging-plan.md` を熟読
2. ✅ `start9-technical-spec.md` で技術詳細確認
3. ✅ `start9-implementation-checklist.md` でタスク管理
4. 🚀 実装開始！

---

**作成日**: 2025-12-24  
**対象読者**: Haven 開発者・パッケージャー  
**所要時間**: セットアップ 2-3 時間、実装 3-5 週間

---

_Good luck with your implementation! 🚀_

