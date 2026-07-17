// HEAL — app version manifest endpoint.
// Returns the minimum + latest app version + store URLs.
// The mobile app polls this on launch to decide whether to show
// a force-update dialog. Bump the numbers whenever you ship.

import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

const MANIFEST = {
  // The user CANNOT use the app below this version.
  // Bump this when shipping a security fix or a backend migration
  // that breaks old clients.
  min_version: '0.1.7',

  // What's currently available in the stores. Used for the optional
  // "there's a new version" banner (not blocking).
  latest_version: '0.1.8',

  // App Store / Play Store URLs. Once we have them, fill these in.
  // Until then the mobile client falls back to the search URL.
  store_url_ios: 'https://apps.apple.com/app/id6751891860',
  store_url_android: 'https://play.google.com/store/apps/details?id=com.pclub.heal',

  // One-line release notes shown in the force-update dialog.
  release_notes: 'Smaller fixes and a smoother start to your day.',
};

export async function GET() {
  return NextResponse.json(MANIFEST, {
    headers: {
      // No need to cache — this is queried once per app launch.
      'Cache-Control': 'no-store',
    },
  });
}
