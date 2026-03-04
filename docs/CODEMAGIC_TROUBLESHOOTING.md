# Codemagic Build Troubleshooting

## If the build fails, we need the exact error

1. Open the failed build in Codemagic
2. Click **Build logs**
3. Find the **first step that failed** (red/failed status)
4. Scroll to the **bottom of that step's log**
5. Copy the **last 30–50 lines** (the error message)
6. Share it so we can fix the specific issue

---

## Common errors and fixes

### "No matching profiles found"
- Upload the provisioning profile to Codemagic (Team settings → Code signing identities → iOS provisioning profiles)
- Ensure the profile is for `com.nightcap.app` and App Store distribution

### "Scheme not found" or "workspace not found"
- The config now uses `ios/App/App.xcworkspace` from project root
- Check the "Verify iOS project structure" step in the logs – does `App.xcworkspace` exist?

### "pod install" fails
- Capacitor 8 uses SPM by default; we force CocoaPods with `--packagemanager CocoaPods`
- If it still fails, check the CocoaPods step output

### Build hangs or times out
- Increased `max_build_duration` to 120 minutes
- Check Codemagic status: https://status.codemagic.io

---

## Current config summary

- **Capacitor**: Uses `--packagemanager CocoaPods` (required for Codemagic compatibility)
- **Workspace**: `ios/App/App.xcworkspace` (full path from project root)
- **Scheme**: `App`
- **Bundle ID**: `com.nightcap.app`
