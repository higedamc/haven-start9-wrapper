# 🔧 Dashboard 問題修正 - 完了

## 📋 発見された問題

### 問題1: Health Check の警告マーク

**症状**: Haven は動作しているのに、Health Check に警告マーク（⚠️）が表示される

**原因**: 
- `curl -sf` が失敗していた
- `-f` フラグは HTTP エラー（4xx, 5xx）で失敗するが、リダイレクト（3xx）も失敗扱いになる可能性
- `set -e` により、途中で失敗すると全体が失敗

### 問題2: Dashboard の Kind カードクリック問題

**症状**: 
- Kind カードをクリックしても正しく動作しない
- クリックするたびに異なる DB のイベントが表示される
- 画面更新後のクリックで意図しない動作

**原因**: 
```javascript
// 問題のあったコード
stats.forEach(stat => {
  const clickArea = document.createElement('div');
  clickArea.className = 'absolute inset-0';
  clickArea.onclick = () => loadEvents(kind, stat.db);
  card.appendChild(clickArea);
});
```

- 各 DB（private, chat, outbox, inbox）ごとにクリックエリアを作成
- 複数の透明な `<div>` が重なって配置される
- 最後に追加されたものが一番上に来るが、クリックイベントが複数発火
- **競合状態（Race Condition）** が発生

---

## ✅ 実施した修正

### 修正1: Health Check の改善

**ファイル**: `assets/compat/check-web.sh`

**変更内容**:
```bash
# Before: curl の終了コードに依存
if curl -sf http://localhost:3355/ > /dev/null 2>&1; then
  ...
fi

# After: HTTP ステータスコードを明示的にチェック
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3355/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo '{"status":"success","message":"Haven is running and accessible"}'
    exit 0
else
    echo '{"status":"error","message":"Haven is not responding (HTTP '$HTTP_CODE')"}'
    exit 1
fi
```

**改善点**:
- ✅ HTTP ステータスコードを直接確認
- ✅ 200, 301, 302 を成功として扱う
- ✅ エラー時に HTTP コードを表示（デバッグに有用）
- ✅ `set -e` の影響を受けない

---

### 修正2: Dashboard の Kind カードクリック修正

**ファイル**: `haven/templates/dashboard.html`

**変更内容**:

#### Before（問題のあったコード）:
```javascript
// DB ごとに透明なクリックエリアを重ねていた
stats.forEach(stat => {
  const clickArea = document.createElement('div');
  clickArea.className = 'absolute inset-0';  // 全体に重なる
  clickArea.onclick = () => loadEvents(kind, stat.db);
  card.appendChild(clickArea);  // 複数回追加される
});
```

#### After（修正後のコード）:
```javascript
// 1. DB バッジを個別にクリック可能なボタンに変更
const dbBadgesHTML = stats.map(s => 
  `<button 
    class="inline-block bg-purple-900 hover:bg-purple-700 text-purple-200 px-2 py-1 rounded text-xs mr-2 mb-2 transition"
    onclick="event.stopPropagation(); loadEvents(${kind}, '${s.db}');">
    ${s.db}: ${s.count.toLocaleString()}
  </button>`
).join('');

// 2. カード全体のクリックは最初の DB をデフォルト表示
card.onclick = () => {
  if (stats.length > 0) {
    loadEvents(kind, stats[0].db);
  }
};
```

**改善点**:
- ✅ DB バッジがクリック可能なボタンになった
- ✅ 各 DB を個別に選択できる
- ✅ `event.stopPropagation()` でイベントの伝播を防止
- ✅ カード全体クリックは最初の DB を表示（明確な動作）
- ✅ ホバー効果でクリック可能であることを視覚的に表示
- ✅ 競合状態を完全に解消

---

## 🎯 修正後の動作

### Health Check

**期待される表示**:
- ✅ **Web Interface**: 緑色のチェックマーク（✓）
- ✅ "Haven is running and accessible"

**もし警告が出た場合**:
- エラーメッセージに HTTP コードが表示される
- 例: "Haven is not responding (HTTP 000)" → Haven が起動していない
- 例: "Haven is not responding (HTTP 404)" → エンドポイントが見つからない

---

### Dashboard の Kind カード

#### 動作方法（2つ）:

**方法1: DB バッジをクリック**
```
┌─────────────────────────────────┐
│ Kind 1              Badge: 842  │
│ ┌────────┐ ┌────────┐          │
│ │outbox:│ │inbox: │ ← クリック可能！
│ │  800  │ │  42   │            │
│ └────────┘ └────────┘          │
│ Text Note                       │
└─────────────────────────────────┘
```
- 各 DB バッジを個別にクリックできる
- クリックした DB のイベントのみを表示
- ホバーすると色が変わる（視覚的フィードバック）

**方法2: カード全体をクリック**
```
┌─────────────────────────────────┐
│ Kind 1              Badge: 842  │  ← この辺をクリック
│ outbox: 800  inbox: 42          │
│ Text Note                       │
└─────────────────────────────────┘
```
- カードの空白部分をクリック
- 最初の DB（通常は outbox または private）を表示
- デフォルトの動作

---

## 🔄 再ビルドとテスト

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
5. 設定 → **START**

### Step 3: テスト

#### Health Check のテスト

