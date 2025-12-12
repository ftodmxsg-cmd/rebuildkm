# KM Save - Navigation App for Singapore Drivers 🚗

A smart iOS navigation app that helps drivers in Singapore save money on fuel, parking, and tolls while providing live navigation with safety features.

## 🎯 Features

- **Live Navigation** - Real-time turn-by-turn directions powered by Google Maps
- **Cost Optimization** - Calculate and compare routes based on fuel, toll, and parking costs
- **Safety Features** - Red-light camera alerts and traffic light countdowns
- **Spending Tracker** - Track daily, monthly, and yearly driving expenses
- **AI Route Recommendations** - Smart route suggestions based on time and cost savings

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 15.0 or later
- CocoaPods
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/rebuildkm.git
   cd rebuildkm
   ```

2. **Install dependencies**
   ```bash
   pod install
   ```

3. **Set up API key**
   ```bash
   cp Secrets.example.xcconfig Secrets.xcconfig
   ```
   
   Edit `Secrets.xcconfig` and add your Google Maps API key:
   ```
   GOOGLE_MAPS_API_KEY = YOUR_API_KEY_HERE
   ```

4. **Open the workspace**
   ```bash
   open kmsave.xcworkspace
   ```
   
   ⚠️ **Important:** Always use `kmsave.xcworkspace`, NOT `kmsave.xcodeproj`

5. **Build and run**
   - Select a simulator or device
   - Press `⌘ + R`

## 🔑 API Key Setup

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/credentials)
2. Enable these APIs:
   - Maps SDK for iOS
   - Directions API
   - Places API
3. Add restrictions:
   - **Application restriction:** iOS apps with bundle ID `Open.kmsave`
   - **API restrictions:** Only enable the APIs listed above

## 🔒 Security

- ✅ API keys are stored in `Secrets.xcconfig` (excluded from git)
- ✅ All sensitive files are in `.gitignore`
- ✅ Only template files are committed to the repository

**Never commit files containing real API keys!**

## 📱 Tech Stack

- **Language:** Swift 5.0
- **Framework:** SwiftUI
- **Maps:** Google Maps SDK 9.4.0
- **Dependency Manager:** CocoaPods
- **Platform:** iOS 15.0+

## 📂 Project Structure

```
rebuildkm/
├── kmsave/                      # Main app source code
│   ├── kmsaveApp.swift         # App entry point
│   ├── ContentView.swift       # Home screen
│   ├── Views/                  # UI views
│   │   └── MapView.swift       # Google Maps integration
│   ├── Info.plist             # App configuration
│   └── Assets.xcassets/       # Images and colors
├── kmsave.xcworkspace/         # Workspace (use this!)
├── Podfile                     # Dependencies
└── Secrets.example.xcconfig    # API key template
```

## 🛠️ Development

### Current Status

✅ **Completed:**
- Xcode project setup
- Google Maps SDK integration
- Basic map view with Singapore location
- Location permissions configuration
- Security setup with .gitignore

🚧 **In Progress:**
- Navigation routing
- Cost calculation features
- UI screens (Trip Planner, Spending Tracker, Settings)
- Safety features (camera alerts, traffic lights)

### Contributing

This is a personal project. Feel free to fork and customize for your own use!

## 📄 License

[Add your license here]

## 👤 Author

[Your name/username]

## 🙏 Acknowledgments

- Google Maps Platform
- Singapore driver community
- Open source contributors

---

**Built with ❤️ for Singapore drivers**

