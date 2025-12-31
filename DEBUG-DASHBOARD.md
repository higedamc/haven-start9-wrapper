# 🔍 Dashboard トラブルシューティングガイド

## 現在の状況

Web Interface のヘルスチェックが警告（⚠️）になっている。

## 🔎 確認手順

### 1. ログを確認

Start9 UIで Haven のログを確認：

```
Services → Haven → Logs
```

以下のメッセージを探す：
- ✅ `🔗 listening at 0.0.0.0:3355` - サーバーが起動している
- ❌ エラーメッセージ（template not found, panic等）
- ❌ 404エラー

### 2. LAUNCH UI でアクセス

1. **LAUNCH UI** ボタンをクリック
2. 表示される内容を確認：
   - ✅ Haven のランディングページ（紫色）→ 正常
   - ❌ エラーページ → 問題あり
3. URL を確認：`http://<onion-address>.local/`

### 3. ダッシュボードに直接アクセス

ブラウザのアドレスバーに入力：
```
http://<your-onion-address>.local/dashboard
```

期待される結果：
- ✅ Database Dashboard が表示される
- ❌ 404 Not Found → ルーティングの問題
- ❌ 500 Internal Server Error → テンプレートの問題

### 4. API エンドポイントをテスト

ブラウザで以下にアクセス：
```
http://<your-onion-address>.local/api/stats
```

期待される結果：
- ✅ JSON が表示される（例：`{"stats":[...],"total":0}`）
- ❌ 404 → APIルーティングの問題

## 🐛 考えられる問題と解決策

### 問題1: ダッシュボードボタンが見えない

**症状**: ランディングページは表示されるが、「📊 View Database Dashboard」ボタンがない

**原因**: 古い `index.html` が使われている（新しいバージョンがビルドされていない）

**解決策**:
```bash
# 再ビルド
cd /path/to/haven-start9-wrapper
make clean
make

# 再インストール
# Start9 UI で Haven をアンインストール → 新しい .s9pk をインストール
```

---

### 問題2: /dashboard にアクセスすると 404

**症状**: `/dashboard` にアクセスすると "Not Found" エラー

**原因**: 
- ルーティングが正しく設定されていない
- 古い Haven バイナリが使われている

**解決策**:
1. Haven submodule を最新にする：
```bash
cd haven
git pull origin main
cd ..
git add haven
git commit -m "update: haven submodule"
```

2. 再ビルド：
```bash
make clean
make
```

---

### 問題3: Template not found エラー

**症状**: ログに `template not found` や `no such file or directory` エラー

**原因**: `templates/dashboard.html` が Docker image に含まれていない

**確認**:
```bash
# コンテナ内でファイルを確認
docker exec <container-id> ls -la /app/templates/
# dashboard.html があるか確認
```

**解決策**:
Haven submodule 内の `templates/` ディレクトリに `dashboard.html` が存在するか確認：
```bash
ls haven/templates/dashboard.html
```

なければ、Haven リポジトリに追加する必要があります。

---

### 問題4: ヘルスチェックが常に警告

**症状**: Haven は動作しているが、ヘルスチェックだけ警告

**原因**: ヘルスチェックスクリプトが期待する応答を受け取っていない

**解決策**: ヘルスチェックを改善（後述）

---

## 🔧 ヘルスチェック改善（オプション）

現在のヘルスチェックを改善するには：

### 方法1: より詳細なチェック

`assets/compat/check-web.sh` を編集：

```bash
#!/bin/bash
set -e

# Check HTTP response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3355/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ]; then
    echo '{"status":"success","message":"Haven is running and accessible"}'
    exit 0
else
    echo '{"status":"error","message":"Haven returned HTTP '$HTTP_CODE'"}'
    exit 1
fi
```

### 方法2: Dashboard を直接チェック

```bash
#!/bin/bash
set -e

# Check dashboard endpoint
if curl -sf http://localhost:3355/dashboard | grep -q "Database Dashboard"; then
    echo '{"status":"success","message":"Haven Dashboard is accessible"}'
    exit 0
else
    echo '{"status":"error","message":"Dashboard not accessible"}'
    exit 1
fi
```

---

## 📊 ログの読み方

Haven のログで確認すべきポイント：

### 正常起動のログ例

```
🚀 HAVEN 1.1.6 is booting up
✅ Blob stored successfully
🔗 listening at 0.0.0.0:3355
```

### エラーの例

```
❌ template not found: dashboard.html
panic: runtime error: ...
404: /dashboard not found
```

---

## 🎯 クイックフィックス

すぐに試せること：

### 1. Haven を再起動
```
Start9 UI → Haven → RESTART
```

### 2. ブラウザキャッシュをクリア
```
Ctrl+Shift+Delete (または Cmd+Shift+Delete)
```

### 3. 別のブラウザで試す
Torブラウザや別のブラウザでアクセス

---

## 📝 報告してもらいたい情報

問題が解決しない場合、以下の情報を教えてください：

1. **Haven のログ** (最後の50行)
2. **LAUNCH UI をクリックした時の画面**
3. **`/dashboard` にアクセスした時の画面**
4. **`/api/stats` にアクセスした時のレスポンス**
5. **Haven のバージョン** (Properties画面で確認)

---

## 🔄 完全リセット手順

すべてリセットして最初からやり直す場合：

```bash
# 1. ローカルで再ビルド
cd /path/to/haven-start9-wrapper
make clean-all
make

# 2. Start9 でアンインストール
Start9 UI → Haven → UNINSTALL

# 3. データ削除（オプション - 注意！）
# データを保持したい場合はスキップ

# 4. 再インストール
Start9 UI → Sideload Service → haven.s9pk をアップロード

# 5. 設定
OWNER_NPUB を設定

# 6. 起動
START をクリック

# 7. 確認
LAUNCH UI → 「📊 View Database Dashboard」をクリック
```

---

## ✅ 動作確認チェックリスト

- [ ] Haven が起動している（STOP/RESTARTボタンが表示）
- [ ] LAUNCH UI をクリックするとランディングページが表示
- [ ] ランディングページに「📊 View Database Dashboard」ボタンがある
- [ ] ダッシュボードボタンをクリックするとダッシュボードが表示
- [ ] 統計情報が表示される（Total Events等）
- [ ] Kind カードが表示される
- [ ] カードをクリックするとJSON が表示される
- [ ] ヘルスチェックが緑色（✓）になっている

---

**作成日**: 2025-12-27

