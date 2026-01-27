## ClearDish — App Store (iOS) publishing checklist (short)

### 0) Important constraint
- iOS builds/archives **require macOS + Xcode**. Windows can’t produce an App Store uploadable build.

### 0.1) No Mac? Yes, still possible
- Use a macOS CI: **Codemagic** (recommended), Bitrise, GitHub Actions (macOS runners), etc.
- This repo includes a ready workflow: `codemagic.yaml` → `ios_testflight`.

### 1) iOS project config (already in repo)
- **Bundle ID**: `com.hitratech.cleardish`
- **Deep link scheme**: `cleardish://` (used by `return_url=cleardish://payment-complete`)
- **Info.plist permissions**: location, camera, photo library (strings added)

### 2) App Store Connect: create the app
- Go to **App Store Connect → Apps → New App**
- Platform: **iOS**
- Name: **ClearDish**
- Primary language: English (UK)
- Bundle ID: **`com.hitratech.cleardish`**
- SKU: `cleardish-ios` (any unique string)

### 3) In‑App Purchases (B2C Premium)
Create **Auto‑Renewable Subscriptions**:
- **Subscription group**: “ClearDish Premium”
- **Monthly**
  - Product ID: `cleardish_user_monthly`
  - Price: £4.99/month
- **Yearly**
  - Product ID: `cleardish_user_yearly`
  - Price: £49.99/year

Notes:
- Product IDs must match the IDs used in the app (`SubscriptionScreen`).
- Add localization + screenshots if requested for IAP review.

### 4) Xcode signing & capabilities (on Mac)
- Open `ios/Runner.xcworkspace` in Xcode
- **Signing & Capabilities**
  - Select your **Team**
  - Ensure **Bundle Identifier** = `com.hitratech.cleardish`
  - Add capability: **In‑App Purchase** (recommended)

### 5) Build & upload to TestFlight (on Mac)
Option A (Xcode):
- Product → Archive → Distribute App → App Store Connect → Upload

Option B (Flutter CLI):
- `flutter pub get`
- `flutter build ipa --release`
- Upload with Xcode Organizer or Apple Transporter

Option C (No Mac, via Codemagic):
- Create a Codemagic app from your Git repo
- Add the following secrets in Codemagic UI (Environment variables / Secrets):
  - `APP_STORE_CONNECT_KEY_IDENTIFIER`
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_PRIVATE_KEY` (paste the full `.p8` content)
- Run workflow: **`ios_testflight`** (uses `codemagic.yaml`)

### 6) TestFlight
- App Store Connect → TestFlight → add **internal testers**
- Create **sandbox testers** for IAP testing (Users and Access → Sandbox)
- Install via TestFlight and verify:
  - products load (monthly/yearly show real App Store prices)
  - purchase → app calls `iap-verify` and activates the plan
  - restore purchases works

### 7) App privacy & review fields (minimum)
In App Store Connect you must fill:
- **Privacy Policy URL**: `https://cleardish.co.uk/privacy-policy/`
- **Terms URL** (optional but recommended): `https://cleardish.co.uk/terms-and-conditions/`
- **App Privacy**: declare data collected/linked (email/auth, profile, optional location/photos if used)
- **Export compliance**: usually “No” if you don’t ship custom encryption beyond Apple’s standard TLS

### 8) Owner payments (B2B) note (policy risk)
Restaurant owner billing is handled via website (Stripe). Apple can be strict about external payment links for digital services.
If review friction happens, the simplest mitigation is:
- hide/remove external billing links in the iOS build, or
- keep iOS consumer‑only and handle owner flows on web.
