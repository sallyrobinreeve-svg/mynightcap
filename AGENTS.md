# AGENTS.md

NightCapt is a single Next.js 14 (App Router) + TypeScript app backed by Supabase
(auth, Postgres, storage). It also ships as an iOS app via Capacitor, but the
native shell just loads the hosted web URL, so iOS/Capacitor is not needed for
web development. There are no automated tests in this repo.

Standard commands live in `package.json` (`npm run dev`, `npm run build`,
`npm run lint`). Setup steps live in `README.md`.

## Cursor Cloud specific instructions

For local development the app runs against a **local Supabase stack** (Docker),
so no hosted Supabase project or secrets are required. The Docker engine and the
`supabase` CLI are preinstalled in the VM image.

Startup sequence for a fresh session (run from the repo root, `/workspace`):

1. Start the Docker daemon if it is not already running, and make the socket
   usable without sudo:
   - `sudo dockerd` (run it in a background/tmux session; it is not a systemd service here)
   - `sudo chmod 666 /var/run/docker.sock`
2. Start Supabase: `supabase start` (first run pulls images; subsequent runs are
   fast). Use `supabase status -o env` to print local URLs/keys.
3. Ensure `.env.local` exists (it is git-ignored). The local stack always uses
   the standard Supabase demo keys, so this file is deterministic:
   ```
   NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
   NEXT_PUBLIC_SITE_URL=http://localhost:3000
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
   ```
4. Run the app: `npm run dev` (http://localhost:3000). Verify with
   `curl http://localhost:3000/api/health` — it returns 200 when the public
   Supabase env vars are set, 503 otherwise.

Local Supabase config lives in `supabase/config.toml` and `supabase/seed.sql`
(added for cloud dev). Important gotchas:

- **Table grants:** the SQL migrations enable RLS and define policies but never
  `GRANT` table privileges. On recent local Supabase, new `public` tables only
  get TRUNCATE/REFERENCES/TRIGGER for `anon`/`authenticated`, so any read/write
  fails with `permission denied for table ...` (e.g. "Failed to load feed",
  "permission denied for table entries"). `supabase/seed.sql` restores the
  standard `select/insert/update/delete` grants and is applied automatically by
  `supabase start` / `supabase db reset`. If you wipe state manually, re-run
  `supabase db reset` so the seed re-applies.
- **Email confirmation is disabled locally** (`auth.email.enable_confirmations =
  false`), so signup activates the account immediately. The signup page still
  shows "Check your email to confirm your account!" — ignore it and just sign in.
  Sent emails are viewable in Mailpit at http://127.0.0.1:54324.
- The `photos` storage bucket and its policies are also created by
  `supabase/seed.sql`; photo uploads need it.
- `next build` overwrites `.next`; if the dev server was running, restart
  `npm run dev` afterwards.
