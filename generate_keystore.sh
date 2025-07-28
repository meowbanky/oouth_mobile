#!/bin/bash

# Generate keystore for OOUTH Mobile App
echo "Generating keystore for OOUTH Mobile App..."

# Create android directory if it doesn't exist
mkdir -p android

# Generate keystore
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass oouth2024 -keypass oouth2024 -dname "CN=OOUTH Mobile, OU=IT Department, O=OOUTH, L=Ibadan, S=Oyo, C=NG"

# Create key.properties file
cat > android/key.properties << EOF
storePassword=oouth2024
keyPassword=oouth2024
keyAlias=upload
storeFile=upload-keystore.jks
EOF

echo "Keystore generated successfully!"
echo "Keystore location: android/upload-keystore.jks"
echo "Key properties file: android/key.properties"
echo ""
echo "IMPORTANT: Keep these files secure and backup the keystore file!"
echo "You'll need this keystore to update your app on the Play Store." 