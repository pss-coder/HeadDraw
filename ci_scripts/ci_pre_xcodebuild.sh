#!/bin/sh

# Check if the Metal toolchain is already visible to the system
if xcodebuild -showComponent metalToolchain >/dev/null 2>&1; then
    echo "✅ Metal toolchain is already installed."
else
    echo "❌ Metal toolchain missing. Starting isolated installation..."
    
    # 1. Download and isolate the toolchain asset to a temporary bundle
    xcodebuild -downloadComponent metalToolchain -exportPath /tmp/metalToolchainDownload/
    
    # 2. Force-register the exported bundle to the Xcode environment
    echo "🧰 Importing metal toolchain into Xcode Cloud environment..."
    xcodebuild -importComponent metalToolchain -importPath /tmp/metalToolchainDownload/*.exportedBundle
    
    echo "🚀 Metal toolchain registration complete."
fi
