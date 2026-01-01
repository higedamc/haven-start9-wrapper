# Start9 Community Registry Submission Guide

## Haven v1.2.3 - Community Registry 登録手順

### 📋 提出前チェックリスト

- [x] サービスが `.s9pk` 形式でパッケージ化済み
- [x] すべてのGitHub issuesが解決済み
- [x] Health checkが正常に動作
- [x] Start9上でテスト済み
- [x] ドキュメントが完備（README.md, instructions.md）
- [x] ソースコードが公開リポジトリで利用可能
- [x] メタデータ（wrapper-repo, support-site, donation-url）が正しく設定済み
- [ ] GitHubリポジトリに適切なタグを付ける（v1.2.3）

---

## 🚀 提出プロセス

### 1. リポジトリの最終準備

#### a) GitHubにタグを作成
```bash
cd /Users/apple/work/haven-start9-wrapper
git tag -a v1.2.3 -m "Haven v1.2.3 - Community Registry Release"
git push origin v1.2.3
```

#### b) GitHubでリリースを作成
1. https://github.com/higedamc/haven-start9-wrapper/releases/new にアクセス
2. タグ: `v1.2.3` を選択
3. リリースタイトル: `Haven v1.2.3 - Community Registry Release`
4. リリースノート:
```markdown
## Haven v1.2.3 - Start9 Community Registry Release

### 🎉 Overview
Haven (High Availability Vault for Events on Nostr) is a comprehensive personal Nostr relay implementation featuring four specialized relays and an integrated Blossom media server.

### ✨ Features
- **Private Relay**: Personal secure storage for drafts and private notes
- **Chat Relay**: Web of Trust protected direct messages (NIP-04)
- **Inbox Relay**: Receive tagged events from trusted sources
- **Outbox Relay**: Public broadcast of your events
- **Blossom Server**: Decentralized media hosting (NIP-96 & BUD-02 compliant)
- **Tor-Only**: Maximum privacy with .onion addresses

### 🔧 Changes in v1.2.3
- Fixed wrapper repository URL
- Updated support site to wrapper issues
- Added Lightning donation address
- All GitHub issues resolved
- Health check improvements
- Cloud backup functionality postponed to v1.3.0
- Ready for Start9 Community Registry

### 📦 Installation
Install via Start9 Community Registry (coming soon) or sideload the package.

### 🔗 Links
- [GitHub Repository](https://github.com/higedamc/haven-start9-wrapper)
- [Haven Upstream](https://github.com/bitvora/haven)
- [Documentation](https://github.com/higedamc/haven-start9-wrapper/blob/main/README.md)
```
5. `haven.s9pk` ファイルをアセットとして添付
6. 「Publish release」をクリック

---

### 2. Start9へ提出メールを送信

**宛先**: `submissions@start9.com`

**件名**: `Community Registry Submission - Haven Nostr Relay v1.2.3`

**本文（英語）**:

```
Subject: Community Registry Submission - Haven Nostr Relay v1.2.3

Dear Start9 Team,

I am submitting Haven, a comprehensive personal Nostr relay implementation, for inclusion in the Start9 Community Registry.

## Service Information

**Service Name**: Haven
**Version**: 1.2.3
**Package ID**: haven
**Category**: Communication / Privacy / Nostr

**Repository**: https://github.com/higedamc/haven-start9-wrapper
**Upstream Source**: https://github.com/bitvora/haven (MIT License)
**Release**: https://github.com/higedamc/haven-start9-wrapper/releases/tag/v1.2.3
**Donation**: https://getalby.com/p/godzhigella

## Description

Haven (High Availability Vault for Events on Nostr) is a sovereign personal relay for the Nostr protocol, featuring:

- Four specialized relays (Private, Chat, Inbox, Outbox)
- Integrated Blossom media server (NIP-96 & BUD-02 compliant)
- Web of Trust spam protection
- Tor-only operation for maximum privacy
- Support for BadgerDB and LMDB

## Testing

The package has been thoroughly tested on StartOS:
- Health checks functioning correctly
- All interfaces accessible via Tor
- Media management working properly
- Configuration system validated
- All GitHub issues resolved

## Documentation

Complete documentation is included:
- User guide (instructions.md)
- Developer documentation (README.md)
- Configuration guide
- Privacy & security information

## Support

I am committed to maintaining this package and providing user support through:
- GitHub Issues: https://github.com/higedamc/haven-start9-wrapper/issues
- Regular updates and bug fixes

## Additional Notes

This is a wrapper for the Haven relay by Bitvora (MIT License). All modifications for Start9 compatibility are also MIT licensed.

Thank you for considering Haven for the Community Registry. I look forward to your feedback.

Best regards,
[Your Name]
```

