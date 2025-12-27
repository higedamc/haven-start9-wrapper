# 🛠️ Scripts Directory

## bump-version.sh

自動バージョンアップスクリプト - 3つの必須ファイルを一括更新し、リリースノートも生成します。

### 🚀 使い方

#### 1. パッチバージョンアップ（最も一般的）
```bash
./scripts/bump-version.sh patch
# 1.1.6 → 1.1.7
```

**使用例**: バグ修正、軽微な改善

---

#### 2. マイナーバージョンアップ
```bash
./scripts/bump-version.sh minor
# 1.1.6 → 1.2.0
```

**使用例**: 新機能追加（後方互換あり）

---

#### 3. メジャーバージョンアップ
```bash
./scripts/bump-version.sh major
# 1.1.6 → 2.0.0
```

**使用例**: 破壊的変更、設定形式変更

---

#### 4. 特定バージョンを指定
```bash
./scripts/bump-version.sh 1.3.0
# 1.1.6 → 1.3.0
```

---

#### 5. インタラクティブモード（推奨）
```bash
./scripts/bump-version.sh
```

対話形式で以下を入力：
1. バージョンタイプを選択
2. リリースノートを入力
3. Gitコミット/タグを作成

---

### 📋 実行例（インタラクティブモード）

```bash
$ ./scripts/bump-version.sh

╔════════════════════════════════════════════════════════════╗
║         Haven Start9 - Version Bump Script               ║
╚════════════════════════════════════════════════════════════╝

[INFO] Current version: 1.1.6

Select version bump type:
  1) patch (1.1.6 → 1.1.7)
  2) minor (1.1.6 → 1.2.0)
  3) major (1.1.6 → 2.0.0)
  4) custom version

Enter choice [1-4]: 1

[INFO] New version will be: 1.1.7

Proceed with version bump? (y/n) y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Starting version bump: 1.1.6 → 1.1.7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[STEP] Updating manifest.yaml version...
✅ Updated manifest.yaml
[STEP] Updating default version values in scripts...
✅ Updated docker_entrypoint.sh
✅ Updated scripts/procedures/importNotes.sh

Would you like to add release notes now? (y/n) y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Release Notes for v1.1.7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter release title (or press Enter for default):
Bug Fixes and Improvements

Enter new features (one per line, empty line to finish):
[empty line]

Enter improvements (one per line, empty line to finish):
Enhanced error handling in dashboard
Improved database query performance
[empty line]

Enter bug fixes (one per line, empty line to finish):
Fixed race condition in event loading
[empty line]

[STEP] Adding release notes to manifest.yaml...
✅ Added release notes

[STEP] Validating changes...
✅ Version in manifest.yaml: 1.1.7
✅ Version in docker_entrypoint.sh: 1.1.7 (3 occurrences)
✅ Version in scripts/procedures/importNotes.sh: 1.1.7 (2 occurrences)
✅ All validations passed!

Would you like to commit these changes to git? (y/n) y
[STEP] Committing changes to git...
✅ Changes committed

Would you like to create a git tag v1.1.7? (y/n) y
✅ Created tag v1.1.7

To push changes and tag, run:
  git push origin main
  git push origin v1.1.7

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Version bump completed successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
  1. Review changes: git diff
  2. Build package: make clean && make
  3. Test package: make verify
  4. Deploy to Start9

Files updated:
  • manifest.yaml
  • docker_entrypoint.sh
  • scripts/procedures/importNotes.sh
```

---

### 🎯 クイック実行パターン

#### パターン1: 素早くパッチバージョンアップ
```bash
# リリースノートなし、Gitコミットなし（最速）
./scripts/bump-version.sh patch
# すべて "n" で回答
```

#### パターン2: 完全自動（推奨）
```bash
# インタラクティブモードで全て入力
./scripts/bump-version.sh
# リリースノート入力 → Gitコミット → タグ作成
```

#### パターン3: スクリプト + 手動調整
```bash
# バージョンだけ更新
./scripts/bump-version.sh 1.2.0
# リリースノート: n
# Gitコミット: n

# その後、手動でリリースノートを編集
vim manifest.yaml

# 手動でコミット
git add manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh
git commit -m "update: version 1.2.0 - Major Update"
git tag v1.2.0
```

---

### ✅ 自動更新されるファイル

スクリプトは以下の3ファイルを自動更新：

1. **`manifest.yaml`**
   - `version:` フィールド
   - `release-notes:` セクション（オプション）

