#!/bin/bash
# This script updates Kotlin version in the Android build files after prebuild
sed -i 's/ext.kotlin_version = .*/ext.kotlin_version = "1.9.25"/' android/build.gradle
