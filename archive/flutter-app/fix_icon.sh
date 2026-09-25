#!/bin/bash

echo "🔧 Fixing App Icon..."
echo ""

# Step 1: Clean
echo "1️⃣ Cleaning build artifacts..."
flutter clean

# Step 2: Get dependencies
echo ""
echo "2️⃣ Getting dependencies..."
flutter pub get

# Step 3: Regenerate icons
echo ""
echo "3️⃣ Regenerating launcher icons..."
dart run flutter_launcher_icons

# Step 4: Build
echo ""
echo "4️⃣ Building app..."
flutter build apk --release

echo ""
echo "✅ Done! Now:"
echo "   1. Uninstall the app from your phone"
echo "   2. Install the new APK from: build/app/outputs/flutter-apk/app-release.apk"
echo "   3. Or run: flutter run --release"
echo ""
echo "📱 The app icon and notification icon should now be updated!"
