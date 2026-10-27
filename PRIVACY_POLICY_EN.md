# Yanik Rummy Offline — Privacy Policy

**Last Updated:** October 27, 2026

This Privacy Policy explains how user data is handled, which third-party services are utilized, and what user rights apply in the **Yanik Rummy Offline** ("Application") mobile application.

---

## 1. Overview and Offline Operation Principle

Yanik Rummy Offline is a single-player card game playable offline.
- Our application requires no user registration, account creation, or login.
- Directly identifiable personal data such as full name, email address, or phone number is **strictly never collected, never stored on servers, and never shared with third parties.**
- Game preferences (sound volume, vibration, assisted mode, selected avatar, and table options) are stored solely on the user's local device using local storage (`SharedPreferences`) and are never transmitted off the device.

---

## 2. Third-Party Advertising Services and Data Processing

To provide the application for free and support maintenance costs, the application utilizes **Google AdMob** (Google LLC) as a third-party advertising provider.

The Google AdMob SDK may automatically collect and process certain technical data for ad serving, frequency capping, fraud prevention, and reporting:

1. **Device or Other IDs:**
   - Google Advertising ID (Android Google Advertising ID - GAID / iOS IDFV)
   - Device manufacturer, model, operating system version, and screen size
2. **App Activity:**
   - Ad impressions, clicks, or ad dismissal events
3. **Diagnostics:**
   - Ad request response latency and ad loading error codes
4. **Approximate Network Information:**
   - IP address (processed in transit by Google AdMob servers for approximate geographic region detection and network security; no GPS or precise location is collected).

For detailed information on how Google processes data, please visit [Google Privacy & Terms](https://policies.google.com/privacy).

---

## 3. Consent Management (UMP / GDPR / KVKK Compliance)

For users in the European Economic Area (EEA), United Kingdom, and jurisdictions with applicable data protection laws, Google User Messaging Platform (**UMP**) integration is provided:

- Upon first launch or whenever legally required, users are presented with a UMP Consent Form to specify their consent preferences.
- Ad requests are initiated solely in accordance with the user's valid consent status (`canRequestAds`). If consent is not granted, personalized ad requests are blocked.
- Users may at any time reset their advertising identifier or disable ad personalization through their device's operating system settings (Android: *Settings > Google > Ads*, iOS: *Settings > Privacy & Security*).

---

## 4. Permissions and Their Purposes

Our application requests only the minimum permissions necessary for core operation:
- `android.permission.INTERNET`: Used solely for loading AdMob advertisements and the UMP consent form.
- `android.permission.ACCESS_NETWORK_STATE`: Checks network availability to ensure ad requests are only sent when an active connection exists, preventing offline gameplay delays.
- `android.permission.VIBRATE`: Used solely for haptic feedback during card draw, discard, and turn notifications; collects no data whatsoever.

The application **does not request** location (GPS), camera, microphone, contacts, photo gallery, or file storage permissions.

---

## 5. Children's Privacy

Our application is not directed at children under the age of 13 and does not knowingly collect personal data from children under 13.

---

## 6. Google Play Store Data Safety Declaration Guide

When completing the "Data Safety" form in the Google Play Console, the following official table should be referenced:

| Question / Category | Declaration Status | Description |
|---|---|---|
| **Does your app collect or share data?** | **Yes** | Advertising and analytics data is processed solely via the integrated Google Mobile Ads (AdMob) SDK. |
| **Is collected data encrypted in transit?** | **Yes** | All network requests are transmitted securely over the HTTPS protocol. |
| **Do you provide a way for users to request data deletion?** | **No** | The app does not have user accounts or registration; it is played directly offline. |
| **Data Type: Location** | **No** | GPS / precise location is neither requested nor collected. |
| **Data Type: Personal Info** | **No** | Name, email, phone number, etc. are not collected. |
| **Data Type: Financial Info** | **No** | No in-app purchases or payments exist. |
| **Data Type: Device or Other IDs** | **Collected and Shared** | Google Advertising ID (Advertising or marketing, Fraud prevention / Security). |
| **Data Type: App Activity** | **Collected and Shared** | Ad interaction data (Analytics, Advertising or marketing). |
| **Data Type: App Info and Performance** | **Collected and Shared** | Error and diagnostic data (Analytics / Diagnostics). |

---

## 7. Contact

If you have any questions regarding this Privacy Policy or data practices, please contact the developer via the support email address.
