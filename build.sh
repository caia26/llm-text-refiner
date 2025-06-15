#!/bin/bash

# Build script for LLM Text Refiner
# Usage: ./build.sh [clean|build|run]

PROJECT_NAME="LLMTextRefiner"
SCHEME_NAME="LLMTextRefiner"

case "$1" in
    "clean")
        echo "Cleaning project..."
        xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}"
        ;;
    "build")
        echo "Building project..."
        xcodebuild build -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" -configuration Debug
        ;;
    "run")
        echo "Building and running project..."
        xcodebuild build -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" -configuration Debug
        if [ $? -eq 0 ]; then
            echo "Opening application..."
            open "build/Debug/${PROJECT_NAME}.app"
        fi
        ;;
    *)
        echo "Usage: $0 [clean|build|run]"
        echo "  clean - Clean the project"
        echo "  build - Build the project"
        echo "  run   - Build and run the project"
        ;;
esac 