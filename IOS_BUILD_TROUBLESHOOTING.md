# iOS Build Troubleshooting Guide

## ❌ Error: Invalid Provisioning Profile

### Problem Description:
```
Invalid Provisioning Profile. The provisioning profile included in the 
com.clickgo.provider bundle is invalid. [Missing code-signing certificate]
```

### Root Causes:
1. **Wrong Provisioning Profile Type**: Using Development profile instead of Distribution
2. **Missing Certificate**: Distribution certificate not included in the provisioning profile
3. **Expired Certificate**: The certificate has expired
4. **Bundle ID Mismatch**: Bundle ID doesn't match the provisioning profile

---

## ✅ Solutions

### Solution 1: Create/Update Distribution Provisioning Profile

#### Step 1: Go to Apple Developer Portal
1. Visit: https://developer.apple.com/account
2. Navigate to: **Certificates, Identifiers & Profiles**

#### Step 2: Check/Create Distribution Certificate
1. Go to **Certificates** → **All**
2. Look for: **iOS Distribution** certificate
3. If missing or expired:
   - Click **+** to create new
   - Select **iOS Distribution**
   - Follow the steps to generate CSR and download certificate

#### Step 3: Create App Store Distribution Provisioning Profile
1. Go to **Profiles** → **All**
2. Click **+** to create new profile
3. Select: **App Store** (under Distribution)
4. Choose App ID: `com.clickgo.provider`
5. Select your **iOS Distribution Certificate**
6. Name it: `ClickGo Provider App Store`
7. Download the profile

---

### Solution 2: Configure CodeMagic

#### Step 1: Add Certificates to CodeMagic
1. Go to CodeMagic Dashboard
2. Navigate to: **Teams** → **Integrations**
3. Click on **App Store Connect** integration
4. Add:
   - **Certificate (.p12 file)**: Your iOS Distribution certificate
   - **Certificate password**: The password you set when exporting
   - **Provisioning Profile**: The App Store profile you downloaded

#### Step 2: Update codemagic.yaml
Make sure your `codemagic.yaml` has:
```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.clickgo.provider
```

#### Step 3: Verify Integration Name
In `codemagic.yaml`, make sure the integration name matches:
```yaml
integrations:
  app_store_connect: CodeMagic  # This should match your integration name
```

---

### Solution 3: Manual Build (Local Testing)

If you want to test locally:

```bash
# 1. Clean build
flutter clean
cd ios
pod deintegrate
pod install
cd ..

# 2. Build without codesign (for testing)
flutter build ios --release --no-codesign

# 3. Build IPA (requires proper signing)
flutter build ipa --release
```

---

## 🔍 Verification Checklist

Before building for App Store:

- [ ] iOS Distribution Certificate is valid (not expired)
- [ ] App Store Distribution Provisioning Profile exists for `com.clickgo.provider`
- [ ] Provisioning Profile includes the Distribution Certificate
- [ ] Bundle ID in Xcode matches: `com.clickgo.provider`
- [ ] Certificates are added to CodeMagic Team integrations
- [ ] Integration name in `codemagic.yaml` matches CodeMagic dashboard
- [ ] `DEVELOPMENT_TEAM` in Xcode project matches your Team ID

---

## 📝 Important Notes

### Bundle ID
- Current: `com.clickgo.provider`
- Must match exactly in:
  - Xcode project
  - Apple Developer Portal
  - Provisioning Profile
  - codemagic.yaml

### Team ID
- Current in project: `S5P9PXJ4TV`
- Verify this matches your Apple Developer Team ID

### Xcode Version
- CodeMagic is using: Xcode 15.2
- Make sure your provisioning profiles are compatible

---

## 🆘 Still Having Issues?

### Check CodeMagic Build Logs:
1. Look for: "Provisioning profile" messages
2. Check: "Code signing identity" being used
3. Verify: Certificate fingerprints match

### Common Issues:
1. **Wrong integration name**: Check spelling in `codemagic.yaml`
2. **Expired certificate**: Renew in Apple Developer Portal
3. **Missing permissions**: Ensure you have Admin access to Apple Developer account
4. **Bundle ID not registered**: Register app in App Store Connect first

---

## 📞 Contact Information

For CodeMagic support:
- Documentation: https://docs.codemagic.io/
- Support: support@codemagic.io

For Apple Developer support:
- Portal: https://developer.apple.com/support/
