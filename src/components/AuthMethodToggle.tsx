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
        Phone
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
