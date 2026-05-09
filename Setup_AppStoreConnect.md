# NoJetLag — App Store Connect Setup

> Step-by-step: pick a Bundle ID, register the App ID, create the App Store Connect entry, get **two different .p8 keys** (one for APNs, one for App Store Connect API). Replace the placeholder `asd.NoJetLag` everywhere.

---

## 0. Decide the Bundle ID first

The current `asd.NoJetLag` is a throwaway. Apple needs a real reverse-domain. Two safe options:

| Bundle ID                    | When to use                                  |
| ---------------------------- | -------------------------------------------- |
| `dev.actvox.nojetlag`        | If you control `actvox.dev` (you do)         |
| `com.boytik.nojetlag`        | Personal namespace, no domain ownership      |

**Recommendation:** `dev.actvox.nojetlag`. You already use `boytik@actvox.dev`, the domain matches.

Pick one and write it down — you'll type it the same way in three places (Apple Developer, App Store Connect, Xcode).

---

## 1. Register the App ID in Apple Developer Portal

Goes here first because App Store Connect needs the ID to already exist.

1. Open **https://developer.apple.com/account/resources/identifiers/list**
2. Top right → **+** (or "Identifiers" → blue plus)
3. Select **App IDs** → Continue
4. Type: **App** → Continue
5. Fill:
    - **Description:** `NoJetLag iOS`
    - **Bundle ID:** **Explicit** → `dev.actvox.nojetlag` (your chosen string)
6. **Capabilities — tick ON:**
    - **Push Notifications**
    - **In-App Purchase** *(needed for Adapty subscriptions later)*
7. Continue → Register

The App ID is now permanent. You'll see it in the Identifiers list.

---

## 2. Create the App in App Store Connect

You're already on this page. Empty list with **"Apps hinzufügen"** button.

1. Click **Apps hinzufügen** (the screenshot shows it)
2. **Plattformen** → tick **iOS** only
3. **Name:** `NoJetLag` *(must be unique on the entire App Store — if taken, fall back to `NoJetLag · Land sharp` or `NoJetLag Pilot`)*
4. **Primäre Sprache:** **English (U.S.)** *(other locales added later)*
5. **Bundle-ID:** dropdown → select **`NoJetLag iOS — dev.actvox.nojetlag`** (the one you just registered in step 1)
6. **SKU:** `NOJETLAG-IOS-001` *(internal — never shown to users; just keep it consistent)*
7. **Benutzerzugriff:** **Voller Zugriff** *(only you for now)*
8. **Erstellen**

The app card appears in the list. Inside it you'll see:
- App-Information (later: name, subtitle, description from `NoJetLag_AppStore_Release.md`)
- Preise und Verfügbarkeit
- App-Datenschutz
- Distribution
- TestFlight tab

---

## 3. Get the **APNs Key** (.p8) — for sending push notifications

