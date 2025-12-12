# Map Display Troubleshooting Guide

## Issue: Map not visible in the app

### Quick Diagnosis Steps

#### 1. **Open Xcode and Run the App**
```bash
open /Users/user/rebuildkm/kmsave.xcworkspace
```

Then press **⌘ + R** to run the app.

#### 2. **Check Console Logs**

In Xcode, open the **Console** (⌘ + Shift + C) and look for these messages:

**✅ Good Signs:**
```
✅ SUCCESS: API key loaded from Info.plist
🔑 API Key (first 10 chars): AIzaSyDMOi...
🗺️ DEBUG: Creating GMSMapView
🗺️ DEBUG: Camera location - lat: 1.284, lon: 103.8607
🗺️ DEBUG: GMSMapView created successfully
🗺️ DEBUG: Map marked as ready
🗺️ DEBUG: MapView appeared with size: (393.0, 852.0)
```

**❌ Bad Signs:**
```
❌ ERROR: No Google Maps API key found!
```

#### 3. **What You Should See**

When the app launches, you should see:
- **Loading indicator** with text "Loading Map..." and view dimensions
- After 0.5 seconds, the **map should appear** showing Singapore
- A **marker** at Marina Bay Sands
- Your **current location** (blue dot) if location permission is granted

---

## Common Issues & Solutions

### Issue 1: "Loading Map..." Never Disappears

**Cause:** Map tiles not loading or API key issue

**Solution:**
1. Check console for API key errors
2. Verify API key in `Secrets.xcconfig`:
   ```bash
   cat /Users/user/rebuildkm/Secrets.xcconfig
   ```
3. Ensure Maps SDK for iOS is enabled in Google Cloud Console
4. Check API key restrictions (should allow iOS apps)

### Issue 2: Gray/Blank Screen

**Cause:** API key not configured or invalid

**Solution:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services > Credentials**
3. Find your API key
4. Click **Edit**
5. Under **API restrictions**, ensure **Maps SDK for iOS** is enabled
6. Under **Application restrictions**, add your bundle ID: `com.yourcompany.kmsave`

### Issue 3: Map Shows But No Location

**Cause:** Location permissions not granted

**Solution:**
1. In simulator, go to **Features > Location > Custom Location**
2. Enter: Latitude `1.2840`, Longitude `103.8607` (Singapore)
3. Or use **Features > Location > Apple** for a default location
4. Grant location permission when prompted

### Issue 4: Console Shows "API key loaded" But No Map

**Cause:** Maps SDK API not enabled in Google Cloud

**Solution:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services > Library**
3. Search for "Maps SDK for iOS"
4. Click **Enable**
5. Rebuild and run the app

---

## Manual Testing Steps

### Step 1: Clean Build
```bash
cd /Users/user/rebuildkm
xcodebuild -workspace kmsave.xcworkspace -scheme kmsave clean
```

### Step 2: Rebuild
```bash
xcodebuild -workspace kmsave.xcworkspace \
  -scheme kmsave \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BFBCEAA0-DA08-4F11-AFE9-3D7DFD498016' \
  build
```

### Step 3: Run in Xcode
```bash
open /Users/user/rebuildkm/kmsave.xcworkspace
```

Press **⌘ + R** and watch the console.

---

## Debug Information to Collect

If the map still doesn't appear, collect this information:

### 1. Console Logs
Copy all lines containing:
- `DEBUG`
- `ERROR`
- `Maps`
- `API`
- `SUCCESS`

### 2. View Hierarchy
In Xcode, while app is running:
- Click **Debug > View Debugging > Capture View Hierarchy**
- Look for `GMSMapView` in the hierarchy
- Check if it has a non-zero frame size

### 3. API Key Status
```bash
# Check if API key is in Secrets.xcconfig
grep GOOGLE_MAPS_API_KEY /Users/user/rebuildkm/Secrets.xcconfig

# Check if Info.plist references it
grep GoogleMapsAPIKey /Users/user/rebuildkm/kmsave/Info.plist
```

---

## Expected Console Output (Successful Launch)

```
🗺️ DEBUG: Configuring Google Maps SDK...
✅ SUCCESS: API key loaded from Info.plist
🔑 API Key (first 10 chars): AIzaSyDMOi...
📍 DEBUG: Requesting location permission
📍 DEBUG: Authorization status changed - When In Use
📍 DEBUG: Starting location updates
🗺️ DEBUG: MapView appeared with size: (393.0, 852.0)
🗺️ DEBUG: Creating GMSMapView
🗺️ DEBUG: Camera location - lat: 1.284, lon: 103.8607
🗺️ DEBUG: GMSMapView created successfully
🗺️ DEBUG: Map marked as ready
🗺️ DEBUG: updateUIView called
🗺️ DEBUG: Adding default marker at Singapore
📍 DEBUG: Location update received
```

---

## Still Not Working?

### Nuclear Option: Complete Reset

```bash
cd /Users/user/rebuildkm

# 1. Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/kmsave-*
xcodebuild -workspace kmsave.xcworkspace -scheme kmsave clean

# 2. Reinstall pods
pod deintegrate
pod install

# 3. Rebuild
xcodebuild -workspace kmsave.xcworkspace \
  -scheme kmsave \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BFBCEAA0-DA08-4F11-AFE9-3D7DFD498016' \
  build

# 4. Open and run
open kmsave.xcworkspace
```

---

## Contact Information

If you're still experiencing issues, provide:
1. Full console logs from app launch
2. Screenshot of the app
3. Output of: `cat /Users/user/rebuildkm/Secrets.xcconfig`
4. Google Cloud Console screenshot showing enabled APIs

---

## Quick Checklist

- [ ] API key exists in `Secrets.xcconfig`
- [ ] Maps SDK for iOS enabled in Google Cloud Console
- [ ] API key has no restrictions OR allows iOS apps
- [ ] Bundle ID matches in API key restrictions
- [ ] App builds without errors
- [ ] Console shows "✅ SUCCESS: API key loaded"
- [ ] Console shows "🗺️ DEBUG: GMSMapView created successfully"
- [ ] Location permission granted in simulator
- [ ] View size is non-zero (e.g., 393x852)

