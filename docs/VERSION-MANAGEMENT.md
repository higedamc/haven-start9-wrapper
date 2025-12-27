# 🔢 Haven Start9 Wrapper - バージョン管理ガイド

## 📋 概要

Haven Start9 Wrapperのバージョンを更新する際に変更が必要なファイルと手順をまとめたガイドです。

## 🎯 バージョン番号の決め方

セマンティックバージョニング（Semantic Versioning）を採用：

```
メジャー.マイナー.パッチ
  1   .  1   .  5
  │      │      └─ バグ修正・軽微な改善
  │      └──────── 新機能追加（後方互換あり）
  └─────────────── 破壊的変更（後方互換なし）
```

### 例
- `1.1.5 → 1.1.6`: バグ修正、軽微な改善
- `1.1.5 → 1.2.0`: 新機能追加（今回のダッシュボード追加など）
- `1.1.5 → 2.0.0`: 設定形式の変更など、破壊的変更

## 📝 変更が必要なファイル

### 🔴 必須（絶対に変更する）

#### 1. `manifest.yaml`
**場所**: 7行目
```yaml
version: 1.1.5  # ← ここを変更
```

**変更例**:
```yaml
version: 1.1.6  # 新しいバージョン
```

**注意**: このファイルが**最も重要**です。Start9はここからバージョンを読み取ります。

---

#### 2. `manifest.yaml` のリリースノート
**場所**: 9行目以降
```yaml
release-notes: |
  **v1.1.6 - Database Dashboard (2025-12-27)**  # ← 新しいバージョンとリリース名
  
  New Features:
  - **Database Dashboard**: View stored Nostr events via web interface
  - **Event Inspector**: Click any kind to view raw JSON data
  - **Statistics View**: See event counts by kind and database
  
  Improvements:
  - Added /api/stats endpoint for event statistics
  - Added /api/events/{kind} endpoint for event retrieval
  - Enhanced main UI with dashboard access button
  
  Documentation:
  - Added Database Dashboard documentation
  - Added Dashboard Testing Guide
  
  # 以前のリリースノート（履歴として残す）
  ---
  **v1.1.5 - Import Notes Feature (2025-12-27)**
  ...
```

---

### 🟡 推奨（デフォルト値として変更）

#### 3. `docker_entrypoint.sh`
**場所**: 83行目と516行目

```bash
# 83行目
RELAY_VERSION=${RELAY_VERSION:-1.1.6}  # ← デフォルト値を更新

# 516行目
log_info "  Version: ${RELAY_VERSION:-1.1.6}"  # ← ログ表示も更新
```

---

#### 4. `scripts/procedures/importNotes.sh`
**場所**: 265行目と284行目

```bash
# 265行目
export RELAY_VERSION=$(yq e '.relay-version // "1.1.6"' /data/start9/config.yaml)

# 284行目
RELAY_VERSION=${RELAY_VERSION:-1.1.6}
```

---

### 🟢 自動（変更不要）

以下のファイルは**自動的に**`manifest.yaml`から読み取るので変更不要：

- ✅ `Makefile` - `VERSION := $(shell yq '.version' manifest.yaml)`
- ✅ Start9 UI - manifest.yamlから自動表示
- ✅ パッケージファイル名 - `haven-1.1.6.s9pk` (自動生成)

---

## 🚀 バージョンアップ手順（完全版）

### Step 1: バージョン番号を決定
```bash
# 現在のバージョンを確認
grep "^version:" manifest.yaml

# 出力例: version: 1.1.5
```

今回の変更内容に応じて新しいバージョンを決定：
- バグ修正 → `1.1.6`
- 新機能追加 → `1.2.0` または `1.1.6`（マイナー機能なら）
- 破壊的変更 → `2.0.0`

**今回（ダッシュボード追加）の推奨**: `1.1.6` または `1.2.0`

---

### Step 2: ファイルを編集

#### 2.1 manifest.yaml
```bash
# エディタで開く
vim manifest.yaml
# または
code manifest.yaml
```

変更箇所：
```yaml
# 7行目
version: 1.1.6

# 9行目以降のリリースノート
release-notes: |
  **v1.1.6 - Database Dashboard (2025-12-27)**
  
  New Features:
  - Database Dashboard with event statistics
  - JSON event viewer
  - Kind-based filtering
```

---

#### 2.2 docker_entrypoint.sh
```bash
# 一括置換（簡単な方法）
sed -i '' 's/1\.1\.5/1.1.6/g' docker_entrypoint.sh

# または手動で編集
# - 83行目: RELAY_VERSION=${RELAY_VERSION:-1.1.6}
# - 516行目: log_info "  Version: ${RELAY_VERSION:-1.1.6}"
```

---

#### 2.3 scripts/procedures/importNotes.sh
```bash
# 一括置換
sed -i '' 's/1\.1\.5/1.1.6/g' scripts/procedures/importNotes.sh

# または手動で編集
# - 265行目: relay-version // "1.1.6"
# - 284行目: RELAY_VERSION=${RELAY_VERSION:-1.1.6}
```

---

### Step 3: バージョンを確認
```bash
# すべてのバージョン参照を確認
grep -r "1\.1\.5" . --include="*.yaml" --include="*.sh" --exclude-dir=haven

# 出力が空なら成功（すべて置き換わった）
```

---

### Step 4: ビルドしてテスト
```bash
# ビルド
make clean
make

# バージョン確認
ls -lh haven.s9pk
# または
unzip -l haven.s9pk | grep manifest

# パッケージ情報を確認
start-sdk inspect haven.s9pk
# Version: 1.1.6 と表示されるはず
```

