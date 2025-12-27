# ✅ .local ドメインアクセス対応 - 修正完了

## 📋 問題の理解

Haven は `.onion` アドレスでしかアクセスできませんでしたが、Start9 では **`.local` ドメイン** でもアクセスできるべきでした。

## 🔍 Synapse の実装から学んだこと

Synapse には **2つの interface** があります：

```yaml
interfaces:
  main:           # Homeserver - .onion のみ
    ui: false
    tor-config: ...
    lan-config: null
    
  admin:          # Admin Portal - .local でアクセス可能
    ui: true
    tor-config: ...
    lan-config:   # ← これが .local を可能にする！
      443:
        ssl: true
        internal: 8080
```

### 重要なポイント

1. **`lan-config`**: ローカルネットワーク（.local）でのアクセスを設定
2. **SSL証明書**: `type: certificate` で自動生成
3. **複数の interface**: 用途別に分けることができる

---

## ✅ Haven への適用

### 修正内容

#### 1. 2つの interface を作成

```yaml
interfaces:
  main:
    name: Nostr Relay Interface
    description: Main Nostr relay endpoint (WebSocket) and Blossom media server via .onion
    tor-config:
      port-mapping:
        80: "3355"
    lan-config: null
    ui: false      # .onion 専用
    protocols:
      - tcp
      - http
      - ws
      
  ui:              # ← NEW!
    name: Haven Web Interface
    description: Web dashboard and management interface
    tor-config:
      port-mapping:
        80: "3355"
    lan-config:    # ← .local アクセスを有効化
      443:
        ssl: true
        internal: 3355
    ui: true       # ← LAUNCH UI ボタンを表示
    protocols:
      - tcp
      - http
```

#### 2. SSL証明書ボリュームを追加

```yaml
volumes:
  main:
    type: data
  ui-cert:         # ← NEW!
    type: certificate
    interface-id: ui
```

#### 3. コンテナに証明書をマウント

```yaml
main:
  mounts:
    main: /data
    ui-cert: /mnt/ui-cert  # ← NEW!
```

---

## 🎯 期待される動作

### アクセス方法（3通り）

#### 方法1: LAUNCH UI ボタン（.local）- 推奨 ✨

```
Start9 UI → Haven → LAUNCH UI をクリック
  ↓
https://<haven-ui-address>.local/
  ↓
Haven ランディングページ（SSL接続）
  ↓
📊 View Database Dashboard をクリック
```

**特徴**:
- ✅ SSL 暗号化（HTTPS）
- ✅ Tor 不要（ローカルネットワーク経由）
- ✅ 高速アクセス
- ✅ ブラウザの警告なし（Start9 の証明書）

#### 方法2: .onion アドレス（Tor経由）

```
Tor ブラウザで http://<onion-address>.onion/ を開く
  ↓
Haven ランディングページ
  ↓
Dashboard にアクセス
```

**特徴**:
- ✅ 完全匿名
- ✅ 外部からアクセス可能
- ⚠️ Tor 経由なので少し遅い

#### 方法3: Properties から

```
Properties → Web Interface の URL をコピー
  ↓
ブラウザで開く
```

---

## 🏗️ アーキテクチャ

### 修正後の構成

```
┌─────────────────────────────────────────────────┐
│ Start9 Server                                   │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Haven Container                          │  │
│  │                                          │  │
│  │  ┌──────────┐      ┌──────────┐        │  │
│  │  │ Haven    │      │ Tor      │        │  │
│  │  │ :3355    │◄────►│ :80      │        │  │
│  │  └──────────┘      └──────────┘        │  │
│  │       ▲                 │               │  │
│  │       │                 ▼               │  │
│  │       │         /data/tor/haven/       │  │
│  │       │         hostname               │  │
│  └───────┼──────────────────────────────────┘  │
│          │                                     │
│  ┌───────┴─────────────────────────────────┐  │
│  │ Start9 Routing                          │  │
│  │                                         │  │
│  │  Interface: main (.onion)              │  │
│  │  ├─ ws://<onion>.onion                 │  │
│  │  └─ http://<onion>.onion               │  │
│  │                                         │  │
│  │  Interface: ui (.local) ← NEW!         │  │
│  │  ├─ https://<ui>.local/ (LAUNCH UI)   │  │
│  │  └─ SSL証明書自動生成                   │  │
│  └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 📊 Interface の比較

| 項目 | main (Nostr Relay) | ui (Web Interface) |
|------|-------------------|-------------------|
| 目的 | Nostr クライアント接続 | Web UI アクセス |
| プロトコル | WebSocket, HTTP | HTTP, HTTPS |
| アクセス | .onion のみ | .local + .onion |
| SSL | なし（Tor暗号化） | あり（Start9証明書） |
| LAUNCH UI | ❌ | ✅ |
| 用途 | リレー接続、Blossom | Dashboard、管理 |

---

## 🚀 再ビルドとインストール

### Step 1: ビルド

```bash
cd /Users/apple/work/haven-start9-wrapper
make clean
make
```

### Step 2: 再インストール

1. Start9 UI → Haven → **Uninstall**
2. **System** → **Sideload Service**
3. `haven.s9pk` をアップロード
4. **Install**

### Step 3: 設定

1. **Owner Npub** を設定
2. その他の設定を入力
3. **Save**

### Step 4: 起動

1. **START** をクリック
2. 起動完了を待つ

### Step 5: LAUNCH UI をクリック

1. **LAUNCH UI** ボタンをクリック
2. **https://<haven-ui>.local/** が開く
3. SSL 接続で Haven ランディングページが表示される
4. **📊 View Database Dashboard** をクリック

---

## ✅ 期待される結果

### Interfaces 画面

Haven サービスページの **Interfaces** セクションに **2つの interface** が表示される：

```
Interfaces:
  ├─ Nostr Relay Interface
  │   └─ ws://<onion-address>.onion
  │
  └─ Haven Web Interface (LAUNCH UI)
      ├─ https://<ui-address>.local/
      └─ http://<onion-address>.onion/
