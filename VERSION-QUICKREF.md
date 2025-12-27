# 🚀 バージョンアップ - クイックリファレンス

## 📝 変更するファイル（3つだけ）

### 1. `manifest.yaml` (2箇所)
```yaml
# 7行目
version: 1.1.6  # ← 新しいバージョン

# 9行目〜
release-notes: |
  **v1.1.6 - 機能名 (2025-12-27)**  # ← リリース情報
  
  New Features:
  - 新機能の説明
```

### 2. `docker_entrypoint.sh` (2箇所)
```bash
# 83行目
RELAY_VERSION=${RELAY_VERSION:-1.1.6}

# 516行目
log_info "  Version: ${RELAY_VERSION:-1.1.6}"
```

### 3. `scripts/procedures/importNotes.sh` (2箇所)
```bash
# 265行目
export RELAY_VERSION=$(yq e '.relay-version // "1.1.6"' /data/start9/config.yaml)

# 284行目
RELAY_VERSION=${RELAY_VERSION:-1.1.6}
```

---

## ⚡ ワンライナー置換（macOS）

```bash
# 新しいバージョンを設定
NEW_VER="1.1.6"
OLD_VER="1.1.5"

# 一括置換
sed -i '' "s/${OLD_VER}/${NEW_VER}/g" manifest.yaml docker_entrypoint.sh scripts/procedures/importNotes.sh

# リリースノートは手動で編集
vim manifest.yaml
```

---

## 🎯 チェックリスト

- [ ] `manifest.yaml` version: 更新
- [ ] `manifest.yaml` release-notes: 追加
- [ ] `docker_entrypoint.sh` 2箇所更新
- [ ] `scripts/procedures/importNotes.sh` 2箇所更新
- [ ] `make clean && make` 成功
- [ ] `git commit` & `git tag`

---

## 💡 バージョン番号の決め方

- **パッチ** (1.1.5 → 1.1.6): バグ修正、軽微な改善
- **マイナー** (1.1.5 → 1.2.0): 新機能追加
- **メジャー** (1.1.5 → 2.0.0): 破壊的変更

---

詳細は [`docs/VERSION-MANAGEMENT.md`](docs/VERSION-MANAGEMENT.md) を参照

