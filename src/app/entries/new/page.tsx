import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { EntryWizard } from "@/components/EntryWizard";
import { NeonLogo } from "@/components/NeonLogo";

export default async function NewEntryPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/signin");
  }

  return (
    <div className="min-h-screen bg-nightcap">
      <nav className="glass sticky top-0 z-10 border-b border-white/5">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <NeonLogo className="text-3xl" />
        </div>
      </nav>

      <main className="mx-auto max-w-2xl px-4 py-12">
        <h1 className="text-4xl font-semibold text-white mb-2">New entry</h1>
        <p className="text-nightcap-muted mb-8">
          Save the night. Photos, the recap, the route.
        </p>
        <EntryWizard userId={user.id} />
      </main>
    </div>
  );
}
