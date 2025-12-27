# 🚀 バージョンアップ - 超簡単ガイド

## ⚡ 最速（1コマンド）

```bash
# パッチバージョンアップ（最も一般的）
make bump-patch
```

これだけ！あとは質問に答えるだけ。

---

## 📋 3つの方法

### 1️⃣ Makeコマンド（推奨）

```bash
make bump-patch    # 1.1.6 → 1.1.7 (バグ修正)
make bump-minor    # 1.1.6 → 1.2.0 (新機能)
make bump-major    # 1.1.6 → 2.0.0 (破壊的変更)
make bump-version  # インタラクティブ
```

### 2️⃣ スクリプト直接実行

```bash
./scripts/bump-version.sh patch
./scripts/bump-version.sh minor
./scripts/bump-version.sh major
./scripts/bump-version.sh         # インタラクティブ
./scripts/bump-version.sh 1.3.0   # 特定バージョン
```

### 3️⃣ 手動編集（非推奨）

[VERSION-QUICKREF.md](VERSION-QUICKREF.md) を参照

---

## 🎬 実際の流れ

```bash
$ make bump-patch

🔢 Bumping patch version...

╔════════════════════════════════════════════════════════════╗
║         Haven Start9 - Version Bump Script               ║
╚════════════════════════════════════════════════════════════╝

[INFO] Current version: 1.1.6

[INFO] New version will be: 1.1.7

Proceed with version bump? (y/n) y    👈 "y" を入力

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Starting version bump: 1.1.6 → 1.1.7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[STEP] Updating manifest.yaml version...
✅ Updated manifest.yaml
[STEP] Updating default version values in scripts...
✅ Updated docker_entrypoint.sh
✅ Updated scripts/procedures/importNotes.sh

Would you like to add release notes now? (y/n) y    👈 "y" を入力

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Release Notes for v1.1.7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter release title (or press Enter for default):
Bug Fixes    👈 リリース名を入力

Enter new features (one per line, empty line to finish):
👈 新機能がなければEnterだけ

Enter improvements (one per line, empty line to finish):
Fixed dashboard error handling    👈 改善点を入力
👈 Enterで終了

Enter bug fixes (one per line, empty line to finish):
Fixed database connection timeout    👈 バグ修正を入力
👈 Enterで終了

[STEP] Adding release notes to manifest.yaml...
✅ Added release notes

[STEP] Validating changes...
✅ Version in manifest.yaml: 1.1.7
✅ Version in docker_entrypoint.sh: 1.1.7 (3 occurrences)
✅ Version in scripts/procedures/importNotes.sh: 1.1.7 (2 occurrences)
✅ All validations passed!

Would you like to commit these changes to git? (y/n) y    👈 "y" を入力
[STEP] Committing changes to git...
✅ Changes committed

Would you like to create a git tag v1.1.7? (y/n) y    👈 "y" を入力
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
```

---

## 💡 よくあるパターン

### パターン1: バグ修正
```bash
make bump-patch
# リリースノートのBug Fixesに内容を記載
# Gitコミット: y
```

### パターン2: 新機能追加
```bash
make bump-minor
# リリースノートのNew Featuresに内容を記載
# Gitコミット: y
```

### パターン3: 素早く更新（リリースノート後で）
```bash
make bump-patch
# リリースノート: n
# Gitコミット: n

# 後で手動編集
vim manifest.yaml
git add manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh
git commit -m "update: version 1.1.7"
```

---

## ✅ 自動でやってくれること

1. ✅ `manifest.yaml` のバージョン更新
2. ✅ `docker_entrypoint.sh` の3箇所更新
3. ✅ `scripts/procedures/importNotes.sh` の2箇所更新
4. ✅ リリースノート生成（オプション）
5. ✅ 変更内容の検証
6. ✅ Gitコミット＆タグ作成（オプション）

---

## 🎯 次のステップ

バージョンアップ後：

```bash
# 1. 変更確認
git diff

# 2. ビルド
make clean && make

# 3. テスト
make verify

# 4. プッシュ（Gitコミットした場合）
git push origin main
git push origin v1.1.7

# 5. リリースパッケージ作成
make release
```

---

## 📚 詳細ドキュメント

- **このファイル**: 超簡単ガイド（今ここ）
- [scripts/README.md](scripts/README.md): スクリプト詳細＋使用例
- [VERSION-QUICKREF.md](VERSION-QUICKREF.md): 手動バージョンアップ
- [docs/VERSION-MANAGEMENT.md](docs/VERSION-MANAGEMENT.md): 完全ガイド

---

## 🆘 トラブル時

### スクリプトが見つからない
```bash
# 実行権限確認
ls -la scripts/bump-version.sh
# -rwxr-xr-x なら OK

# なければ付与
chmod +x scripts/bump-version.sh
```

### プロジェクトルートじゃない
```bash
cd /path/to/haven-start9-wrapper
make bump-patch
```

### バージョン確認
```bash
make version-check
```

---

**最終更新**: 2025-12-27

