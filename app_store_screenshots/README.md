# App Store screenshots (version 1.8.0)

Upload these in App Store Connect. First screenshot is the one people see on the product page.

Apple previously rejected a **login-only iPad** shot. Do not lead with Sign in.

## iPhone 6.5" — use these (1284 × 2778)

App Store Connect is asking for **1242 × 2688**, **1284 × 2778**, or the landscape versions of those. These files are **1284 × 2778** portrait.

Drag these into the iPhone screenshot slot:

| Order | File | Size | Caption (optional) |
| --- | --- | --- | --- |
| 1 | `01_iphone_feed.png` | 1284 × 2778 | Recap the night. See your friends’ nights. |
| 2 | `02_iphone_create.png` | 1284 × 2778 | Rate the night. Keep any answer private. |
| 3 | `03_iphone_memories.png` | 1284 × 2778 | Your nights, as a photo grid. |
| 4 | `04_iphone_profile.png` | 1284 × 2778 | Your profile. Your lore. |
| 5 | `05_iphone_friends.png` | 1284 × 2778 | Find friends. Accept requests. |
| 6 | `06_iphone_uk_phone_signin.png` | 1284 × 2778 | UK phone login, or email if you’re outside the UK. |

If Connect still rejects 1284 × 2778, use the copies in `iphone_1242x2688/` (1242 × 2688). Same order.

Do **not** upload the old 1320 × 2868 files into this slot. Those are 6.9" only (`iphone_69_1320x2868/`).

Landscape (2688 × 1242 or 2778 × 1284) is only if you captured the app sideways. These shots are portrait — use the portrait sizes.

## iPad 12.9" / 13" — drag these 3 screenshots

Skip **app previews** (those are videos). You only need screenshots.

Apple accepts **2064 × 2752** or **2048 × 2732** portrait (landscape is 2752 × 2064 or 2732 × 2048). These are portrait. Do not rotate them.

**Logged-in only.** No Sign in on iPad — Apple already rejected that.

### If Connect wants 2064 × 2752 (13")

Upload from `ipad_2064x2752/`:

| Order | File | Size |
| --- | --- | --- |
| 1 | `01_ipad_feed_2064x2752.png` | 2064 × 2752 |
| 2 | `02_ipad_create_2064x2752.png` | 2064 × 2752 |
| 3 | `03_ipad_profile_2064x2752.png` | 2064 × 2752 |

### If Connect wants 2048 × 2732 (12.9")

Upload from `ipad_2048x2732/` (same screens as `07` / `08` / `09` at repo root):

| Order | File | Size |
| --- | --- | --- |
| 1 | `01_ipad_feed_2048x2732.png` | 2048 × 2732 |
| 2 | `02_ipad_create_2048x2732.png` | 2048 × 2732 |
| 3 | `03_ipad_profile_2048x2732.png` | 2048 × 2732 |

Try **2064 × 2752** first if that is the size listed in the drop zone. If it rejects, use **2048 × 2732**.

## Better if you have TestFlight

These are neon mockups of the Flutter UI. If the TestFlight build is on your iPhone, capture the real Feed / Create / Memories / Profile, then resize to **1284 × 2778** (or 1242 × 2688) and replace these.
