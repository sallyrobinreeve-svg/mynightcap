"use client";

export type AuthMethod = "phone" | "email";

export function AuthMethodToggle({
  value,
  onChange,
}: {
  value: AuthMethod;
  onChange: (next: AuthMethod) => void;
}) {
  const tabClass = (active: boolean) =>
    `rounded-lg px-4 py-2.5 text-sm font-medium transition ${
      active ? "bg-nightcap-accent text-white" : "text-nightcap-muted hover:text-white"
    }`;

  return (
    <div className="mb-6 grid grid-cols-2 rounded-xl border border-white/10 bg-nightcap/80 p-1">
      <button
        type="button"
        className={tabClass(value === "phone")}
        onClick={() => onChange("phone")}
      >
        UK phone
      </button>
      <button
        type="button"
        className={tabClass(value === "email")}
        onClick={() => onChange("email")}
      >
        Email
      </button>
    </div>
  );
}

export function UkAuthNotice({
  method,
  intent = "signin",
}: {
  method: AuthMethod;
  intent?: "signin" | "signup";
}) {
  return (
    <p className="mb-6 text-sm text-nightcap-muted">
      {method === "phone"
        ? "Phone authentication is for UK users only. If you're outside the UK, use email."
        : intent === "signup"
          ? "Outside the UK? Create an account with email. Phone login is for UK mobiles only."
          : "Outside the UK? Sign in with email. Phone login is for UK mobiles only."}
    </p>
  );
}