1. Haven サービスページを開く
2. **HEALTH CHECKS** セクションを確認
3. **期待**: ✅ 緑色のチェックマーク
4. もし警告なら Haven のログを確認

#### Dashboard のテスト

1. **LAUNCH UI** をクリック
2. **📊 View Database Dashboard** をクリック
3. Kind カードが表示されることを確認

**DB バッジクリックのテスト**:
```
1. outbox バッジをクリック
   → モーダルが開く
   → タイトルに "Kind X Events (outbox)" と表示
   → outbox のイベント JSON が表示

2. モーダルを閉じる

3. inbox バッジをクリック
   → モーダルが開く
   → タイトルに "Kind X Events (inbox)" と表示
   → inbox のイベント JSON が表示（異なる内容）

4. 何度クリックしても正しく動作することを確認
```

---

## 🐛 トラブルシューティング

### Health Check がまだ警告

**確認事項**:
1. Haven のログを確認
   ```
   Services → Haven → Logs
   ```
2. `🔗 listening at 0.0.0.0:3355` が表示されているか
3. Haven が完全に起動しているか（数秒かかる場合がある）

**デバッグ**:
```bash
# コンテナ内で直接確認
docker exec <container-id> curl -I http://localhost:3355/
# HTTP/1.1 200 OK が返るはず
```

### DB バッジをクリックしても反応しない

**確認事項**:
1. ブラウザの開発者ツールを開く（F12）
2. **Console** タブでエラーを確認
3. `/api/events/` エンドポイントにアクセスできるか確認

**手動テスト**:
```
# ブラウザで直接アクセス
https://<ui-address>.local/api/stats
https://<ui-address>.local/api/events/1?db=outbox
```

### モーダルが開くが JSON が表示されない

**原因**: 
- API から空の配列が返っている
- そのDBに対象のイベントが存在しない

**確認**:
```javascript
// ブラウザの Console で確認
fetch('/api/events/1?db=outbox')
  .then(r => r.json())
  .then(console.log)
// 配列が返るはず。空なら [] が表示される
```

---

## 📊 技術的な詳細

### 競合状態（Race Condition）とは？

**修正前の問題**:
```javascript
// カード1つに対して、複数のクリックエリアが追加される
stats = [{db: 'private'}, {db: 'outbox'}, {db: 'inbox'}]

// 実際には3つの透明な div が重なっている
<div class="kind-card">
  ...
  <div onclick="loadEvents(1, 'private')"></div>  // 1つ目
  <div onclick="loadEvents(1, 'outbox')"></div>   // 2つ目
  <div onclick="loadEvents(1, 'inbox')"></div>    // 3つ目（一番上）
</div>

// クリックすると...
// → 3つ全てのイベントハンドラが発火
// → 3つの loadEvents が同時に実行
// → 最後に完了したものがモーダルに表示される
// → どれが表示されるかは不定（レースコンディション）
```

**修正後**:
```javascript
// 1. DB バッジは個別のボタン（明確な境界）
<button onclick="event.stopPropagation(); loadEvents(1, 'outbox')">
  outbox: 800
</button>

// 2. カード全体は1つのイベントハンドラ
card.onclick = () => loadEvents(1, stats[0].db);

// クリックすると...
// → 1つのイベントハンドラのみが発火
// → 1つの loadEvents のみが実行
// → 予測可能な動作
```

### event.stopPropagation() の役割

```javascript
<div onclick="parentHandler()">
  <button onclick="event.stopPropagation(); childHandler()">
    Click me
  </button>
</div>

// stopPropagation がない場合:
// button をクリック → childHandler() + parentHandler() 両方実行

// stopPropagation がある場合:
// button をクリック → childHandler() のみ実行
```

---

## 📈 改善のメリット

### Health Check

| 項目 | 修正前 | 修正後 |
|------|--------|--------|
| 信頼性 | ⚠️ 不安定 | ✅ 安定 |
| デバッグ | ❌ 困難 | ✅ 簡単（HTTPコード表示） |
| リダイレクト | ❌ 失敗 | ✅ 対応 |

### Dashboard

| 項目 | 修正前 | 修正後 |
|------|--------|--------|
| クリック動作 | ❌ 不定 | ✅ 明確 |
| DB 選択 | ❌ 不可能 | ✅ 可能 |
| UX | ⚠️ 混乱 | ✅ 直感的 |
| 視覚的フィードバック | ❌ なし | ✅ ホバー効果 |
| パフォーマンス | ⚠️ 複数リクエスト | ✅ 1リクエストのみ |

---

## 🎉 まとめ

### 修正内容

1. ✅ **Health Check**: HTTP ステータスコードで明確に判定
2. ✅ **Dashboard**: DB バッジを個別クリック可能なボタンに変更
3. ✅ **競合状態**: イベントハンドラを1つに統一
4. ✅ **UX**: ホバー効果で操作可能な要素を明示

### 期待される結果

- ✅ Health Check が緑色（✓）
- ✅ DB バッジをクリックすると、そのDBのイベントを表示
- ✅ カード全体をクリックすると、デフォルトDBのイベントを表示
- ✅ 何度クリックしても正しく動作
- ✅ 視覚的に操作可能な要素が分かりやすい

---

**作成日**: 2025-12-27  
**ステータス**: ✅ 修正完了、テスト待ち  
**影響**: Health Check の安定性向上、Dashboard の操作性向上