> This is the key your **backend** (or Adapty's messaging feature) uses to send remote push notifications to NoJetLag users. **Different** from the App Store Connect API key — don't mix them up.

1. Open **https://developer.apple.com/account/resources/authkeys/list**
2. Top right → **+**
3. Fill:
    - **Key Name:** `NoJetLag APNs`
    - **Tick ON:** **Apple Push Notifications service (APNs)**
    - *(Click "Configure" next to it → tick "Sandbox & Production" if asked)*
4. Continue → Register
5. **Download** the `.p8` file. **It can be downloaded ONLY ONCE.** Save it immediately to a password manager or a backed-up secure location.
6. From the post-creation screen, copy and save:
    - **Key ID** — 10 characters, e.g. `ABC1234567`
    - **Team ID** — top-right corner of the dev portal under your name, 10 characters
    - The `.p8` file path

You now have three pieces — Key ID, Team ID, the file. All three are needed together. None of them alone is useful.

---

## 4. Get the **App Store Connect API Key** (.p8) — for Adapty

> Different .p8. Different portal. Different purpose. This one lets Adapty (and your backend, if you have one) talk to App Store Connect — read subscription state, validate receipts, listen for App Store Server Notifications V2.

1. Inside **App Store Connect** (where you are now), click **Benutzer und Zugriffsrechte** (top nav)
2. Sub-tab → **Integrationen** → **App Store Connect API**
3. Section **In-App Purchase Schlüssel** (preferred) OR **Team-Schlüssel** (broader access)
    - If you see "In-App Purchase Schlüssel" — use that. It's narrower scope, safer.
    - Otherwise go to **Team-Schlüssel** and pick role **App Manager**.
4. Click the **+** to generate a new key
5. Fill:
    - **Name:** `Adapty Integration`
    - **Access / Role:** **In-App Purchase** *(if you used the in-app purchase tab)* or **App Manager** *(team-keys tab)*
6. **Generate**
7. **Download API Key** → save the `.p8` file. **Only one download chance.**
8. Copy and save:
    - **Key ID** — 10 characters
    - **Issuer ID** — UUID at the top of the keys page, applies to all your team's keys

---

## 5. Wire keys into Adapty

Now you have both .p8 files. Open Adapty Dashboard → your project → **App Settings** (or "Apps" if that's the label).

### 5.1 App Store Connect API key (the one from step 4)

In Adapty:
- Section **App Store Connect API**
- Upload the `.p8` file
- Paste **Key ID** + **Issuer ID**
- Save

This unlocks: receipt validation, server-side subscription state, App Store Server Notifications V2.

### 5.2 APNs key (the one from step 3) *— optional, only if you want Adapty to send push*

Adapty has a messaging feature that can send pushes for subscription events (renewal failed, trial ending, etc).

- Section **Apple Push Notifications** (or "Messaging" → "iOS push")
- Upload the APNs `.p8`
- Paste **Key ID** + **Team ID** + your **Bundle ID** (`dev.actvox.nojetlag`)
- Save

If you don't want Adapty to push for you, skip 5.2 and keep the APNs `.p8` for your own backend later.

---

## 6. Update Xcode to match

Open `NoJetLag.xcodeproj` → target **NoJetLag** → **Signing & Capabilities** tab.

1. **Bundle Identifier:** change `asd.NoJetLag` → `dev.actvox.nojetlag` (or whatever you chose).
2. **Team:** select your real Apple Developer team (top right of the same panel).
3. Click **+ Capability**:
    - Add **Push Notifications**
    - Add **Background Modes** → tick **Remote notifications** *(only if you'll handle silent push later)*
4. Update the static constant in code if needed:

   ```swift
   // NoJetLagApp.swift — already exists, just change the placement ID if different
   static let adaptyOnboardingPlacementId = "Important"
   ```

5. Update the line in `NoJetLag_AppStoreConnect.md` and any privacy/support pages where the bundle ID appears.

---

## 7. Verify before TestFlight

Quick sanity list before you push the first build:

- [ ] Bundle ID identical in three places: Apple Developer Portal, App Store Connect app entry, Xcode project Signing tab.
- [ ] Both `.p8` files backed up in a password manager (1Password, Bitwarden, etc) along with their Key IDs.
- [ ] Team ID and Issuer ID written down somewhere you can find them.
- [ ] Push Notifications capability ticked in Xcode.
- [ ] Adapty Dashboard → App Settings shows green check next to "App Store Connect API key configured."
- [ ] Adapty placement `Important` is **Live**, not Draft.

After this, archive a build in Xcode → Distribute → App Store Connect → wait for processing → invite yourself to TestFlight.

---

## 8. Common mistakes to avoid

1. **Mixing the two .p8 files.** APNs key is for *sending* pushes. App Store Connect API key is for *reading* subscription state. They live on different portals (`developer.apple.com` vs `appstoreconnect.apple.com`), have different Key IDs, and Adapty wants both in different upload slots.
2. **Losing the .p8.** Apple lets you download each `.p8` exactly once. If you close the tab without saving, you have to revoke the key and create a new one.
3. **Trying `asd.NoJetLag` as Bundle ID.** App Store Connect rejects non-reverse-domain IDs and any ID with a hyphen in the wrong place.
4. **Choosing a name that's already on the App Store.** Apple checks at creation time. Have a backup name ready (`NoJetLag · Pilot`, `NoJetLag — Land sharp`).
5. **Forgetting In-App Purchase capability.** If you ship with a paywall but didn't tick this, products won't appear in StoreKit and Adapty will return empty paywalls.

---

## 9. What you have at the end

| Asset                       | Where it lives                          | What it's for                           |
| --------------------------- | --------------------------------------- | --------------------------------------- |
| Bundle ID                   | All three portals + Xcode               | Identifies the app uniquely             |
| Team ID                     | Apple Developer top-right               | Used with APNs key                      |
| Issuer ID                   | App Store Connect → API Keys page       | Used with App Store Connect API key     |
| `NoJetLag_APNs.p8`          | Your password manager                   | Sending push notifications              |
| APNs Key ID                 | Your password manager                   | Pairs with the APNs `.p8`               |
| `Adapty_Integration.p8`     | Your password manager + Adapty dashboard| Reading subscription state via Adapty   |
| App Store Connect API Key ID| Your password manager                   | Pairs with that `.p8`                   |

When you message me back with "p8 готов и Bundle обновлён", I'll wire push handling into the app — register for remote notifications, store the device token, send it to your backend or Adapty, and add an opt-in toggle in Settings.
