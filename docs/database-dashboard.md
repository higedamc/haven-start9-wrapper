# Haven Database Dashboard

## Overview

The Haven Database Dashboard provides a web interface to view and inspect stored Nostr events in your Haven relay databases.

## Features

### 📊 Statistics View
- **Total Events**: View the total number of events stored across all databases
- **Event Kinds**: See how many different event types (kinds) are stored
- **Database Breakdown**: Events are categorized by database (private, chat, outbox, inbox)

### 🔍 Event Inspection
- **Kind Cards**: Each event kind is displayed in a card showing:
  - Kind number
  - Event count per database
  - Human-readable description of the event type
- **JSON Viewer**: Click any kind card to view the raw JSON data of all events of that kind

## Access

### On Start9 Server
1. Open your Haven service in Start9 UI
2. Click **"LAUNCH UI"** button
3. You'll see the main Haven landing page
4. Click **"📊 View Database Dashboard"** button

The dashboard will be available at: `http://<your-haven-onion-address>.local/dashboard`

### Direct URL
```
http://<your-tor-address>/dashboard
```

## API Endpoints

The dashboard uses the following API endpoints:

### GET /api/stats
Returns statistics about all stored events grouped by kind and database.

**Response:**
```json
{
  "stats": [
    {
      "kind": 1,
      "count": 150,
      "db": "outbox"
    },
    {
      "kind": 3,
      "count": 5,
      "db": "private"
    }
  ],
  "total": 155
}
```

### GET /api/events/{kind}?db={database}
Returns all events of a specific kind from a specific database.

**Parameters:**
- `kind` (path): The Nostr event kind number
- `db` (query): Database name (`private`, `chat`, `outbox`, `inbox`)

**Example:**
```
GET /api/events/1?db=outbox
```

**Response:**
```json
[
  {
    "id": "event-id-here",
    "pubkey": "pubkey-here",
    "created_at": 1234567890,
    "kind": 1,
    "tags": [],
    "content": "Hello, Nostr!",
    "sig": "signature-here"
  }
]
```

## Supported Event Kinds

The dashboard includes descriptions for common Nostr event kinds:

| Kind | Description |
|------|-------------|
| 0 | User Metadata |
| 1 | Text Note |
| 3 | Contacts |
| 4 | Encrypted Direct Messages |
| 7 | Reaction |
| 40-44 | Channel Events |
| 1059 | Gift Wrap |
| 9734-9735 | Zap Request/Receipt |
| 10000-10002 | Lists (Mute, Pin, Relay) |
| 30023 | Long-form Content |

And many more...

## Database Structure

Haven uses 4 separate databases:

- **private**: Personal events (authenticated access only)
- **chat**: Chat-related events (WoT-protected)
- **outbox**: Published events (owner's public notes)
- **inbox**: Received events (from WoT contacts)

## Use Cases

### 1. Verify Database Persistence
After the recent fix to `docker_entrypoint.sh`, you can use this dashboard to confirm that:
- Events are being stored correctly
- The database symlink (`/app/db -> /data/db`) is working
- Data persists across container restarts

### 2. Debug Import Issues
When running the import function:
- Check if imported events are appearing
- Verify which databases contain imported data
- Inspect event content to ensure proper formatting

### 3. Monitor Relay Activity
- Track the number of events in each database
- See which event kinds are most common
- Identify any unusual patterns

### 4. Data Inspection
- View raw JSON of stored events
- Verify event signatures and metadata
- Troubleshoot client compatibility issues

## Technical Details

### Implementation
- **Backend**: Go (added to `main.go`)
- **Frontend**: Pure HTML/JavaScript with Tailwind CSS
- **Database Access**: Uses existing `DBBackend` interface
  - `QueryEvents()`: Retrieves events
  - `CountEvents()`: Gets statistics

### Performance Considerations
- Event queries use filters to limit results
- Large databases may take a few seconds to load statistics
- JSON rendering is client-side (browser-based)

### Security
- Dashboard is accessible via Tor hidden service
- Uses same authentication/access controls as Haven itself
- CORS enabled for API endpoints

## Troubleshooting

### Dashboard Not Loading
1. Check that Haven is running: `docker logs <container-id>`
2. Verify the `/dashboard` endpoint is accessible
3. Check browser console for JavaScript errors

### "No Events" Displayed
1. Ensure databases exist at `/data/db/`
2. Check database permissions: `ls -la /data/db/`
3. Verify events were imported/created successfully

### API Errors
1. Check Haven logs for Go errors
2. Verify database backend (LMDB/Badger) is initialized
3. Test API endpoints directly: `curl http://localhost:3355/api/stats`

## Future Enhancements

Possible improvements:
- [ ] Pagination for large event lists
- [ ] Search/filter by pubkey, date, content
- [ ] Export events as JSON file
- [ ] Event deletion interface
- [ ] Real-time updates (WebSocket)
- [ ] Database size statistics
- [ ] Event signature verification UI

## Related Documentation

- [Haven Database Fix](../docs/import-detailed-logging.md)
- [Start9 Implementation](../docs/start9-implementation-checklist.md)
- [Nostr Protocol](https://github.com/nostr-protocol/nips)

