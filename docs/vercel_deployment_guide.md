# 🚀 Vercel Deployment Guide for Warisan Kita Admin Web

This guide provides simple step-by-step instructions to deploy the **Warisan Kita Admin Web Dashboard** on **Vercel** with automated continuous deployment from your GitHub repository.

---

## 🛠️ Included Vercel Configuration Files

The repository is fully pre-configured for Vercel:
1. [`vercel.json`](file:///c:/Users/User/StudioProjects/Warisan_Kita/vercel.json): Configures output directory (`build/web`), clean URLs, SPA routing rewrites, and caching headers.
2. [`build.sh`](file:///c:/Users/User/StudioProjects/Warisan_Kita/build.sh): Automated build script that installs Flutter SDK on Vercel's build environment and compiles the web release.
3. [`package.json`](file:///c:/Users/User/StudioProjects/Warisan_Kita/package.json): Defines build scripts (`"vercel-build": "bash build.sh"`).
4. [`.vercelignore`](file:///c:/Users/User/StudioProjects/Warisan_Kita/.vercelignore): Excludes native mobile folders (`android/`, `ios/`) to optimize upload speeds.

---

## 📋 Steps to Deploy on Vercel

### Step 1: Push Changes to GitHub
Make sure all your latest changes on branch `Tze-Chuen` are pushed to GitHub.

---

### Step 2: Import Project into Vercel
1. Log in to your **[Vercel Dashboard](https://vercel.com/dashboard)**.
2. Click **"Add New..."** $\rightarrow$ **"Project"**.
3. Select your GitHub repository: `TC2251/WarisanKita`.
4. Choose the branch: `Tze-Chuen`.

---

### Step 3: Configure Project Settings on Vercel
In the Vercel **Configure Project** screen:

| Setting | Value |
| :--- | :--- |
| **Framework Preset** | `Other` |
| **Root Directory** | `./` |
| **Build Command** | `bash build.sh` *(or leave default)* |
| **Output Directory** | `build/web` |
| **Install Command** | *(Leave empty)* |

---

### Step 4: Click "Deploy"
1. Click the **Deploy** button.
2. Vercel will execute `build.sh`, set up Flutter stable, run `flutter build web --release`, and publish your app.
3. Once finished, you will receive your live URL:
   `https://warisan-kita.vercel.app`

---

## 🔐 Accessing the Admin Dashboard on Web

1. Open your Vercel URL in any browser.
2. Sign in with the Administrator credentials:
   - **Email**: `admin@warisankita.my`
   - **Password**: `admin123`
3. You will be automatically routed to `/admin` (`AdminModerationDashboardView`), featuring:
   - **Moderation Queue**: SSM license review, proof inspection, 1-click Approval/Rejection.
   - **Active Artisans Tab**: Master artisan directory and status toggles.
   - **User Management Tab**: Search, filter, and account suspension/reactivation.
   - **Forum Moderation & System Settings Tabs**.
