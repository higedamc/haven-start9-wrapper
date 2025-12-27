# 🔄 Haven ダッシュボード版 - 再インストール手順

## 📋 問題の原因

Haven は **submodule** なので、ダッシュボード機能の変更が Haven リポジトリ内でコミットされていませんでした。

✅ **修正完了**: Haven submodule にダッシュボード機能がコミットされました！

---

## 🚀 再インストール手順

### Step 1: ビルド（ローカル）

```bash
cd /Users/apple/work/haven-start9-wrapper

# クリーンビルド
make clean
make

# 完了まで 5-10分かかります
# "✅ Package created: haven.s9pk" と表示されれば成功
```

---

### Step 2: Start9 で現在の Haven をアンインストール

1. Start9 UI を開く
2. **Services** → **Haven** をクリック
3. **Actions** → **Uninstall** をクリック
4. 確認ダイアログで **Uninstall** をクリック

⚠️ **注意**: データは保持されますが、念のためバックアップを推奨

---

### Step 3: 新しいパッケージをインストール

1. Start9 UI で **System** → **Sideload Service** をクリック
2. **Choose File** をクリック
3. ビルドした `haven.s9pk` を選択
4. **Install** をクリック
5. インストール完了を待つ（1-2分）

---

### Step 4: 設定

1. Haven の設定画面を開く
2. **Owner Npub** を設定（以前と同じ値）
3. その他の設定も必要に応じて入力
4. **Save** をクリック

---

### Step 5: 起動

1. Haven サービスページで **START** をクリック
2. 起動完了を待つ（30秒〜1分）
3. ステータスが **Running** になることを確認

---

### Step 6: ダッシュボードを確認

1. **LAUNCH UI** をクリック
2. Haven ランディングページが表示されることを確認
3. **📊 View Database Dashboard** ボタンをクリック
4. Database Dashboard が表示されることを確認

**期待される表示**:
- 📊 Haven Database Dashboard（タイトル）
- Total Events: X
- Event Kinds: Y
- Kind カード（あればイベントデータが表示）

---

### Step 7: ヘルスチェック確認

Haven サービスページで：
- **Web Interface** が緑色のチェックマーク（✓）になっていることを確認

---

## ✅ 動作確認チェックリスト

- [ ] ビルドが成功した
- [ ] Start9 にインストールできた
- [ ] Haven が起動した（Running状態）
- [ ] LAUNCH UI をクリックするとランディングページが表示
- [ ] **📊 View Database Dashboard** ボタンが表示されている
- [ ] ダッシュボードボタンをクリックすると Dashboard が表示
- [ ] ヘルスチェックが緑色（✓）

---

## 🐛 トラブルシューティング

### ビルドが失敗する

```bash
# 依存関係を再インストール
./prepare.sh

# 再度ビルド
make clean
make
```

### インストールが失敗する

- パッケージファイルサイズを確認：`ls -lh haven.s9pk`
- 100MB以上あれば正常
- 小さすぎる場合は再ビルド

### ダッシュボードボタンが表示されない

1. Haven のログを確認：
```
Services → Haven → Logs
```

2. エラーメッセージを探す

3. [DEBUG-DASHBOARD.md](DEBUG-DASHBOARD.md) を参照

### ヘルスチェックが警告のまま

1. Haven を再起動：**RESTART** ボタン
2. 1分待つ
3. それでも警告なら Haven のログを確認

---

## 📊 既存データについて

### データは保持されます

アンインストール→再インストールしても、以下は保持されます：
- ✅ データベース (`/data/db/`)
- ✅ Blossom ファイル (`/data/blossom/`)
- ✅ Tor アドレス (`/data/tor/`)
- ✅ インポートされたイベント

### データを確認

再インストール後、ダッシュボードで：
- 以前と同じ Event 数が表示されるはず
- Kind カードも以前と同じ内容

---

## 🎉 完了後

ダッシュボードが正常に表示されたら：

1. **Import Past Notes** を実行（まだの場合）
2. インポート完了後、ダッシュボードで確認
3. Event 数が増えていることを確認
4. Kind カードをクリックして JSON を確認

---

## 📝 次回のバージョンアップ

次回からは Haven submodule の変更も含めて管理されるので、スムーズにいくはずです！

バージョンアップ方法：
```bash
# 自動バージョンアップ
make bump-patch

# ビルド＆インストール
make clean && make
# Start9 で再インストール
```

---

**作成日**: 2025-12-27  
**ステータス**: Haven submodule コミット済み、再ビルド待ち

