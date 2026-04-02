---
name: create-event
description: "Create or restyle Google Calendar events with consistent formatting."
---

# create-event

Create or restyle Google Calendar events with a consistent style guide.

## Modes

- **Create** — parse input (URL, photo, PDF, text) → extract event details → apply style guide → upload attachments to Drive → create calendar event
- **Restyle** — fetch existing event(s) by name/date/range → reformat to match conventions → update

---

## Style Guide

### Title format

`Type: Entity — topic` (only include parts that exist)

Rules:
- Use English for event titles, even if source is in another language (translate key info)
- Omit yourself — just name the other party
- No filler words ("about", "regarding", "with")
- Front-load important info
- No emoji
- Use ` — ` (em dash with spaces) to separate entity from topic

### Title examples by category

| Category | Format | Example |
|----------|--------|---------|
| Flight | `Flight: ORIGIN → DEST` | `Flight: SFO → JFK` |
| Train | `Train: ORIGIN → DEST` | `Train: Kyiv → Lviv` |
| Doctor | `Dentist: Dr. Name` / `Doctor: Specialty` | `Dentist: Dr. Smith` |
| Procedure | `Type: Place` | `Haircut: Barbershop X` |
| Concert | `Concert: Artist — Venue` | `Concert: Radiohead — MSG` |
| Meet (in-person) | `Meet: Name` | `Meet: Jane Doe` |
| Call (remote) | `Call: Entity — topic` | `Call: Startale — intro` |
| Interview | `Interview: Company — type` | `Interview: Chrona — technical` |
| Follow-up | `Follow-up: topic` | `Follow-up: NFD offer` |
| Focus time | `Focus: topic` | `Focus: cover letters` |
| Simple activity | Just the word | `Surf` |
| 1:1 (shared cal) | `Name / Name` | `Fedor / Jane Doe` |

### Reminder levels

| Level | Categories | Reminders |
|-------|-----------|-----------|
| High | Flights, doctor, procedures | 1 day (1440 min), 2 hours (120 min), 30 min |
| Medium | Concerts, trains, interviews | 1 day (1440 min), 1 hour (60 min) |
| Low | Meets, calls, focus, 1:1s | 30 min |

### Attachments

- **URLs** → add to description under a "Source" section
- **Local files** (PDF, photo, pasted images, etc.) → upload to Google Drive `Calendar Attachments` folder via `gws drive +upload <file> --parent 1mwCs8JBvEoSjP0o3IU1LroCH9dOHSPTF` → attach Drive link to event + add to description

### Description

Agent decides format based on context. No strict template enforced. Include relevant details extracted from input. Include source links/references.

### Timezone

Use default calendar timezone.

## Create mode workflow

1. Accept input (user provides URL, file path, screenshot, or text)
2. Parse input — read file/URL/image to extract: event name, date/time, location, relevant details
3. Apply title conventions from style guide above
4. Determine reminder level based on event category
5. If local file provided:
   a. Upload file via `gws drive +upload <file> --parent 1mwCs8JBvEoSjP0o3IU1LroCH9dOHSPTF`
   b. Note the Drive file URL from the response
6. Compose event description (contextual format, include source links)
7. Create event via `gcal_create_event` with:
   - title (styled per conventions)
   - start/end time
   - location (if applicable)
   - description
   - reminders (per level table, `useDefault: false` with `overrides`)
   - attachments (Drive file links if any)
8. Show confirmation to user

## Restyle mode workflow

1. User specifies target: event name, date range, or "restyle my events for next week"
2. Fetch events via `gcal_list_events` with appropriate time range
3. For each event, compare title against conventions
4. Propose changes — show before → after for each event
5. After user confirmation, apply via `gcal_update_event`
6. Also fix reminders to match the category's reminder level