---

### Step 5: Git コミット
```bash
# 変更をステージング
git add manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh

# コミット
git commit -m "update: version 1.1.6 - Database Dashboard"

# タグを作成（オプション）
git tag v1.1.6
git push origin v1.1.6
```

---

## 📋 バージョンアップチェックリスト

新しいバージョンをリリースする前に、このチェックリストを確認：

### ファイル変更
- [ ] `manifest.yaml` - version フィールド
- [ ] `manifest.yaml` - release-notes セクション
- [ ] `docker_entrypoint.sh` - 2箇所のデフォルト値
- [ ] `scripts/procedures/importNotes.sh` - 2箇所のデフォルト値

### 動作確認
- [ ] `make clean && make` でビルド成功
- [ ] `make verify` でパッケージ検証成功
- [ ] Start9にインストールして起動確認
- [ ] UI上でバージョン表示が正しい

### ドキュメント
- [ ] README.mdに変更があれば更新
- [ ] リリースノートが適切に記載されている
- [ ] 新機能のドキュメントが追加されている

### Git管理
- [ ] 変更をコミット
- [ ] バージョンタグを作成（オプション）
- [ ] GitHubにプッシュ

---

## 🛠️ 便利なコマンド集

### 現在のバージョンを確認
```bash
# manifest.yamlから
yq '.version' manifest.yaml

# または
grep "^version:" manifest.yaml | awk '{print $2}'
```

### すべてのバージョン参照を検索
```bash
# 古いバージョン番号が残っていないか確認
grep -r "1\.1\.5" . \
  --include="*.yaml" \
  --include="*.sh" \
  --include="*.md" \
  --exclude-dir=haven \
  --exclude-dir=.git
```

### 一括置換（慎重に使用）
```bash
# 対象ファイルのみ置換
OLD_VERSION="1.1.5"
NEW_VERSION="1.1.6"

# macOS
sed -i '' "s/${OLD_VERSION}/${NEW_VERSION}/g" manifest.yaml
sed -i '' "s/${OLD_VERSION}/${NEW_VERSION}/g" docker_entrypoint.sh
sed -i '' "s/${OLD_VERSION}/${NEW_VERSION}/g" scripts/procedures/importNotes.sh

# Linux
sed -i "s/${OLD_VERSION}/${NEW_VERSION}/g" manifest.yaml
sed -i "s/${OLD_VERSION}/${NEW_VERSION}/g" docker_entrypoint.sh
sed -i "s/${OLD_VERSION}/${NEW_VERSION}/g" scripts/procedures/importNotes.sh
```

### リリースパッケージの作成
```bash
# releases/ ディレクトリに配布用ファイルを作成
make release

# 出力例:
# releases/haven-1.1.6.s9pk
# releases/haven-1.1.6.s9pk.sha256
```

---

## 🎯 今回のダッシュボード機能追加の場合

### 推奨バージョン
**1.1.5 → 1.1.6** (マイナーな新機能なのでパッチバージョンアップ)

または

**1.1.5 → 1.2.0** (新機能として強調したい場合)

### 具体的な手順
```bash
# 1. バージョンを決定
NEW_VERSION="1.1.6"

# 2. manifest.yaml を編集
vim manifest.yaml
# - version: 1.1.6
# - release-notes に Database Dashboard の説明を追加

# 3. デフォルト値を更新
sed -i '' 's/1\.1\.5/1.1.6/g' docker_entrypoint.sh
sed -i '' 's/1\.1\.5/1.1.6/g' scripts/procedures/importNotes.sh

# 4. 確認
grep -r "1\.1\.[56]" . --include="*.yaml" --include="*.sh" --exclude-dir=haven

# 5. ビルド
make clean && make

# 6. コミット
git add manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh
git commit -m "update: version 1.1.6 - Add Database Dashboard"
git tag v1.1.6
```

---

## ⚠️ 注意事項

### DON'T（やってはいけないこと）
- ❌ `haven/` ディレクトリ内のファイルは変更しない（submoduleなので）
- ❌ バージョン番号を下げない（ダウングレード不可）
- ❌ manifest.yamlのバージョンと他のファイルで不一致にしない
- ❌ リリースノートを削除しない（履歴として残す）

### DO（推奨すること）
- ✅ 変更内容を明確にリリースノートに記載
- ✅ バージョンタグをGitに作成
- ✅ releases/ ディレクトリにバージョン付きパッケージを保存
- ✅ テスト環境で動作確認してからリリース

---

## 📚 参考リンク

- [Semantic Versioning](https://semver.org/)
- [Start9 Packaging Spec](https://github.com/Start9Labs/start-os/blob/master/docs/spec.md)
- [Keep a Changelog](https://keepachangelog.com/)

---

## 📞 トラブルシューティング

### Q: バージョンを変更したのにUIに反映されない
**A**: ブラウザキャッシュをクリアするか、Start9を再起動してください。

### Q: 古いバージョンから新しいバージョンにアップグレードできない
**A**: マイグレーションスクリプトが必要な場合があります。`scripts/procedures/migrations.ts` を確認してください。

### Q: バージョン番号が不一致でビルドエラー
**A**: 上記の「すべてのバージョン参照を検索」コマンドで古いバージョンが残っていないか確認してください。

---

**最終更新**: 2025-12-27  
**ドキュメントバージョン**: 1.0

