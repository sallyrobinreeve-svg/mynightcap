# NightCapt – Capture the Chaos

A mobile-first social app for recording and sharing night-out recaps. Spill the tea, lock in the memory.

A social journal app for recording and sharing post-night-out memories: outfit photos, favourite photos, reflection prompts, and an interactive timeline.

## Features (MVP)

- **Auth** – Email sign up / sign in (including magic link)
- **Entry creation** – Step-by-step wizard:
  - Date of night
  - Photos (outfit + favourite)
  - Rating (1–5 stars)
  - Prompts: who was drunkest, funniest thing, mission, success, who kissed who (with privacy toggle)
  - Interactive timeline (Pres → Club → Bar → Afters → Other)
  - Review & visibility (private / friends / public)
- **Profile** – Basic profile view with entry count
- **Entries list & detail** – View all entries and full entry detail with timeline

## Social Features

- **Follow friends** – Search and follow users by display name
- **Friend feed** – Chronological feed of your entries and friends' entries
- **Comments** – Add and delete comments on entries
- **Reactions** – React to entries (fire, heart, laugh, wild)
- **Tag friends** – Tag people you follow when creating entries
- **Missions highlights** – "Top missions this week" section
- **Memories archive** – Photo grid of past nights
- **Bottom navigation** – Feed, Create, Memories, Profile

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run the migrations in order:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_social_features.sql`
   - `supabase/migrations/003_prompts_and_emoji.sql`
   - `supabase/migrations/004_user_stats.sql`
   - `supabase/migrations/005_edit_video_mission.sql`
   - `supabase/migrations/006_kissed_prompt_update.sql`
   - `supabase/migrations/007_ugc_safeguards.sql`
   - `supabase/migrations/008_follow_requests.sql`
   - `supabase/migrations/009_photos_timeline_view.sql`
   - `supabase/migrations/010_notifications_seen.sql`
   - `supabase/migrations/011_terms_acceptance_profile_trigger.sql`

3. Create a storage bucket:
   - Go to Storage → New bucket
   - Name: `photos`
   - Public: Yes
   - Add policy: authenticated users can `INSERT`, everyone can `SELECT`

4. Configure auth redirect:
   - Authentication → URL Configuration
   - Add `http://localhost:3000/auth/callback` to Redirect URLs
   - Add `https://mynightcap.vercel.app/auth/callback` to Redirect URLs
   - Add `com.mynightcap.app://auth/callback` to Redirect URLs

5. Copy `.env.local.example` to `.env.local` and add your Supabase URL and keys:

   ```
   NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
   NEXT_PUBLIC_SITE_URL=https://mynightcap.vercel.app
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   RESEND_API_KEY=your_resend_key
   UGC_ALERT_EMAIL=nightcapt1@outlook.com
   ```

### 3. Run the app

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Mobile release

- Set the same production environment variables in Vercel before building the native app.
- Run `npm run screenshots:ipad` before App Store resubmission and upload `screenshots-output/ipad-13inch.png`.
- Codemagic builds the remote Capacitor shell from `codemagic.yaml`, reads the marketing version from `package.json`, and generates a unique build number.
- For App Store review, set the Support URL to `https://mynightcap.vercel.app/support` and Privacy Policy URL to `https://mynightcap.vercel.app/privacy`.

## Tech stack

- **Next.js 14** (App Router)
- **Supabase** (auth, database, storage)
- **Tailwind CSS**
- **TypeScript**