---

### 3. Start9によるレビュープロセス

Start9チームが以下を実施します：

1. **コードレビュー**
   - セキュリティチェック
   - ベストプラクティス準拠確認
   - ドキュメント品質確認

2. **ビルドテスト**
   - `.s9pk` パッケージのビルド確認
   - 依存関係の検証

3. **機能テスト**
   - StartOS上での動作確認
   - Health checkの検証
   - インターフェースの動作確認

---

### 4. Community Beta Registryへの公開

テストが完了すると：

1. Start9から確認メールが届く
2. **Community Beta Registry** に掲載される
3. ユーザーが以下の方法でインストール可能に：
   - Start9 UI → System → Manage → Registry Settings
   - Community Beta Registry を有効化
   - Marketplace からインストール

---

### 5. 本番環境への移行

ベータテスト期間（通常数週間〜数ヶ月）後：

1. ユーザーフィードバックを収集
2. バグ修正・改善を実施
3. Start9に本番環境への移行を依頼
4. **Community Registry** (本番環境) に公開

---

## 📊 提出後のタイムライン

| フェーズ | 期間 | アクション |
|---------|------|-----------|
| 提出 | Day 0 | メール送信 |
| 初期レビュー | 1-2週間 | Start9からの返信待ち |
| レビュー対応 | 1-4週間 | フィードバックへの対応 |
| Beta公開 | 数日 | Community Beta Registryに掲載 |
| ベータテスト | 2-8週間 | ユーザーフィードバック収集 |
| 本番移行 | 数日 | Community Registryに昇格 |

---

## 🔗 参考リンク

- [Start9 Developer Documentation](https://docs.start9.com/0.3.5.x/developer-docs/)
- [Community Submission Process](https://docs.start9.com/0.3.5.x/developer-docs/submission)
- [Start9 Marketplace Strategy](https://blog.start9.com/start9-marketplace-strategy/)

---

## 📝 重要な注意事項

### ライセンス確認
- Haven本体: MIT License ✅
- アイコン: 公式Havenアイコン（Bitvoraに確認済み）✅

### サポート体制
Community Registryに登録されたサービスは、Start9が直接サポートするものではありません。以下の体制を整備済み：

- GitHub Issues: ユーザーからの問題報告受付
- README.md: 詳細なドキュメント
- instructions.md: セットアップガイド
- 定期的なメンテナンス体制

### 更新プロセス
新しいバージョンをリリースする際：

1. GitHubで新しいタグとリリースを作成
2. `submissions@start9.com` に更新を通知
3. Start9がレビュー・テスト後、Registryを更新

---

## ✅ 次のステップ

1. [ ] GitHubにv1.2.3タグを作成
2. [ ] GitHubでリリースを作成（haven.s9pkを添付）
3. [ ] submissions@start9.com にメール送信
4. [ ] Start9からの返信を待つ
5. [ ] フィードバックに対応
6. [ ] Beta Registry公開の通知を受ける
7. [ ] ユーザーフィードバックを収集
8. [ ] 必要に応じて改善版をリリース

---

**🎉 Haven v1.2.3 は Community Registry への提出準備が完了しています！**

## 📝 v1.2.3で修正された項目

- ✅ Wrapper Repository URL: `higedamc/haven-start9-wrapper`
- ✅ Support Site: Wrapper側のissuesに変更（Start9特有の問題を切り分け）
- ✅ Donation URL: Lightning Address対応（https://getalby.com/p/godzhigella）

