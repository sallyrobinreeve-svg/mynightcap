import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        nightcap: {
          DEFAULT: "#000000",
          card: "#0a0a0a",
          muted: "#9a9a9a",
          accent: "#ff2e9a",
          orange: "#ff8a3c",
          pink: "#ff2e9a",
          blue: "#4ecdc4",
          yellow: "#ffd93d",
          glow: "rgba(255, 46, 154, 0.55)",
        },
      },
      fontFamily: {
        display: ["var(--font-body)", "system-ui", "sans-serif"],
        body: ["var(--font-body)", "system-ui", "sans-serif"],
        script: ["var(--font-script)", "cursive"],
      },
    },
  },
  plugins: [],
};

export default config;
