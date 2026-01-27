# Deep Linking Requirements

Purpose: specify how external links, intents, and app links route into the app.

- **Supported targets**: Media details (by id), actor profile (by id), specific list or saved item, and home sections.
- **URL scheme**: Define canonical HTTP(S) app links and an optional custom scheme (`mediavore://`) for internal testing.
- **Fallback behavior**: If a target is unavailable, direct the user to the closest fallback (home or search) and show a message.
- **Parameter handling**: Accept optional query params (e.g., source, episode index) and surface them to the destination screen.
- **Cold-start routing**: When opening a deep link from a cold start, finish any initialization (DB, settings) before navigation.
- **Testing**: Provide integration tests that simulate opening each supported link on cold and warm app states.

Notes: See `DOCS/DEEP_LINKING.md` for design examples and routing mappings.
