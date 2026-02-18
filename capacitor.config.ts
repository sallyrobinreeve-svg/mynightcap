import type { CapacitorConfig } from '@capacitor/cli';

// Set this to your deployed app URL (e.g. https://nightcap.vercel.app)
const APP_URL = process.env.CAPACITOR_APP_URL || 'https://nightcap.vercel.app';

const config: CapacitorConfig = {
  appId: 'com.nightcap.app',
  appName: 'NightCap',
  webDir: 'www',
  server: {
    url: APP_URL,
    cleartext: false,
    allowNavigation: [
      APP_URL,
      'https://wnnpbjwtmayzfcdduvhq.supabase.co',
      'https://*.supabase.co',
      'https://*.vercel.app',
    ],
  },
};

export default config;
