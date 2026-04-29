# ViralForge Subscription Sandbox Test Plan

This plan covers the China-first Pro subscription setup for local StoreKit, TestFlight sandbox, and backend notification validation.

## Products

| Plan | Product ID | Target China price |
| --- | --- | --- |
| Monthly | `viralforge_pro_monthly` | `CNY 39.8/month` |
| Yearly | `viralforge_pro_yearly` | `CNY 398/year` |

## Automated Local Backend Check

Run this before any TestFlight subscription pass:

```sh
npm --prefix backend run smoke:subscriptions
```

Expected coverage:

- `/api/app-store/status` reports `local_development`.
- A new user starts as non-Pro.
- `viralforge_pro_monthly` activates Pro in local development mode.
- Unsupported product IDs are rejected.
- Signed local yearly transactions are decoded and cross-checked.
- App Store Server Notification V2 payloads can expire and renew the same subscription record.

## Local StoreKit Simulator Pass

### Automated Product-Loading Check

The regular UI suite verifies that the paywall can load and render the local StoreKit products:

```sh
xcodebuild -project ViralForge.xcodeproj \
  -scheme ViralForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ViralForgeUITests/CreationFlowUITests/testPaywallShowsChinaSubscriptionPlans \
  test
```

Expected coverage:

- `ViralForge.storekit` products are visible through StoreKit product loading.
- Monthly and yearly plan IDs are present.
- China-first local prices render in the paywall.
- Purchase and restore controls are visible.

### Automated Purchase Diagnostic

There is a gated StoreKitTest diagnostic for local purchase activation:

```sh
touch /tmp/viralforge-run-storekit-purchase-tests
VF_RUN_STOREKIT_PURCHASE_TESTS=1 xcodebuild -project ViralForge.xcodeproj \
  -scheme ViralForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ViralForgeUITests/CreationFlowUITests/testLocalStoreKitPurchaseActivatesPro \
  test
rm -f /tmp/viralforge-run-storekit-purchase-tests
```

If the runner reports `notEntitled`, the command-line UI test process cannot perform off-device StoreKitTest purchases in the current Xcode environment. In that case, use the Xcode GUI pass below; do not treat the product-loading test alone as a completed purchase pass.

### Xcode GUI Purchase Pass

1. Open `ViralForge.xcodeproj` in Xcode.
2. Confirm the run scheme uses `ViralForge.storekit`.
3. Launch the app on an iPhone simulator with Simplified Chinese locale.
4. Open the `会员` tab.
5. Confirm both plans are visible:
   - `viralforge_pro_monthly`, `¥39.8/月`
   - `viralforge_pro_yearly`, `¥398/年`
6. Buy monthly, then verify:
   - App shows Pro active state.
   - Quota card switches to Pro/unlimited behavior.
   - Backend mode, if enabled, syncs through `/api/subscription/sync`.
7. Use `恢复购买` after relaunch and verify Pro state returns.
8. In Xcode StoreKit Transaction Manager, test renewal, cancellation, expiration, and revocation. Relaunch or restore after each state change and verify the app reflects the expected Pro state.

## TestFlight Sandbox Pass

Prerequisites:

- App Store Connect agreements, tax, and banking are complete.
- Subscription metadata and review screenshots are attached.
- China storefront prices are manually confirmed.
- A public HTTPS backend is deployed.
- Release build has `BACKEND_BASE_URL` set to that HTTPS backend.

Backend environment:

```env
IAP_VERIFICATION_MODE=app_store_server
APP_STORE_SERVER_ENVIRONMENT=sandbox
APP_STORE_SERVER_ISSUER_ID=...
APP_STORE_SERVER_KEY_ID=...
APP_STORE_SERVER_BUNDLE_ID=com.phil.viralforge
APP_STORE_SERVER_PRIVATE_KEY_PATH=/secure/path/AuthKey_XXXXXXXXXX.p8
```

App Store Server Notifications V2 URL:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

Sandbox cases:

- New sandbox Apple ID can purchase monthly.
- New sandbox Apple ID can purchase yearly.
- Restore purchase works after reinstall.
- Auto-renewal keeps Pro active.
- Cancellation or expiration removes Pro after Apple sends the final inactive transaction state.
- Refund/revoke, if available in the sandbox tools, removes Pro.

Backend checks during the pass:

```sh
curl https://YOUR_BACKEND_DOMAIN/api/app-store/status
curl -H 'x-user-id: USER_ID_FROM_APP' https://YOUR_BACKEND_DOMAIN/api/subscription
```

Do not mark the TestFlight subscription pass complete until both app UI state and backend subscription state agree.
