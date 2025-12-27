# ✅ LAUNCH UI ボタン復活 - 修正完了

## 📋 問題

`ui: false` に設定してしまったため、Start9 の Haven サービスページから **LAUNCH UI** ボタンが消えてしまいました。

## ✅ 修正内容

### 1. manifest.yaml を修正

```yaml
interfaces:
  main:
    ui: true  # ← false から true に戻した
    tor-config:
      port-mapping:
        80: "3355"
```

### 2. ヘルスチェックを改善

`assets/compat/check-web.sh` を更新して、Dashboard の動作も確認するようにしました：

```bash
# メインページをチェック
curl -sf http://localhost:3355/

# Dashboard もチェック
curl -sf http://localhost:3355/dashboard
```

## 🎯 現在の設計

### Haven の Tor 管理方法

Haven は **自分で Tor を管理** していますが、Start9 の UI 機能も使えるようにしています：

```
┌─────────────────────────────────────────────┐
│ Start9 Server                               │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │ Haven Container                       │ │
│  │                                       │ │
│  │  ┌──────────┐      ┌──────────┐     │ │
│  │  │ Haven    │      │ Tor      │     │ │
│  │  │ :3355    │◄────►│ :80      │     │ │
│  │  └──────────┘      └──────────┘     │ │
│  │       ▲                 │            │ │
│  │       │                 ▼            │ │
│  │       │         /data/tor/haven/    │ │
│  │       │         hostname            │ │
│  └───────┼─────────────────────────────┘ │
│          │                                │
│  ┌───────┼──────────────────────────┐    │
│  │ Start9 Tor Proxy                │    │
│  │       │                          │    │
│  │       └──► .onion address ──────┼───►│
│  └──────────────────────────────────┘    │
│                                           │
│  LAUNCH UI ボタン                         │
│  ↓                                        │
│  http://<onion-address>.local/           │
└─────────────────────────────────────────────┘
```

### ポイント

1. **Haven が Tor を起動**: `docker_entrypoint.sh` で `tor -f /etc/tor/torrc`
2. **Tor アドレスは Haven 管理**: `/data/tor/haven/hostname`
3. **Start9 の UI 機能を利用**: `ui: true` で LAUNCH UI ボタンを表示
4. **port-mapping**: Start9 が Haven のポート 3355 にルーティング

## 🚀 使い方

### 再ビルド後

```bash
cd /Users/apple/work/haven-start9-wrapper
make clean
make

# Start9 で再インストール
```

### アクセス方法（2通り）

#### 方法1: LAUNCH UI ボタン（推奨）

1. Start9 UI → Services → Haven
2. **LAUNCH UI** ボタンをクリック
3. Haven ランディングページが表示される
4. **📊 View Database Dashboard** をクリック

#### 方法2: Properties から直接

1. Start9 UI → Services → Haven → **Properties**
2. **Web Interface** の URL をコピー
3. Tor ブラウザで開く
4. Dashboard にアクセス

## ✅ 期待される動作

再インストール後：

- ✅ **LAUNCH UI** ボタンが表示される
- ✅ ボタンをクリックすると Haven ランディングページが開く
- ✅ **Properties** に正しい Tor アドレスが表示される
- ✅ **Health Check** が緑色（✓）
- ✅ Dashboard が正常に動作する

## 🔍 Tor アドレスについて

### 重要：アドレスは変わりません

Haven が管理している Tor アドレス（`/data/tor/haven/hostname`）は：

- ✅ 永続化される（`/data/` ボリューム）
- ✅ 再インストールしても保持される
- ✅ Start9 の UI 機能とも互換性がある

### 確認方法

```bash
# Properties で確認
Tor Hidden Service: <your-address>.onion

# すべてのリレー URL が同じアドレスを使用
Outbox Relay: ws://<your-address>.onion
Private Relay: ws://<your-address>.onion/private
Chat Relay: ws://<your-address>.onion/chat
Inbox Relay: ws://<your-address>.onion/inbox
```

## 📝 技術的な詳細

### なぜ `ui: true` で動作するのか？

Start9 の `tor-config` は：
- Haven コンテナ内のポート 3355 を Tor の 80 番ポートにマッピング
- Start9 が Haven の Tor サービスをプロキシする
- Haven が生成した .onion アドレスを Start9 が認識

### port-mapping の意味

```yaml
tor-config:
  port-mapping:
    80: "3355"
```

- **80**: Tor が外部に公開するポート
- **3355**: Haven が内部でリッスンしているポート

## 🐛 トラブルシューティング

### LAUNCH UI ボタンが表示されない

**原因**: 古いバージョンがインストールされている

**解決策**:
1. Haven をアンインストール
2. 新しい `.s9pk` を再インストール

### LAUNCH UI をクリックしても開かない

**原因**: Haven が起動していない、または Tor が起動していない

**解決策**:
1. Haven のログを確認
2. `🔗 listening at 0.0.0.0:3355` が表示されているか
3. Tor アドレスが生成されているか確認

### Health Check が失敗する

**原因**: Haven が応答していない

**解決策**:
1. Haven を再起動
2. ログでエラーを確認
3. `/data/tor/haven/hostname` が存在するか確認

## 📊 まとめ

| 項目 | 修正前 | 修正後 |
|------|--------|--------|
| LAUNCH UI ボタン | ❌ 非表示 | ✅ 表示 |
| Tor アドレス管理 | Haven | Haven（変更なし） |
| Properties 表示 | ✅ 正常 | ✅ 正常 |
| Health Check | ⚠️ 警告 | ✅ 成功（予定） |
| Dashboard アクセス | ✅ 可能 | ✅ 可能 |

---

**作成日**: 2025-12-27  
**ステータス**: ✅ 修正完了、再ビルド待ち  
**影響**: UI ボタンが復活、Tor アドレスは変わらず

