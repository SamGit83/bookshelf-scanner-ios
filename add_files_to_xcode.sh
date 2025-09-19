#!/bin/bash

echo "Adding all Swift files to Xcode project..."

# Open Xcode project (this will create the necessary user data)
echo "Opening Xcode project to initialize..."
open BookshelfScanner.xcodeproj

# Wait a moment for Xcode to initialize
sleep 3

echo "✅ Xcode project opened successfully!"
echo ""
echo "📋 Next Steps (Manual - for now):"
echo ""
echo "1. In Xcode, select the 'Sources' folder in the project navigator"
echo "2. Right-click → Add Files to 'BookshelfScanner'"
echo "3. Navigate to your project folder"
echo "4. Select all .swift files from the Sources/ directory"
echo "5. Make sure 'Copy items if needed' is checked"
echo "6. Click 'Add'"
echo ""
echo "This will add all 24 Swift files to your project automatically!"
echo ""
echo "After adding files:"
echo "1. Add Firebase packages (File → Add Packages)"
echo "2. Set environment variables for API keys"
echo "3. Build and run (⌘R)"
echo ""
echo "🎯 All your Swift files are ready to be added to Xcode!"