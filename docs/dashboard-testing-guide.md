# Dashboard Testing Guide

## Quick Test Instructions

### 1. Build the Package

```bash
cd /Users/apple/work/haven-start9-wrapper
make
```

This will:
- Build the Docker image
- Create `haven.s9pk` package file

### 2. Install on Start9

#### Option A: Via Start9 UI
1. Go to Start9 System > Sideload Service
2. Upload `haven.s9pk`
3. Configure your OWNER_NPUB
4. Start the service

#### Option B: Via CLI
```bash
start-cli package install haven.s9pk
```

### 3. Access the Dashboard

1. Wait for Haven to start (check logs)
2. Click **"LAUNCH UI"** button in Start9
3. On the landing page, click **"📊 View Database Dashboard"**

Or visit directly:
```
http://<your-haven-address>.local/dashboard
```

### 4. Verify Functionality

#### Check Statistics
- [ ] Dashboard loads without errors
- [ ] Total events count is displayed
- [ ] Event kinds count is shown
- [ ] Refresh button works

#### Check Event Cards
- [ ] Kind cards display correctly
- [ ] Each card shows kind number and count
- [ ] Database badges (private/chat/outbox/inbox) are visible
- [ ] Event descriptions are readable

#### Check Event Viewer
- [ ] Click a kind card
- [ ] Modal opens with JSON viewer
- [ ] Events load correctly
- [ ] JSON is properly formatted
- [ ] Close button works

### 5. Test with Real Data

#### Option 1: Run Import
```bash
# In Start9 UI, run the "Import Notes" action
# Or via CLI:
docker exec <container-id> /usr/local/bin/importNotes.sh
```

After import completes:
1. Refresh the dashboard
2. You should see imported events
3. Check different databases have events

#### Option 2: Post a Test Event
```bash
# Use any Nostr client (Damus, Amethyst, etc.)
# Add your Haven relay: ws://<your-onion-address>
# Post a note
# Check if it appears in the dashboard
```

### 6. Test API Endpoints Directly

#### Stats Endpoint
```bash
# Inside container or via curl
curl http://localhost:3355/api/stats | jq
```

Expected output:
```json
{
  "stats": [
    {
      "kind": 0,
      "count": 1,
      "db": "private"
    },
    {
      "kind": 1,
      "count": 42,
      "db": "outbox"
    }
  ],
  "total": 43
}
```

#### Events Endpoint
```bash
# Get kind 1 events from outbox
curl "http://localhost:3355/api/events/1?db=outbox" | jq
```

### 7. Test Database Persistence

#### Verify Symlink
```bash
docker exec <container-id> ls -la /app/db
# Should show: /app/db -> /data/db
```

#### Verify Data Directory
```bash
docker exec <container-id> ls -la /data/db/
# Should show: outbox/, inbox/, private/, chat/, blossom/
```

#### Test Container Restart
1. Note the event counts in dashboard
2. Restart Haven service in Start9
3. Wait for service to start
4. Refresh dashboard
5. **Verify**: Event counts should be the same (data persisted)

### 8. Check Logs

```bash
# View Haven logs
docker logs <container-id>

# Should NOT see errors like:
# - "Failed to query events"
# - "Database not initialized"
# - "Template not found"

# SHOULD see:
# - "🔗 listening at 0.0.0.0:3355"
# - "Tor Hidden Service started"
```

## Common Issues & Solutions

### Issue: Dashboard shows "Loading..." forever
**Solution**: 
- Check browser console for errors
- Verify `/api/stats` endpoint works: `curl http://localhost:3355/api/stats`
- Check Haven logs for Go panics

### Issue: "No events" but you know there should be data
**Solution**:
- Verify database exists: `docker exec <container> ls /data/db/`
- Check database permissions
- Try restarting Haven
- Check if symlink is correct: `docker exec <container> ls -la /app/db`

### Issue: Modal doesn't open when clicking cards
**Solution**:
- Check browser console for JavaScript errors
- Verify `/api/events/` endpoint works
- Try clearing browser cache

### Issue: "Invalid db parameter" error
**Solution**:
- Dashboard might be querying wrong database name
- Check API logs to see which db parameter was sent
- Verify database names in Go code match (private/chat/outbox/inbox)

## Testing Checklist

### Functional Tests
- [ ] Dashboard loads on `/dashboard`
- [ ] Statistics load correctly
- [ ] All 4 databases are represented
- [ ] Kind cards render
- [ ] Modal opens when clicking cards
- [ ] JSON displays correctly
- [ ] Refresh button updates stats
- [ ] Close modal button works

### Data Persistence Tests
- [ ] Events persist after restart
- [ ] Database symlink is correct
- [ ] `/data/db/` contains subdirectories
- [ ] No data loss after container restart

### API Tests
- [ ] `/api/stats` returns valid JSON
- [ ] `/api/events/{kind}?db={name}` returns events
- [ ] CORS headers are set
- [ ] Error handling works (invalid kind, invalid db)

### UI/UX Tests
- [ ] Responsive design works on mobile
- [ ] Loading indicators display
- [ ] Error messages are user-friendly
- [ ] Colors/styling consistent with Haven theme
- [ ] No broken links
- [ ] Button hover effects work

## Performance Tests

### Small Database (< 1000 events)
- Stats should load in < 2 seconds
- Event lists should load in < 1 second

### Medium Database (1000-10000 events)
- Stats should load in < 5 seconds
- Event lists might take 2-5 seconds

### Large Database (> 10000 events)
- Consider implementing pagination
- May need optimization for QueryEvents

## Security Verification

- [ ] Dashboard only accessible via Tor
- [ ] API endpoints have CORS configured
- [ ] No sensitive data exposed
- [ ] Database queries are filtered (not returning all data at once)

## Documentation Verification

- [ ] README mentions dashboard
- [ ] API endpoints documented
- [ ] Screenshots/examples included
- [ ] Troubleshooting section complete

## Next Steps After Testing

1. Document any bugs found
2. Add feature requests to backlog
3. Consider adding:
   - Pagination for large result sets
   - Search/filter functionality
   - Export to JSON feature
   - Real-time updates via WebSocket

## Reporting Issues

When reporting bugs, include:
- Haven version
- Start9 OS version
- Database engine (LMDB/Badger)
- Number of events in database
- Browser console logs
- Haven container logs
- Steps to reproduce

## Success Criteria

✅ Dashboard loads without errors
✅ Statistics display correctly
✅ Events can be viewed as JSON
✅ Data persists across restarts
✅ No linter errors in Go code
✅ Documentation is complete

---

**Happy Testing! 🎉**

If you encounter issues, check the [troubleshooting section](./database-dashboard.md#troubleshooting) or open an issue on GitHub.

