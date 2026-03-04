import type { CapacitorConfig } from '@capacitor/cli';

// Your live Vercel deployment URL
const APP_URL = process.env.CAPACITOR_APP_URL || 'https://mynightcap.vercel.app';

const config: CapacitorConfig = {
  appId: 'com.mynightcap.app',
  appName: 'NightCapt',
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
