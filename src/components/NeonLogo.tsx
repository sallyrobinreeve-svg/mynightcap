import Link from "next/link";

export function NeonLogo({
  href = "/",
  className = "text-4xl",
}: {
  href?: string | null;
  className?: string;
}) {
  const mark = (
    <span className={`font-script leading-none ${className}`} aria-label="NightCapt">
      <span className="neon-text-pink text-nightcap-accent">Night</span>
      <span className="neon-text-orange text-nightcap-orange">Capt</span>
    </span>
  );

  if (!href) return mark;
  return (
    <Link href={href} className="inline-block">
      {mark}
    </Link>
  );
}
