# 🔧 Xcode Scheme Setup for API Key

## Quick Setup (Recommended Method)

To run the app, you need to configure the Google Maps API key in Xcode's scheme:

### Step 1: Open Scheme Editor
1. In Xcode, go to: **Product** → **Scheme** → **Edit Scheme...**
2. Or press: **⌘ + <** (Command + Shift + Comma)

### Step 2: Add Environment Variable
1. Select **Run** in the left sidebar
2. Go to the **Arguments** tab
3. Under **Environment Variables** section
4. Find the existing `GOOGLE_MAPS_API_KEY` variable
5. **Double-click** the value field
6. Replace `YOUR_API_KEY_HERE` with your actual API key from `Config/Secrets.xcconfig`
7. Make sure the checkbox is **checked** (enabled)
8. Click **Close**

### Step 3: Run the App
- Press **⌘ + R** to build and run
- The app should now launch successfully! 🎉

## Alternative: Use Cursor/VS Code

If you're running from Cursor/VS Code instead of Xcode:

1. Open terminal in Cursor
2. Run:
   ```bash
   source ~/.zshrc  # This loads the API key from your profile
   # Then run your app from this terminal
   ```

The API key is already added to your `~/.zshrc` file.

## Verification

When the app launches successfully, you should see:
```
✅ 🗺️ DEBUG: API key loaded from environment variable
✅ 🗺️ DEBUG: Google Maps SDK initialized successfully
```

No more crashes! 🚀




