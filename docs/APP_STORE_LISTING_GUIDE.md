# NightCapt – Complete App Store Listing Guide

Everything you need to fill in App Store Connect and generate screenshots.

---

## Part 1: Screenshot Requirements (2024)

### Required sizes
- **iPhone 6.5" (this listing):** 1284 × 2778 or 1242 × 2688 portrait (landscape: 2778 × 1284 or 2688 × 1242). Upload **1284 × 2778** from `app_store_screenshots/`.
- **iPhone 6.9" (only if Connect shows that slot):** 1320 × 2868 — extras in `app_store_screenshots/iphone_69_1320x2868/`
- **iPad 12.9" / 13":** 2064 × 2752 or 2048 × 2732 portrait (landscape: 2752 × 2064 or 2732 × 2048). Upload Feed, Create, Profile from `app_store_screenshots/ipad_2064x2752/` or `ipad_2048x2732/`. No login shot.

### Format
- JPEG, JPG, or PNG

---

## Part 2: How to Generate Screenshots (No Mac Needed)

### Option A: Screenshot your live app in a browser

1. Go to [mynightcap.vercel.app](https://mynightcap.vercel.app) on your phone or in Chrome
2. Sign in and navigate to key screens
3. Take screenshots (or use Chrome DevTools to simulate iPhone size)
4. Use an online tool to add device frames (see Option B)

### Option B: Use a free online screenshot generator

1. **Screenshot your app** – Open mynightcap.vercel.app, resize browser to ~390px wide (iPhone width), take screenshots of:
   - Feed
   - A journal entry
   - Profile
   - New entry screen

2. **Add device frames** – Go to one of these (no account needed):
   - [StoreSnaps](https://www.storesnaps.com/) – Free, no account
   - [Screenshot Generator](https://www.screenshotgen.dev/) – Processes locally in browser
   - [AppScreen Studio](https://appscreenstudio.com/) – Free templates

3. **Upload your screenshots** → Choose iPhone 6.9" or 6.5" → Export

### Option C: Chrome DevTools (exact pixel size)

1. Open [mynightcap.vercel.app](https://mynightcap.vercel.app) in Chrome
2. Press **F12** → Click the device icon (or **Ctrl+Shift+M**)
3. Select **iPhone 15 Pro Max** (430 x 932) or **Responsive**
4. Set dimensions to **430 x 932** (scales to ~1320 x 2868)
5. Navigate to each screen, take screenshots (**Ctrl+Shift+P** → "Capture screenshot")
6. Resize images to 1320 x 2868 using [Photopea](https://www.photopea.com/) (free online Photoshop) or any image editor

### Ready-to-upload files

Use `app_store_screenshots/` in this repo. Upload order and captions are in `app_store_screenshots/README.md`.

- **iPhone 6.5"** (1284 × 2778): Feed, Create, Memories, Profile, Friends, then UK phone sign-in last. Alternate size: `iphone_1242x2688/` (1242 × 2688).
- **iPad 12.9" / 13":** Feed, Create, Profile — **logged-in only**. Use `ipad_2064x2752/` (2064 × 2752) or `ipad_2048x2732/` (2048 × 2732). Apple rejected a login-only iPad shot before.

If TestFlight is on your phone, capture the real Flutter screens at those sizes and replace the mockups.

### Screens to capture (in order)
1. **Feed** – logged-in recap feed (this should be first)
2. **Create** – recap prompts, stars, Keep this private
3. **Memories** – photo grid
4. **Profile** – 3-column grid
5. **Friends** – optional
6. **UK phone sign-in** – last, not first; skip this on iPad

---

## Part 3: App Store Connect – What to Fill In

### App Information

| Field | What to enter |
|-------|----------------|
| **Name** | NightCapt |
| **Subtitle** | (Optional, 30 chars max) e.g. "Nights out, recapped" |
| **Privacy Policy URL** | https://mynightcap.vercel.app/privacy |
| **Support URL** | https://mynightcap.vercel.app/support |
| **Category** | Primary: **Social Networking** or **Lifestyle** |
| **Secondary Category** | (Optional) **Photo & Video** or **Entertainment** |
| **Content Rights** | Check if you have rights to all content |
| **Age Rating** | **17+**. Answer yes for mature/suggestive themes, alcohol references, and user-generated content. |

---

### Description (4000 chars max)

```
NightCapt is your social journal for nights out. Capture the recap, keep the private bits private, and lock in the memory.

• Recap the night with photos, video, and prompts
• Sign in with a UK mobile code, or email if you are outside the UK
• Share with friends and see their nights
• Keep any answer private
• Browse Memories as a photo grid of past nights

Whether it was a big night or a quiet one, NightCapt is where the morning-after debrief lives.
```

---

### Keywords (100 chars max, comma-separated, no spaces after commas)

```
journal,social,night out,memories,friends,diary,stories,photos,nightlife
```

---

### Promotional Text (170 chars, can be updated anytime)

```
Capture the chaos. Spill the tea from last night. Your social journal for nights out is here.
```

---

### What's New (paste this for 1.8.0)

App Store Connect → this version → **What's New**. 4000 characters max. Keep it short.

**Use this:**

```
UK phone login for UK mobiles, email for everyone else. New neon look. Recap prompts including Rate the night, mission, and Keep this private on every answer.
```

Slightly longer option:

```
Sign in with a UK mobile code, or email if you’re outside the UK.

Fresh neon NightCapt look.

Recap the night with Rate the night, Who was the drunkest, The funniest bit, Anyone get kissed, mission, and Keep this private on every answer.
```

Do not mention Twilio, TestFlight, or Apple review workarounds here. Users see this on the product page.

---

### Support URL (required)

```
https://mynightcap.vercel.app/support
```

The Support section is on the Privacy page (which already works). Use this URL – Apple rejects the homepage as a support URL.

---

### Marketing URL (Optional)

```
https://mynightcap.vercel.app
```

---

### Version Information

| Field | Value |
|-------|-------|
| **Version** | 1.8.0 |
| **Copyright** | 2025 [Your Name or Company] – **Required** |
| **Trade Representative Contact** | Your email |

### Content Rights (App Information → Content Rights)

- **Content Rights Information** – Required before submission
- If users upload content: Select **Yes**, confirm you have rights or that user-generated content is allowed
- Add any third-party content disclosures if needed

### Pricing

- **Price** – Choose a price tier (select **Free** for a free app)
- App Store Connect → Your app → **Pricing and Availability** → set price

### App Privacy (Admin required)

- **App Privacy** – An Admin must complete this before submission
- App Store Connect → Your app → **App Privacy** → **Get Started**
- Declare what data you collect (e.g. account info, user content). For NightCapt: account/phone number, journal content, photos

---

## Part 4: Export Compliance

When you submit, Apple asks:

**Does your app use encryption?**
- If you only use HTTPS (standard web encryption): Select **No** – HTTPS is exempt
- If you have custom encryption: Select **Yes** and complete the form

For NightCap (Supabase auth, HTTPS): Usually **No** is correct.

---

## Part 5: Content Rights

**Does your app contain, display, or access third-party content?**
- **Yes** – if users can upload/share content (you do)
- Confirm you have rights or that user-generated content is allowed

---

## Part 6: Advertising Identifier (IDFA)

**Does your app use the Advertising Identifier?**
- **No** – unless you've added an ad network (e.g. Google Ads)

---

## Part 7: Step-by-Step Submission Checklist

1. [ ] Upload screenshots (at least 1 for 6.9" or 6.5" iPhone)
2. [ ] Add Description
3. [ ] Add Keywords
4. [ ] Add Privacy Policy URL
5. [ ] Select Category
6. [ ] Add Support URL
7. [ ] Select your build (from TestFlight)
8. [ ] Complete Age Rating questionnaire
9. [ ] Answer Export Compliance (usually No)
10. [ ] Click **Add for Review**
11. [ ] Answer any final questions
12. [ ] Click **Submit to App Review**

---

## Quick Copy-Paste Summary

**What's New:** UK phone login for UK mobiles, email for everyone else. New neon look. Recap prompts including Rate the night, mission, and Keep this private on every answer.

**Description (short):** NightCapt is your social journal for nights out. Capture the recap, keep the private bits private, and lock in the memory with friends.

**Keywords:** journal,social,night out,memories,friends,diary,stories,photos,nightlife

**Privacy Policy:** https://mynightcap.vercel.app/privacy

**Support URL:** https://mynightcap.vercel.app/support
