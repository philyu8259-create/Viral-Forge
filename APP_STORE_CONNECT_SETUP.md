# App Store Connect Subscription Setup

## Product IDs

These auto-renewable subscriptions are configured in the `ViralForge Pro` subscription group.

App Store Connect app ID: `6763895926`
Subscription group ID: `22053732`

| Product | Product ID | Apple ID | Duration | Base price |
| --- | --- | --- | --- | --- |
| ViralForge Pro Monthly | `viralforge_pro_monthly` | `6763896490` | 1 month | China target `CNY 39.8/month` |
| ViralForge Pro Yearly | `viralforge_pro_yearly` | `6763896846` | 1 year | China target `CNY 398/year` |

The current App Store Connect setup was created from US base prices. For the China-first release, manually verify and adjust the China storefront prices to exactly `CNY 39.8/month` and `CNY 398/year`.

## App Store Connect Steps

1. Add subscription review screenshots when the paywall UI is final.
2. Make sure Paid Apps Agreement, bank, and tax setup are complete.
3. Configure App Store Server Notifications V2 after a public HTTPS backend URL exists.
4. Upload an app build.
5. On the app version page, attach the first subscription in the App In-App Purchases and Subscriptions section before submitting to App Review.

## Xcode Steps

1. In-App Purchase capability is enabled in `project.yml` and regenerated into `ViralForge.xcodeproj`.
2. Keep `ViralForge.storekit` for local simulator testing. It is configured for China storefront/local prices: monthly `39.8`, yearly `398`.
3. Use `SUBSCRIPTION_SANDBOX_TEST_PLAN.md` for local StoreKit and TestFlight sandbox validation.
4. Test with sandbox Apple IDs before TestFlight.

## Production Backend Note

The app sends the StoreKit 2 verified transaction plus its signed transaction JWS to `/api/subscription/sync`. In local development mode, the backend cross-checks the JWS payload fields, stores the raw payload, and marks the user's Pro quota active.

```env
IAP_VERIFICATION_MODE=local_development
```

For production, configure:

```env
IAP_VERIFICATION_MODE=app_store_server
APP_STORE_SERVER_ENVIRONMENT=sandbox
APP_STORE_SERVER_ISSUER_ID=...
APP_STORE_SERVER_KEY_ID=...
APP_STORE_SERVER_BUNDLE_ID=com.phil.viralforge
APP_STORE_SERVER_PRIVATE_KEY_PATH=/secure/path/AuthKey_XXXXXXXXXX.p8
```

The backend also exposes:

```text
GET  /api/app-store/status
POST /api/app-store/notifications/v2
```

Before release, deploy the backend behind HTTPS, set the notification URL in App Store Connect, and test with Apple's test notification flow.

The app uses StoreKit `appAccountToken` during purchase. The token is a stable UUID generated from the backend `userId`, so server notifications can be matched back to the local user by `appAccountToken` or `originalTransactionId`.

Local backend subscription smoke test:

```sh
npm --prefix backend run smoke:subscriptions
```
