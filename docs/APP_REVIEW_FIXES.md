# App Review Fixes – Resubmission Checklist

After receiving App Review feedback, these changes were made. Use this checklist before resubmitting.

---

## 1. iPad Screenshots (Guideline 2.3.3)

**Issue:** 13-inch iPad screenshot showed only login screen.

**Fix:** The `resize-for-ipad.js` script now prefers app-in-use screens (feed, profile, new entry) over the landing page.

**Action:** Run `node scripts/resize-for-ipad.js` to regenerate. Ensure `screenshots-input` contains a logged-in screenshot (feed or profile). If your captures are all login screens, manually add a screenshot of the feed/profile while logged in, name it `04-feed.png` or `06-profile.png`, then run the script. Upload the new `screenshots-output/ipad-13inch.png` to App Store Connect.

---

## 2. Profile Edit → Take Photo Crash (Guideline 2.1)

**Issue:** App crashed when tapping Take Photo on iPad (Profile → Edit → Take Photo).

**Fix:** On native (Capacitor), the app now uses the Capacitor Camera plugin with **Photos only** (gallery) instead of the web file input. This avoids the known WKWebView crash when using the camera on iPad.

**Action:** Rebuild and test on iPad. Profile photo now uses "Choose from library" only on iOS.

---

## 3. Support URL (Guideline 1.5)

**Issue:** Support URL (homepage) did not direct to a page with support information.

**Fix:** Created `/support` page with contact email, FAQs, and links to Privacy/Terms.

**Action:** In App Store Connect, update **Support URL** to:
```
https://mynightcap.vercel.app/support
```

---

## 4. User-Generated Content Safeguards (Guideline 1.2)

**Fix:** Implemented:

- **Terms of Use (EULA)** – `/terms` with zero-tolerance policy for objectionable content
- **Terms acceptance** – Required checkbox on signup
- **Report content** – Report button on entries and comments (⋮ menu)
- **Block user** – Block button on profiles and in report menu; blocked users’ content is removed from feed instantly
- **Content filtering** – Basic filter on comment creation (`src/lib/content-filter.ts` – expand blocklist as needed)
- **Reports table** – Reports stored in `reports` table; developer must review and act within 24 hours

**Action:** Run the new migration in Supabase:

```sql
-- Run supabase/migrations/007_ugc_safeguards.sql in Supabase SQL Editor
```

---

## 5. Before Resubmitting

1. [ ] Deploy the latest code to Vercel
2. [ ] Run migration `007_ugc_safeguards.sql` in Supabase
3. [ ] Update Support URL in App Store Connect to `https://mynightcap.vercel.app/support`
4. [ ] Upload new iPad screenshot (app-in-use, not login)
5. [ ] Bump version/build, push, and run Codemagic build
6. [ ] Test on iPad: Profile → Edit → tap profile picture (should open photo library, not crash)
