# NightCap – Capture the Chaos

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

3. Create a storage bucket:
   - Go to Storage → New bucket
   - Name: `photos`
   - Public: Yes
   - Add policy: authenticated users can `INSERT`, everyone can `SELECT`

4. Configure auth redirect:
   - Authentication → URL Configuration
   - Add `http://localhost:3000/auth/callback` to Redirect URLs

5. Copy `.env.local.example` to `.env.local` and add your Supabase URL and anon key:

   ```
   NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
   ```

### 3. Run the app

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Tech stack

- **Next.js 14** (App Router)
- **Supabase** (auth, database, storage)
- **Tailwind CSS**
- **TypeScript**
