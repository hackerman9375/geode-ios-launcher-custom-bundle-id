#!/bin/bash
if [ ! -f "./Resources/Frameworks/libTulipHook.dylib" ]; then
    curl -L "https://nightly.link/geode-sdk/TulipHook/actions/runs/15570711673/output-ios-arm.zip" -o "output-ios-arm.zip"
    unzip -q "output-ios-arm.zip" -d .
    mkdir Resources/Frameworks
    mv libTulipHook.dylib ./Resources/Frameworks
fi
