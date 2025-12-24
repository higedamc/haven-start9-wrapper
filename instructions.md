# Haven Setup Instructions

Welcome to Haven - your self-sovereign Nostr relay suite with integrated Blossom media server!

## 🚀 Initial Configuration

After installation, you'll need to configure Haven with your Nostr public key (npub).

### Step 1: Get Your Nostr Public Key

If you don't have a Nostr identity yet:

1. **Install a Nostr client:**
   - **Amethyst** (Android) - [Google Play](https://play.google.com/store/apps/details?id=com.vitorpamplona.amethyst)
   - **Damus** (iOS) - [App Store](https://apps.apple.com/app/damus/id1628663131)
   - **Primal** (Web/Mobile) - [primal.net](https://primal.net)

2. **Create a new account** in the client

3. **Copy your public key** (starts with `npub1...`)
   - In Amethyst: Settings → Account → Copy npub
   - In Damus: Settings → Account → Copy npub
   - In Primal: Settings → Profile → Copy npub

### Step 2: Configure Haven

1. Go to **Haven's Config page** in Start9 UI
2. Enter your **Nostr public key** (npub1...)
3. *(Optional)* Customize relay names and descriptions
4. **Save configuration**
5. Haven will restart automatically

### Step 3: Get Your Relay URLs

After configuration, go to **Haven's Properties page** to see your relay URLs.

---

## 📡 Your Relay URLs

Haven provides **four specialized relays**, all accessible via Tor:

### 🌍 Outbox Relay (Public)
```
ws://your-haven-address.onion
```
- **Purpose**: Your public posts and broadcasts
- **Read**: Anyone can read
- **Write**: Only you can write
- **Use Case**: Main relay for your public content

### 🔒 Private Relay
```
ws://your-haven-address.onion/private
```
- **Purpose**: Private drafts, eCash notes, sensitive data
- **Read**: Only you (Auth required)
- **Write**: Only you (Auth required)
- **Use Case**: Personal secure storage

### 💬 Chat Relay
```
ws://your-haven-address.onion/chat
```
- **Purpose**: Direct messages (DMs)
- **Read**: You and Web of Trust contacts (Auth required)
- **Write**: You and Web of Trust contacts (Auth required)
- **Use Case**: Private conversations

### 📥 Inbox Relay
```
ws://your-haven-address.onion/inbox
```
- **Purpose**: Receive replies, mentions, and tagged events
- **Read**: Only you (Auth required)
- **Write**: Web of Trust contacts
- **Use Case**: Curated notifications

---

## 📱 Configure Nostr Clients

### Amethyst (Android)

1. **Open Amethyst** → Settings → Relays
2. **Add relays**:
   - Tap **"Add Relay"**
   - Enter your relay URLs (from Properties page)
   - Set permissions:
     - **Outbox**: Read ✓, Write ✓
     - **Private**: Read ✓, Write ✓ (Auth enabled)
     - **Chat**: Read ✓, Write ✓ (Auth enabled)
     - **Inbox**: Read ✓ (Auth enabled)

3. **Configure Blossom** (Media Server):
   - Settings → Media Servers
   - Add: `http://your-haven-address.onion`
   - Enable for uploads

### Damus (iOS)

1. **Open Damus** → Settings → Relays
2. **Add custom relay**:
   - Tap **"+"**
   - Enter relay URL
   - Enable for Read/Write as needed

3. Repeat for each relay

### Primal (Web/Mobile)

1. **Open Primal** → Settings → Network
2. **Add relay**:
   - Click **"Add Relay"**
   - Enter relay URL
   - Save

---

## 📁 Blossom Media Server

Haven includes a **Blossom-compliant media server** for hosting images, videos, and other media files.

### Blossom Server URL
```
http://your-haven-address.onion
```

### Supported Clients
- ✅ **Amethyst** (built-in support)
- ✅ **Coracle**
- ✅ **nostrudel**
- ✅ Any client supporting **NIP-96** or **BUD-02**

### Upload Media

**In Amethyst:**
1. Settings → Media Servers
2. Add: `http://your-haven-address.onion`
3. Enable **"Use for uploads"**
4. Upload media directly from posts

**Manual Upload (curl):**
```bash
curl -X POST \
  -H "Authorization: Nostr <base64-encoded-auth-event>" \
  -F "file=@image.jpg" \
  http://your-haven-address.onion/upload
```

---

## 🕸️ Web of Trust (WoT)

Haven uses **Web of Trust** to protect your Chat and Inbox relays from spam.

### How It Works

1. Haven automatically fetches your **follow list** from other relays
2. Builds a trust network up to specified **depth** (default: 2)
   - **Depth 1**: People you follow
   - **Depth 2**: People followed by people you follow
3. Updates **periodically** (default: 24 hours)
4. Only trusted users can write to Chat and Inbox relays

### Configure WoT Settings

1. Go to **Config page**
2. Adjust:
   - **WoT Depth**: 1-3 (recommended: 2)
   - **Refresh Interval**: 6-48 hours
   - **Minimum Followers**: 10 (spam protection)
3. Save configuration

### Troubleshooting WoT

- **Can't receive DMs from someone?**
  - Check if they're in your WoT (follow them or they should be followed by someone you follow)
  - Lower WoT depth temporarily
  - Check Haven logs for WoT updates

---

## 🔄 Advanced Features

### Import Old Notes

To import your existing notes from other relays:

1. Go to **Config page** → Advanced Settings
2. Add **seed relay URLs** (comma-separated):
   ```
   wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band
   ```
3. *(Optional)* Set **import start date** (YYYY-MM-DD)
4. **Save and restart**
5. Haven will import notes in background
6. Check logs for import progress

### Cloud Backups

Haven supports automated cloud backups to S3-compatible services:

1. Go to **Config** → Backup Settings
2. Choose **backup provider**:
   - DigitalOcean Spaces
   - AWS S3
   - Backblaze B2
   - Any S3-compatible service
3. Enter credentials:
   - Access Key ID
   - Secret Access Key
   - Bucket Name
   - Region
4. Set **backup interval** (hours)
5. **Enable backups**
6. First backup runs immediately

### Database Selection

Haven supports two database engines:

#### BadgerDB (Default)
- ✅ Better compatibility
- ✅ Easier setup
- ✅ Good for most users
- ✅ Works on all storage types

#### LMDB
- ✅ Higher performance on NVMe drives
- ✅ Lower memory usage
- ⚠️ Requires LMDB_MAPSIZE configuration
- ⚠️ More complex tuning

**Change in Config → Advanced Settings if needed.**

---

## 🐛 Troubleshooting

### Can't Connect to Relay

**Symptoms:**
- Nostr client can't connect
- Timeout errors

**Solutions:**
1. Verify **Tor is working** on Start9
2. Check **Haven service status** (should be "Running")
3. Ensure **.onion address is correct**
4. Try accessing web interface: `http://your-haven-address.onion`
5. Check **Haven logs** for errors

### Authentication Failures

**Symptoms:**
- "Auth required" errors
- Can't read private relay

**Solutions:**
1. Verify **npub is correct** in config
2. Ensure your Nostr client supports **NIP-42 (Auth)**
   - Amethyst: ✅ Full support
   - Damus: ✅ Full support
   - Primal: ⚠️ Limited support
3. Try **refreshing client connection**
4. **Re-add the relay** in client

### Media Upload Fails

**Symptoms:**
- Upload button doesn't work
- 403 Forbidden errors

**Solutions:**
1. Check **file size limits** (default: 100MB)
2. Verify you're **authenticated as owner**
3. Ensure **Blossom server is enabled** in Haven config
4. Check **supported file types**:
   - Images: JPEG, PNG, GIF, WebP
   - Videos: MP4, WebM
5. Check **Haven logs** for upload errors

### WoT Not Working

**Symptoms:**
- Can't receive DMs from contacts
- Spam still getting through

**Solutions:**
1. Wait for **initial WoT fetch** to complete (check logs)
2. Verify your **follow list is public** on other relays
3. Try **lowering WoT depth** temporarily
4. Check if contact is in your WoT:
   - Look for logs: "User [pubkey] is in WoT"
5. **Manually trigger WoT refresh** (restart Haven)

### Database Issues

**Symptoms:**
- Haven won't start
- Corrupted database errors

**Solutions:**
1. **Stop Haven**
2. **Backup database** (Start9 backup feature)
3. Check **available disk space**
4. Try **switching database engine** (BadgerDB ↔ LMDB)
5. If corrupted, **restore from backup** or **delete database** (⚠️ data loss):
   ```bash
   rm -rf /data/db/*
   ```
6. **Restart Haven**

### Performance Issues

**Symptoms:**
- Slow relay responses
- High memory usage

**Solutions:**
1. **Check database size**: Properties page → Database Size
2. **Reduce WoT depth** to 1 or 2
3. **Increase WoT refresh interval** to 48 hours
4. **Disable import** if running
5. Consider **switching to LMDB** for better performance
6. **Restart Haven** periodically

---

## 📊 Monitoring

### Properties Page

View real-time statistics:
- **.onion address** (with QR code)
- **Relay URLs** (all four relays)
- **Blossom server URL**
- **Database size**
- **Media files count and size**
- **Service status**

### Logs

View Haven logs in Start9 UI:
- **Logs** → Haven
- Look for:
  - ✅ "Haven is booting up"
  - ✅ "Tor Hidden Service started"
  - ✅ "Listening at 0.0.0.0:3355"
  - ⚠️ Any ERROR messages

---

## 🔐 Security Best Practices

1. **Keep Your nsec Private**
   - Never share your private key (nsec)
   - Only use npub (public key) in Haven config
   - Use Nostr clients with good key management

2. **Use Tor Only**
   - Haven is designed for Tor-only operation
   - Do not expose to clearnet
   - Verify .onion address before sharing

3. **Regular Backups**
   - Enable **cloud backups** or use **Start9's backup feature**
   - Test restores periodically
   - Keep backups encrypted

4. **Monitor Logs**
   - Check Haven logs **periodically** for anomalies
   - Watch for unusual activity
   - Investigate any errors

5. **Update Regularly**
   - Keep Haven **updated to latest version**
   - Review **release notes** before updating
   - Test after updates

6. **Secure Your Start9**
   - Use strong **Start9 password**
   - Enable **2FA** if available
   - Keep **Start9 OS updated**

7. **WoT Configuration**
   - Use **WoT depth 2** for good balance
   - Set **minimum followers** to filter spam
   - Review WoT settings periodically

---

## 📚 Additional Resources

### Documentation
- [Haven GitHub](https://github.com/bitvora/haven)
- [Nostr Protocol (NIPs)](https://github.com/nostr-protocol/nips)
- [Blossom Specification](https://github.com/hzrd149/blossom)
- [Start9 Documentation](https://docs.start9.com)

### Support
- **GitHub Issues**: [Haven Issues](https://github.com/bitvora/haven/issues)
- **Start9 Community**: [community.start9.com](https://community.start9.com)
- **Nostr**: Contact @bitvora

### Nostr Resources
- [NIP-01: Basic Protocol](https://github.com/nostr-protocol/nips/blob/master/01.md)
- [NIP-42: Authentication](https://github.com/nostr-protocol/nips/blob/master/42.md)
- [NIP-96: HTTP File Storage](https://github.com/nostr-protocol/nips/blob/master/96.md)

---

## 🎉 You're All Set!

Enjoy your **sovereign Nostr infrastructure**! 🚀

Your Haven relay suite provides:
- ✅ Private, secure storage
- ✅ Spam-free direct messages
- ✅ Decentralized media hosting
- ✅ Complete ownership of your data
- ✅ Tor-only privacy protection

**Happy Nostr-ing!** 🟣

---

*Haven is built with ❤️ by the Nostr community.*

