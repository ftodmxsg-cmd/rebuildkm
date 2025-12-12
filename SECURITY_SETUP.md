# 🔒 Security Setup Guide

## ⚠️ IMPORTANT: API Key Security

This project uses Google Maps API which requires an API key. **Never commit API keys to version control!**

## 🚨 If Your API Key Was Exposed

If GitHub alerted you about an exposed API key:

1. **Immediately revoke the compromised key**
   - Go to: https://console.cloud.google.com/google/maps-apis/credentials
   - Delete or regenerate the exposed key

2. **Create a new API key**
   - Generate a new key in Google Cloud Console
   - Add restrictions (see below)

3. **Clean git history** (if key was committed)
   ```bash
   # Remove sensitive data from git history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch Config/Secrets.xcconfig Secrets.xcconfig" \
     --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

## 🔧 Setup Instructions

### Step 1: Get Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/credentials)
2. Create a new API key or use an existing one
3. **Add restrictions** (IMPORTANT for security):
   - **Application restrictions:**
     - Select "iOS apps"
     - Add bundle ID: `Open.kmsave`
   - **API restrictions:**
     - Select "Restrict key"
     - Enable: Maps SDK for iOS, Directions API, Places API

### Step 2: Configure the API Key

You have **two options** (choose one):

#### Option A: Environment Variable (Recommended for Development)

```bash
# Add to your ~/.zshrc or ~/.bash_profile
export GOOGLE_MAPS_API_KEY="your-api-key-here"

# Reload your shell
source ~/.zshrc
```

Then run the app from terminal or configure in Xcode scheme:
- Xcode → Product → Scheme → Edit Scheme
- Run → Arguments → Environment Variables
- Add: `GOOGLE_MAPS_API_KEY` = `your-key-here`

#### Option B: Secrets.xcconfig File

1. Copy the template:
   ```bash
   cp Config/Secrets.xcconfig.template Config/Secrets.xcconfig
   # OR
   cp Secrets.example.xcconfig Secrets.xcconfig
   ```

2. Edit `Secrets.xcconfig` and replace `YOUR_API_KEY_HERE` with your actual key:
   ```
   GOOGLE_MAPS_API_KEY = AIzaSy...your-actual-key
   ```

3. **Verify it's in .gitignore:**
   ```bash
   git check-ignore Secrets.xcconfig Config/Secrets.xcconfig
   # Should output the file paths (meaning they're ignored)
   ```

### Step 3: Verify Setup

Run the app and check the console logs:
- ✅ `🗺️ DEBUG: API key loaded from environment variable` - Using env var
- ✅ `🗺️ DEBUG: API key loaded from Info.plist` - Using Secrets.xcconfig
- ❌ `❌ ERROR: No Google Maps API key found!` - Not configured

## 📋 Security Checklist

- [ ] API key has application restrictions (iOS bundle ID)
- [ ] API key has API restrictions (specific APIs only)
- [ ] `Secrets.xcconfig` is in `.gitignore`
- [ ] No API keys are hardcoded in source files
- [ ] Old/exposed keys have been revoked
- [ ] New API key is working in the app

## 🔐 Best Practices

1. **Never commit** `Secrets.xcconfig` or any file with real API keys
2. **Always use** `.gitignore` to exclude sensitive files
3. **Use environment variables** for local development
4. **Rotate keys** periodically
5. **Monitor usage** in Google Cloud Console
6. **Set up billing alerts** to detect unauthorized usage

## 🆘 Troubleshooting

### App shows: "No Google Maps API key found"
- Check if `GOOGLE_MAPS_API_KEY` environment variable is set
- Verify `Secrets.xcconfig` exists and has the correct key
- Make sure Xcode scheme has the environment variable configured

### Map doesn't load
- Check API key restrictions in Google Cloud Console
- Verify the bundle ID matches: `Open.kmsave`
- Check console logs for specific error messages

### "API key not valid" error
- Ensure APIs are enabled: Maps SDK for iOS, Directions API
- Check API key restrictions aren't too strict
- Verify billing is enabled in Google Cloud Console

## 📚 Additional Resources

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [iOS Maps SDK Setup](https://developers.google.com/maps/documentation/ios-sdk/start)