```

### Properties 画面

```
Haven Version: 1.1.6
Service Status: Running
Tor Hidden Service: <onion-address>.onion
Web Interface: http://<onion-address>.onion/
Outbox Relay: ws://<onion-address>.onion
Private Relay: ws://<onion-address>.onion/private
Chat Relay: ws://<onion-address>.onion/chat
Inbox Relay: ws://<onion-address>.onion/inbox
Blossom Media Server: http://<onion-address>.onion
Database Size: ...
Media Storage: ...
Total Storage: ...
```

### Health Checks

- ✅ **Web Interface**: 緑色（✓）

---

## 🔒 セキュリティ

### SSL証明書

- Start9 が自動的に生成
- ローカルネットワーク内でのみ有効
- ブラウザの警告なし（Start9 の CA 証明書をインストール済み）

### アクセス制限

- **`.local` ドメイン**: ローカルネットワークのみ
- **`.onion` アドレス**: Tor ネットワーク経由でどこからでも

---

## 🐛 トラブルシューティング

### LAUNCH UI ボタンが表示されない

**原因**: 古いバージョンがインストールされている

**解決策**: Haven を再インストール

### LAUNCH UI をクリックしても開かない

**原因**: `ui` interface が正しく設定されていない

**確認**:
1. Interfaces に "Haven Web Interface" が表示されているか
2. `.local` アドレスが生成されているか

### SSL証明書エラー

**原因**: Start9 の CA 証明書がブラウザにインストールされていない

**解決策**: 
1. Start9 ドキュメントに従って CA 証明書をインストール
2. ブラウザを再起動

### .local にアクセスできない

**原因**: ローカルネットワークに接続されていない

**確認**:
1. Start9 サーバーと同じネットワークに接続しているか
2. VPN を使用している場合は無効化

---

## 📝 技術的な詳細

### lan-config の仕組み

```yaml
lan-config:
  443:              # 外部ポート（HTTPS）
    ssl: true       # SSL を有効化
    internal: 3355  # コンテナ内のポート
```

Start9 は：
1. `<service-ui>.local` ドメインを生成
2. SSL証明書を自動生成（`/mnt/ui-cert/`）
3. HTTPS (443) → HTTP (3355) にリバースプロキシ
4. ブラウザからは HTTPS でアクセス可能

### 証明書の場所

```
/mnt/ui-cert/
├── main.cert.pem  # SSL証明書
└── main.key.pem   # 秘密鍵
```

Haven は現在これらを使用していませんが、将来的に Haven 自身で HTTPS を提供する場合に使用できます。

---

## 🎉 メリット

### 修正前

- ❌ .onion アドレスのみ
- ❌ Tor ブラウザが必要
- ❌ 接続が遅い
- ❌ 設定が複雑

### 修正後

- ✅ .local ドメインでアクセス可能
- ✅ 通常のブラウザで OK
- ✅ 高速アクセス（ローカルネットワーク）
- ✅ LAUNCH UI ボタンで簡単アクセス
- ✅ SSL 暗号化
- ✅ .onion も引き続き使用可能

---

## 🔮 今後の改善案

1. **Haven 自身で HTTPS 対応**
   - `/mnt/ui-cert/` の証明書を使用
   - nginx をコンテナに追加

2. **LAN アクセスの最適化**
   - ローカルネットワーク検出
   - 自動リダイレクト

3. **複数の UI interface**
   - Dashboard 専用 interface
   - Blossom 専用 interface

---

**作成日**: 2025-12-27  
**ステータス**: ✅ 修正完了、テスト待ち  
**影響**: .local ドメインでアクセス可能、Tor アドレスは変わらず