2. **`docker_entrypoint.sh`**
   - 83行目: `RELAY_VERSION=${RELAY_VERSION:-X.Y.Z}`
   - 516行目: `log_info "Version: ${RELAY_VERSION:-X.Y.Z}"`
   - 562行目: `yq e '.relay-version // "X.Y.Z"'`

3. **`scripts/procedures/importNotes.sh`**
   - 265行目: `yq e '.relay-version // "X.Y.Z"'`
   - 284行目: `RELAY_VERSION=${RELAY_VERSION:-X.Y.Z}`

---

### 🔍 検証機能

スクリプトは自動的に以下を検証：

- ✅ `manifest.yaml` のバージョン更新
- ✅ `docker_entrypoint.sh` の3箇所更新
- ✅ `scripts/procedures/importNotes.sh` の2箇所更新
- ⚠️  古いバージョン番号の残留チェック

検証に失敗した場合、エラーメッセージが表示されます。

---

### 🎨 リリースノート生成

対話形式で以下を入力できます：

1. **リリースタイトル** (例: "Database Dashboard")
2. **新機能** (New Features)
3. **改善点** (Improvements)
4. **バグ修正** (Bug Fixes)

入力内容は自動的に manifest.yaml の `release-notes:` セクションに追加されます。

生成例：
```yaml
release-notes: |
  **v1.1.7 - Bug Fixes and Improvements (2025-12-27)**
  
  Improvements:
  - Enhanced error handling in dashboard
  - Improved database query performance
  
  Bug Fixes:
  - Fixed race condition in event loading
  
  ---
  **v1.1.6 - Database Dashboard (2025-12-27)**
  ...
```

---

### 🔄 Git統合

スクリプトは以下のGit操作を提案：

1. **自動コミット**: 変更した3ファイルをコミット
2. **タグ作成**: `v1.1.7` のようなバージョンタグ

すべてオプショナルで、スキップ可能です。

---

### ⚠️ 注意事項

#### DO（推奨）
- ✅ プロジェクトルートで実行
- ✅ 変更前にバックアップ（`git status` で確認）
- ✅ リリースノートを丁寧に記載
- ✅ 実行後に `git diff` で確認

#### DON'T（非推奨）
- ❌ サブディレクトリから実行しない
- ❌ バージョンを下げない（ダウングレード）
- ❌ 手動編集と混在させない（スクリプト実行前後）

---

### 🐛 トラブルシューティング

#### Q: "manifest.yaml not found" エラー
**A**: プロジェクトルートで実行してください
```bash
cd /path/to/haven-start9-wrapper
./scripts/bump-version.sh patch
```

#### Q: 古いバージョンが残っている警告
**A**: 通常はリリースノート履歴に残っているだけなので問題ありません。
ただし、`v1.1.6 -` のような履歴以外で警告が出た場合は手動確認が必要です。

```bash
# 古いバージョンを検索
grep -r "1\.1\.6" manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh
```

#### Q: yq がインストールされていない
**A**: スクリプトは sed にフォールバックしますが、yq の使用を推奨します。

```bash
# macOS
brew install yq

# Linux
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
sudo chmod +x /usr/local/bin/yq
```

---

### 📚 関連ドキュメント

- [VERSION-QUICKREF.md](../VERSION-QUICKREF.md) - 手動バージョンアップ方法
- [docs/VERSION-MANAGEMENT.md](../docs/VERSION-MANAGEMENT.md) - 詳細ガイド

---

### 🎓 使用例シナリオ

#### シナリオ1: 軽微なバグ修正
```bash
# パッチバージョンアップ
./scripts/bump-version.sh patch

# リリースノート例:
# Title: Bug Fixes
# Bug Fixes:
# - Fixed dashboard loading issue
# - Corrected import timeout handling
```

#### シナリオ2: 新機能追加
```bash
# マイナーバージョンアップ
./scripts/bump-version.sh minor

# リリースノート例:
# Title: Export Feature
# New Features:
# - Export events to JSON file
# - Bulk event deletion interface
```

#### シナリオ3: メジャーアップデート
```bash
# メジャーバージョンアップ
./scripts/bump-version.sh major

# リリースノート例:
# Title: Breaking Changes - New Config Format
# Breaking Changes:
# - Changed configuration file structure
# - Requires migration from v1.x
```

---

**最終更新**: 2025-12-27
**スクリプトバージョン**: 1.0

