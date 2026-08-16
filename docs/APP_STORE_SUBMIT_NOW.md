# Submit NightCapt to the App Store

Use this list in order. Code-side review prep is already in the Flutter iOS project.

## Already done in the app

- Neon Instagram-style iPhone UI, UK phone / email auth, privacy toggles
- iOS encryption flag (`ITSAppUsesNonExemptEncryption` = false)
- `PrivacyInfo.xcprivacy` (no tracking; phone, email, name, photos, recap content)
- Codemagic Flutter iOS build **fails** if `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing
- Support, privacy, and terms pages on the website

## Your steps

### 1. Deploy the website

Push/merge this branch and confirm Vercel is live:

- https://mynightcap.vercel.app/support
- https://mynightcap.vercel.app/privacy
- https://mynightcap.vercel.app/terms

### 2. Run the phone-profile SQL in Supabase

Supabase → SQL Editor → paste and run `supabase/migrations/012_phone_auth_profile.sql` if you have not already.

This makes phone-only accounts get a profile.

### 3. Turn Twilio into a real SMS sender

Twilio trial can only text numbers you verified.

1. Upgrade the Twilio account off trial
2. Keep the **UK** sender number
3. In Supabase → Authentication → Phone, confirm Twilio is still the SMS provider
4. Send one real UK mobile a code from the app and confirm it arrives

Reviewers will use **email**, so this is for real UK users, not for Apple.

### 4. Put keys in Codemagic

Codemagic → environment group `nightcapt`:

- `SUPABASE_URL` = `https://wnnpbjwtmayzfcdduvhq.supabase.co`
- `SUPABASE_ANON_KEY` = the **anon / public** key (same as the website)
- `SITE_URL` = `https://mynightcap.vercel.app`

Then run workflow **NightCapt Flutter iOS**. It should upload a TestFlight build. Version is `1.8.0`; the build number is generated automatically.

### 5. Create a reviewer demo account

In the live app (or website), create an **email** account. Do not use phone.

Fill it so Feed is not empty:

- Display name and username
- 4–6 recaps with photos
- At least one friend and a couple of comments

Write down:

- Email
- Password

### 6. TestFlight on your iPhone

Install the new build. As a **new email user**, check:

- Sign in with Email (not UK phone)
- Create a recap with photos, stars, mission, kiss, Keep this private
- Friends search / request
- Report and block on a post menu
- Profile → Edit profile photo from library
- Profile → Delete account (use a throwaway, not the demo account)

If you have an iPad, open the same build once. Apple still lists iPad because the app supports it.

### 7. App Store Connect listing

App Store Connect → NightCapt → this version:

| Field | Value |
| --- | --- |
| Name | NightCapt |
| Support URL | https://mynightcap.vercel.app/support |
| Privacy Policy URL | https://mynightcap.vercel.app/privacy |
| Category | Social Networking or Lifestyle |
| Age rating | **17+** (alcohol references, mature themes, user-generated content) |

Description and keywords: see `docs/APP_STORE_LISTING_GUIDE.md`.

**App Privacy** questionnaire (must match the app):

- Phone number — used for account, linked to identity, not used for tracking
- Email address — same
- Name — same
- Photos / videos — user content
- Other user content — recaps, comments
- No tracking

### 8. What's New and screenshots

**What's New** (paste):

```
UK phone login for UK mobiles, email for everyone else. New neon look. Recap prompts including Rate the night, mission, and Keep this private on every answer.
```

**Screenshots:** yes, new ones. The old login-only / pre-neon shots will get you rejected again.

Upload **logged-in** screens first, not Sign in.

Files are in `app_store_screenshots/` (see the README there for order and captions).

- iPhone 6.5" (**1284 × 2778**): `01_iphone_feed.png` → Create → Memories → Profile → Friends → UK phone sign-in last. If Connect wants 1242 × 2688, use `iphone_1242x2688/`.
- iPad 13" (2048 × 2732): Feed → Create → Profile. No login shot on iPad. Apple previously rejected that.

Best: recapture the same screens from TestFlight on a real iPhone and replace the mockups.

### 9. Review Notes (paste this)

```
NightCapt is a nightlife recap journal.

Sign in with EMAIL, not phone. Phone login is for UK mobiles only (+44 7…) and will not work for US numbers.

Demo account:
Email: [PASTE EMAIL]
Password: [PASTE PASSWORD]

After login you should see Feed with sample recaps. Create is the centre tab. Report/block is on the ⋯ menu on a post. Account deletion is Profile → Account → Delete account.

Support: nightcapt1@outlook.com
We review reports within 24 hours and may remove content or accounts.
```

### 10. Submit

1. Confirm TestFlight build is the one attached to this version
2. Submit for review
3. Watch email for Apple questions (often 24–48 hours)

Do not submit an older Capacitor/web build. Use the Flutter workflow only.
