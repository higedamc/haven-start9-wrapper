# Start9 Community Registry Submission Email

## Email Details

**To**: `submissions@start9.com`

**Subject**: `Community Registry Submission - Haven Nostr Relay v1.2.3`

---

## Email Body

```
Dear Start9 Team,

I am submitting Haven v1.2.3, a comprehensive personal Nostr relay implementation, for inclusion in the Start9 Community Registry.

## Service Information

**Service Name**: Haven  
**Package ID**: haven  
**Version**: 1.2.3  
**Category**: Communication / Privacy / Nostr

**Service Wrapper Repository**: https://github.com/higedamc/haven-start9-wrapper  
**Upstream Source Repository**: https://github.com/bitvora/haven  
**Release**: https://github.com/higedamc/haven-start9-wrapper/releases/tag/v1.2.3  
**License**: MIT (both wrapper and upstream)

## Service Description

Haven (High Availability Vault for Events on Nostr) is a sovereign personal relay for the Nostr protocol, featuring:

- **Four Specialized Relays**:
  - Private Relay: Personal secure storage for drafts and private notes
  - Chat Relay: Web of Trust protected direct messages (NIP-04)
  - Inbox Relay: Receive tagged events from trusted sources
  - Outbox Relay: Public broadcast of your events

- **Integrated Blossom Media Server**: Decentralized media hosting (NIP-96 & BUD-02 compliant)

- **Advanced Features**:
  - Web of Trust spam protection
  - Tor-only operation for maximum privacy
  - Support for BadgerDB and LMDB database engines
  - Event import functionality
  - Database dashboard with event statistics

## Build Instructions

The service is ready for production build:

```bash
git clone https://github.com/higedamc/haven-start9-wrapper.git
cd haven-start9-wrapper
git checkout v1.2.3
make
```

This will produce `haven.s9pk` that has been thoroughly tested on StartOS.

## StartOS Compatibility Checklist

I have verified the following on StartOS:

✅ **Marketplace Listing**: All required metadata fields are populated with valid links  
✅ **Install/Uninstall**: Service installs and uninstalls cleanly  
✅ **Instructions**: Comprehensive setup instructions display without error  
✅ **Properties**: Service properties display correctly  
✅ **Config**: Configuration system functions properly (database engine selection, WoT settings, etc.)  
✅ **Dependencies**: Properly utilizes Tor dependency  
✅ **Actions**: Import Notes action runs without error  
✅ **Health Checks**: Docker-based health check (check-web.sh) displays and runs correctly  
✅ **Interfaces**: Four Nostr relay interfaces (main/private/chat/inbox) plus Blossom server accessible via Tor  
✅ **Logs**: Service logs display without error  
✅ **Compatibility**: Tested on x86_64, runs efficiently with minimal resource usage  
✅ **Backup/Restore**: Successfully tested backup creation and restoration

## Technical Details

- **Architecture**: amd64 (x86_64)
- **Base Image**: Alpine Linux 3.19
- **Upstream Language**: Go 1.24
- **Resource Requirements**: Low (suitable for Raspberry Pi 4 8GB)
- **Dependencies**: Tor (for .onion addresses)
- **Data Persistence**: `/data` volume (database, media, backups)

## Testing Summary

The service has been extensively tested on StartOS:

1. **Installation**: Clean install with automatic Tor configuration
2. **Configuration**: All config options function correctly
3. **Operations**: All four relays and Blossom server operational
4. **Client Compatibility**: Tested with Amethyst, Damus, Primal, Coracle
5. **Health Monitoring**: Process and HTTP checks functioning
6. **Data Persistence**: Database persists across container restarts
7. **Backup/Restore**: Successfully verified data recovery

## Additional Information

**Support**: https://github.com/higedamc/haven-start9-wrapper/issues  
**Donation**: https://getalby.com/p/godzhigella  
**Documentation**: Complete README and setup instructions included

The service wrapper is production-ready and has been polished for Community Registry publication. All source code is publicly available under MIT license.

I am committed to maintaining this service and providing timely support for any issues that may arise. I am also prepared to leave the service on Community Beta Registry for additional testing before requesting production publication.

Thank you for your consideration. Please let me know if you need any additional information or if there are any issues during your review and testing process.

Best regards,
[Your Name]

---

## Contact Information (Optional)

GitHub: @higedamc  
Nostr: [Your Nostr Public Key if applicable]  
Email: [Your Email Address]
```

---

## 📝 送信前の確認事項

### 1. メール本文のカスタマイズ

以下を実際の情報に置き換えてください：

- `[Your Name]` → あなたの名前
- `[Your Email Address]` → あなたのメールアドレス
- `[Your Nostr Public Key if applicable]` → Nostrの公開鍵（任意）

### 2. 最終確認

- [ ] GitHubリポジトリが公開されていることを確認
- [ ] v1.2.3タグがプッシュされていることを確認
- [ ] リリースページに `haven.s9pk` が添付されていることを確認
- [ ] README.mdとinstructions.mdが最新であることを確認
- [ ] manifest.yamlのすべてのメタデータが正しいことを確認

### 3. メール送信

上記の確認が完了したら、メール本文をコピーして `submissions@start9.com` に送信してください。

---

## ⏱️ 提出後のタイムライン予想

| ステップ | 期間 | 内容 |
|---------|------|------|
| 提出 | Day 0 | メール送信 |
| リポジトリスナップショット | 1-2日 | Start9がリポジトリのスナップショットを作成 |
| コードレビュー | 3-7日 | セキュリティ・完全性チェック |
| ビルドテスト | 1-2日 | Debianビルドボックスでビルド |
| 機能テスト | 2-5日 | StartOS上でインストール・動作確認 |
| Beta Registry公開 | 1日 | 承認メール受信 |
| ベータテスト期間 | 数日〜数週間 | コミュニティテスト |
| 本番公開依頼 | - | "ship it"メールで依頼 |
| 本番Registry公開 | 1-2日 | 正式公開 |

**合計予想期間**: 2〜4週間

---

## 🎯 注意事項

### Start9からのフィードバック対応

Start9からビルドエラーや問題の指摘があった場合：

1. 速やかに修正
2. バージョンを上げる（例: v1.2.4）
3. 修正内容を返信で報告
4. 必要に応じて再提出

### ベータ期間中の対応

Community Beta Registryに公開された後：

1. 自分でテストを実施
2. コミュニティからのフィードバックを収集
3. 重大なバグがあれば修正してから本番リリース
4. 問題がなければ "ship it" メールを送信

---

## 📧 "Ship it" メールのテンプレート（ベータ完了後）

```
Subject: Re: Community Registry Submission - Haven Nostr Relay v1.2.3

Dear Start9 Team,

Thank you for publishing Haven v1.2.3 to the Community Beta Registry.

After [X days/weeks] of beta testing with positive feedback from the community and no critical issues reported, I believe the service is ready for production.

Please ship it to the production Community Registry.

Best regards,
[Your Name]
```

---

**🎉 Haven v1.2.3 のStart9 Community Registry提出の準備が完全に整いました！**

