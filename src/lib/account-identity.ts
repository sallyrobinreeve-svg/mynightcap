type AuthContact = {
  email?: string | null;
  phone?: string | null;
};

export function accountContact(user: AuthContact): string | null {
  return user.phone || user.email || null;
}

export function accountFallbackName(user: AuthContact): string {
  if (user.phone) return user.phone;
  if (user.email) return user.email.split("@")[0] || "You";
  return "You";
}

export function accountInitial(
  user: AuthContact,
  displayName?: string | null
): string {
  const name = displayName?.trim();
  if (name) return name[0]!.toUpperCase();
  if (user.email) return user.email[0]!.toUpperCase();
  if (user.phone) {
    const digits = user.phone.replace(/\D/g, "");
    return (digits.slice(-1) || "#").toUpperCase();
  }
  return "?";
}
