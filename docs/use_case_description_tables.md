# WARISAN KITA — USE CASE SPECIFICATIONS (AUTH & ADMIN MODULE)

---

### USE CASE : UC001_USER_LOGIN

| BASIC FLOW | |
| :---: | :---: |
| **USER** | **SYSTEM** |
| | 1. Use case begins when system prompt user to enter login credentials [M1: Enter credentials] [FR001_1] |
| 2. User enter username/handle or email, and password [A6: Forgot password] | |
| | 3. System perform real-time form validation (non-empty fields, email/handle format, password min 8 characters) [C1: Password length] [A1: Invalid format] [FR001_2] |
| | 4. System resolve username to registered email if handle provided, query DB, authenticate credentials, and verify Role-Based Access Control (RBAC) [A2: Authentication failed] [A3: Account suspended] [A8: Unconfirmed email account] [FR001_3] |
| | 5. System verify user role and active mode options [M2: Login successful] [A4: Artisan pending approval] [A5: Artisan active mode selection] [A7: Admin account detected on mobile] |
| | 6. System display designated user dashboard (Artisan Studio Dashboard or Tourist Exploration Dashboard) |
| | 7. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Invalid format**<br>A1.1 System prompt inline validation error [M3: Password must be at least 8 characters / Please enter valid handle or email]<br>A1.2 Return to Step 2<br><br>**A2: Authentication failed**<br>A2.1 System prompt error message [M4: Invalid credentials]<br>A2.2 Return to Step 2<br><br>**A3: Account suspended**<br>A3.1 System detect status == 'SUSPENDED'<br>A3.2 System prompt error message [M5: Account suspended by administrator]<br>A3.3 Return to Step 2<br><br>**A4: Artisan pending approval**<br>A4.1 System detects artisan account status is 'PENDING_APPROVAL' or 'PENDING'<br>A4.2 System route artisan to Application Status Screen [M6: Pending admin review]<br>A4.3 System display 3-stage review timeline and lock studio editing controls<br>A4.4 User can click "Explore as Cultural Tourist while waiting" to browse crafts<br>A4.5 Use case ends<br><br>**A5: Artisan active mode selection (Master Artisan vs Cultural Tourist)**<br>A5.1 System detects account has Artisan privileges (or dual role)<br>A5.2 System display Role Selection Dialog [M7: Select active session mode] [FR001_4]<br>A5.3 User selects desired active session mode:<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Master Artisan** selected & status is **'APPROVED'**: System set active session and route user to Artisan Studio Dashboard [Return to Step 6]<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Master Artisan** selected & status is **'PENDING_APPROVAL'**: System route user directly to Application Status Screen [A4]<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Cultural Tourist** selected: System set active session and route user to Tourist Exploration Dashboard [Return to Step 6]<br>A5.4 Use case ends<br><br>**A6: Forgot password**<br>A6.1 User select "Forgot Password" on mobile login screen<br>A6.2 System initiate Password Recovery Flow (Refer to **UC003_RESET_PASSWORD**)<br>A6.3 Use case ends<br><br>**A7: Administrator account detected on mobile**<br>A7.1 System detect administrator login attempt on Mobile Native App<br>A7.2 System display modal dialog: "Admin Web Portal Only — Administrator moderation console is hosted exclusively on Desktop Web"<br>A7.3 System provide direct 1-tap "OPEN WEB PORTAL" button launching `https://warisan-kita.vercel.app` (Refer to **UC102_ADMIN_PORTAL_LOGIN**)<br>A7.4 Use case ends<br><br>**A8: Unconfirmed / Unverified email account**<br>A8.1 System detect authentication attempt on account with unconfirmed email address (`email_confirmed_at == NULL`)<br>A8.2 System display Email Verification Modal dialog: "Email Verification Required — Please verify your email with the 6-digit code sent to your inbox"<br>A8.3 System provide direct "VERIFY EMAIL NOW" button routing user to Email Verification Screen (`/verify-email`) [FR001_6]<br>A8.4 User completes 6-digit OTP verification (Refer to **UC002_USER_REGISTRATION**)<br>A8.5 Use case ends | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER LOGIN CREDENTIALS"<br>M2 : "LOGIN SUCCESSFUL"<br>M3 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M4 : "INVALID CREDENTIALS"<br>M5 : "ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT"<br>M6 : "ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL"<br>M7 : "ARTISAN ACCOUNT DETECTED: PLEASE SELECT YOUR ACTIVE SESSION MODE"<br>M8 : "ADMIN WEB PORTAL ONLY: PLEASE ACCESS VIA WEB BROWSER"<br>M9 : "EMAIL NOT CONFIRMED: PLEASE VERIFY YOUR EMAIL ADDRESS WITH THE 6-DIGIT CODE SENT TO YOUR INBOX" | |
| **CONSTRAINTS** | |
| C1 : Password length $\ge$ 8 characters<br>C2 : Unapproved Artisan roles (status == 'PENDING_APPROVAL' or 'PENDING') MUST route to the Application Status Screen when Master Artisan mode is selected<br>C3 : User status == 'SUSPENDED' MUST strictly block authentication<br>C4 : Accounts with Artisan privileges MUST be offered session mode selection (Artisan Studio vs Tourist Explorer) upon login<br>C5 : Administrator accounts attempting authentication on mobile MUST be blocked from mobile entry and directed to the Web Portal<br>C6 : Unconfirmed email accounts MUST strictly complete 6-digit OTP verification before login access is granted | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR001_1** | System prompt user to enter login credentials (supporting both username/handle and email) on mobile app |
| **FR001_2** | System validate form fields in real-time, enforce min 8 character password constraint, and resolve handle identifiers to account email |
| **FR001_3** | System verify RBAC role and account approval status, routing user to the designated UI |
| **FR001_4** | System allow artisans to choose between Master Artisan Studio Mode and Cultural Tourist Exploration Mode |
| **FR001_5** | System detect administrator accounts attempting login on mobile devices and provide direct redirection to the live Web Portal (Refer to UC102_ADMIN_PORTAL_LOGIN) |
| **FR001_6** | System enforce email verification guard during login, preventing unconfirmed accounts from authenticating and providing a direct shortcut to OTP verification |

---

### USE CASE : UC002_USER_REGISTRATION

| BASIC FLOW | |
| :---: | :---: |
| **USER** | **SYSTEM** |
| 1. User select "Register / Join Us" on login screen (or authenticated tourist selects "Apply for Master Artisan" in Profile / Role Switcher) [A5: Apply for Master Artisan studio] | |
| | 2. System display Single-Page Tourist Registration form with real-time feedback [M1: Enter registration details] [FR002_1] |
| 3. User enter Full Name, Unique Username/Handle (@handle), Email, Password, and Confirm Password | |
| | 4. System evaluate password in real-time using Password Strength Meter & Live Checklist (Weak/Fair/Good/Strong, 8+ chars, Upper/Lower, Numbers, Symbols) [C1: Password strength & length] [A1: Invalid password] [FR002_2] |
| | 5. System perform debounced live check for unique username availability with visual status badges [C4: Unique username handle] [A4: Duplicate username] |
| | 6. System perform live email format check and duplicate account detection with direct Sign In shortcut [A3: Account already exists] |
| | 7. System validate matching password confirmation [C2: Passwords match] [A2: Mismatched passwords] [FR002_3] |
| | 8. System initiate registration in Supabase Auth, dispatch a 6-digit OTP verification code to the user's email via Gmail SMTP mailer, and transition user to the **Email Verification Screen (`/verify-email`)** [M10: Verification code sent] [FR002_7] |
| 9. User enter 6-digit numeric OTP code (or paste code) [A6: Invalid OTP code] [A7: Resend OTP code] | |
| | 10. System verify 6-digit OTP token against Supabase Auth (`verifyOTP`), mark email as confirmed (`email_confirmed_at = NOW()`), activate user session, and initialize Tourist account in DB (`users` table) with role 'Tourist' and status 'ACTIVE' [M2: Registration successful] [FR002_4] |
| | 11. System redirect user to Tourist Exploration Dashboard (where user can browse crafts or apply for Master Artisan studio verification) [A5: Apply for Master Artisan studio] |
| | 12. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Invalid password**<br>A1.1 System prompt error message [M3: Password must be at least 8 characters]<br>A1.2 Return to Step 3<br><br>**A2: Mismatched passwords**<br>A2.1 System prompt error message [M4: Passwords do not match]<br>A2.2 Return to Step 3<br><br>**A3: Account already exists**<br>A3.1 System detect email is already registered in DB and display inline warning banner with 1-tap "Sign In" button<br>A3.2 System prompt error message [M5: Account already registered: Please sign in instead]<br>A3.3 Return to Step 3<br><br>**A4: Duplicate username handle**<br>A4.1 System detect chosen username handle is already taken by another registered user and display ❌ status badge<br>A4.2 System prompt error message [M6: Username already taken]<br>A4.3 Return to Step 3<br><br>**A5: Apply for Master Artisan Studio (In-App Onboarding Flow)**<br>A5.1 Authenticated tourist navigates to Tourist Profile (or Role Switcher) and selects "Apply for Master Artisan" [FR002_5]<br>A5.2 System display Artisan Studio Application Form prompting studio details, interactive Google Map location picker, and document attachments<br>A5.3 User enters Studio Name, Craft Category, SSM Reg No., State, Bio, selects physical studio coordinates via Interactive Google Map (lat/lng), and optionally uploads verification proofs (SSM PDF, Kraftangan Master Certificate PDF, workshop photos) [A5-1: Missing studio details] [FR002_6] [FR002_8]<br>A5.4 System validate inputs, enforce unique username handle, and save artisan studio profile in normalized `artisan_profiles` table with status 'PENDING_APPROVAL' in DB [C3: Pending default]<br>A5.5 System route user to Application Status Screen [M7: Application submitted]<br>A5.6 *[Upon Admin Approval in UC100]*: System upgrades user role to 'Artisan' with status 'ACTIVE' in DB<br>A5.7 Use case ends<br><br>**A5-1: Missing studio registration details**<br>A5-1.1 System detect required studio name, SSM / Kraftangan license number, or map location is missing<br>A5-1.2 System prompt error message [M8: Please provide required studio registration details]<br>A5-1.3 Return to Step A5.3<br><br>**A6: Invalid or Expired Verification OTP Code**<br>A6.1 System detect entered 6-digit OTP code is incorrect, invalid, or expired (> 15 minutes)<br>A6.2 System display error message [M11: Invalid or expired verification code]<br>A6.3 Return to Step 9<br><br>**A7: Resend Verification Code with Cooldown Timer**<br>A7.1 User selects "Resend Code" on the verification screen<br>A7.2 If cooldown timer > 0s, action is disabled; once cooldown reaches 0s, system triggers `resendVerificationOtp()`<br>A7.3 System dispatch a fresh 6-digit OTP via Gmail SMTP mailer, restart 60-second cooldown timer, and display confirmation [M12: Verification code resent]<br>A7.4 Return to Step 9 | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER REGISTRATION DETAILS"<br>M2 : "REGISTRATION SUCCESSFUL: WELCOME CULTURAL EXPLORER"<br>M3 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M4 : "PASSWORDS DO NOT MATCH"<br>M5 : "ACCOUNT ALREADY REGISTERED: PLEASE SIGN IN INSTEAD"<br>M6 : "USERNAME ALREADY TAKEN: PLEASE CHOOSE A UNIQUE USERNAME"<br>M7 : "ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL"<br>M8 : "PLEASE PROVIDE REQUIRED STUDIO REGISTRATION DETAILS"<br>M9 : "INVALID FILE FORMAT: PLEASE UPLOAD A PDF, PNG, OR JPG DOCUMENT"<br>M10 : "VERIFICATION CODE SENT: PLEASE CHECK YOUR EMAIL INBOX"<br>M11 : "INVALID OR EXPIRED VERIFICATION CODE: PLEASE TRY AGAIN"<br>M12 : "A FRESH 6-DIGIT VERIFICATION CODE HAS BEEN SENT TO YOUR EMAIL" | |
| **CONSTRAINTS** | |
| C1 : Password length $\ge$ 8 characters with live 4-level strength meter (Weak, Fair, Good, Strong) and security requirement checklist<br>C2 : Password input string == Confirm Password input string<br>C3 : Artisan account application status MUST initialize strictly as "PENDING_APPROVAL" in DB<br>C4 : Username handles (@handle) MUST be 3–20 alphanumeric characters / underscores and strictly unique across all accounts in DB<br>C5 : Supporting document uploads MUST be in PDF, PNG, or JPG formats<br>C6 : Registration requires successful validation of a 6-digit numeric OTP token dispatched via SMTP (Gmail) before the user session is activated<br>C7 : Resend OTP action MUST enforce an active 60-second client-side cooldown timer<br>C8 : Artisan studio location registration MUST capture geographic coordinates (latitude, longitude) via interactive Google Map pin dropping | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR002_1** | System provide clean single-page registration interface for all onboarding users as Cultural Tourists with live feedback |
| **FR002_2** | System evaluate password strength in real-time and provide interactive security requirement checklist chips |
| **FR002_3** | System validate matching password confirmation states in real-time during registration |
| **FR002_4** | System perform debounced live check for unique username handles and assign initial RBAC role ('Tourist') with status 'ACTIVE' |
| **FR002_5** | System provide dedicated in-app Master Artisan studio application flow for registered tourists |
| **FR002_6** | System provide document attachment pipeline supporting optional SSM certificates, Kraftangan accreditations, and workshop photos |
| **FR002_7** | System dispatch 6-digit OTP verification code upon registration and provide a dedicated verification screen with auto-advancing PIN input and 60-second cooldown timer |
| **FR002_8** | System provide interactive Google Maps widget for artisan studio registration with geocoding and coordinate capture |

---

### USE CASE : UC003_RESET_PASSWORD

| BASIC FLOW | |
| :---: | :---: |
| **USER** | **SYSTEM** |
| | 1. Use case begins when user select "Forgot Password" on mobile login screen [FR003_1] |
| | 2. System prompt user to enter registered email address [M1: Enter registered email] |
| 3. User enter registered email address or username handle and submit [A5: Administrator reset restriction] | |
| | 4. System validate email format and query DB for existing account [A1: Email not found] [FR003_2] |
| | 5. System generate secure single-use password reset token with expiration timestamp [C1: Token validity 15 mins] |
| | 6. System dispatch password reset link to user's email [M2: Reset link sent] [FR003_3] |
| 7. User open reset link from email | |
| | 8. System validate token authenticity and display Reset Password form |
| 9. User enter new password and confirm password with live Password Strength Meter assistance | |
| | 10. System validate password complexity (min 8 chars) and matching confirmation [C2: Password length & strength] [C3: Passwords match] [A2: Invalid format] [A3: Mismatched passwords] [FR003_4] |
| | 11. System update encrypted password in DB and invalidate reset token [C4: Token single-use] |
| | 12. System prompt success message [M3: Password reset successful] |
| | 13. System redirect user to Login Screen |
| | 14. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Email not found**<br>A1.1 System prompt error message [M4: Email not registered]<br>A1.2 Return to Step 2<br><br>**A2: Invalid format**<br>A2.1 System prompt error message [M5: Password must be at least 8 characters]<br>A2.2 Return to Step 9<br><br>**A3: Mismatched passwords**<br>A3.1 System prompt error message [M6: Passwords do not match]<br>A3.2 Return to Step 9<br><br>**A4: Expired or invalid token**<br>A4.1 System detect token is expired (> 15 mins) or already consumed<br>A4.2 System prompt error message [M7: Reset link expired]<br>A4.3 System redirect to Step 2<br><br>**A5: Administrator account protection (Self-Service Reset Blocked)**<br>A5.1 System detect entered email, handle, or resolved user record belongs to an Administrator account (role == 'Admin' or known administrator email/identifier)<br>A5.2 System strictly block self-service password reset, display high-priority security alert banner [M8: Administrator account protected], and log security event<br>A5.3 Return to Step 2 | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER YOUR REGISTERED EMAIL ADDRESS"<br>M2 : "PASSWORD RESET LINK HAS BEEN SENT TO YOUR EMAIL"<br>M3 : "PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN"<br>M4 : "EMAIL ADDRESS NOT FOUND IN SYSTEM"<br>M5 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M6 : "PASSWORDS DO NOT MATCH"<br>M7 : "PASSWORD RESET LINK IS EXPIRED OR INVALID: PLEASE REQUEST A NEW ONE"<br>M8 : "ADMINISTRATOR ACCOUNT PROTECTED: ADMINISTRATOR CREDENTIALS CANNOT BE RESET VIA SELF-SERVICE. CONTACT SUPPORT." | |
| **CONSTRAINTS** | |
| C1 : Password reset tokens must expire after 15 minutes<br>C2 : Password length $\ge$ 8 characters evaluated with live strength meter<br>C3 : Password input string == Confirm Password input string<br>C4 : Tokens must be strictly single-use and invalidated immediately upon password update<br>C5 : All administrator accounts (including admin emails, usernames, and administrative roles) are strictly prohibited from resetting passwords via public self-service across mobile and web entry points | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR003_1** | System provide a password recovery entry point on the consumer mobile authentication screen |
| **FR003_2** | System verify existence of registered email in DB |
| **FR003_3** | System generate cryptographic tokens and dispatch recovery emails |
| **FR003_4** | System validate new password complexity with Password Strength Meter and update hashed credentials in DB |
| **FR003_5** | System enforce security restriction blocking self-service password resets for all Administrator accounts across mobile and web entry points |

---

### USE CASE : UC100_MODERATE_ARTISAN_PROFILE

| BASIC FLOW | |
| :---: | :---: |
| **ADMINISTRATOR** | **SYSTEM** |
| | 1. Use case begins when system dynamically retrieves and displays pending artisan profile applications from Cloud DB (`users` + `artisan_profiles`) [FR100_1] |
| 2. Administrator select an artisan application to review in the moderation queue [A3: Auto-Refresh Moderation Queues] [A4: Moderate Workshop Relocation Requests] | |
| | 3. System display artisan profile details, SSM business registration number & optional PDF, Kraftangan Master Certificate, studio workshop photos, and mapped geographic coordinates |
| 4. Administrator select "Approve" menu [A1: Reject profile] [A2: View Active Verified Artisans] [A4: Moderate Workshop Relocation Requests] | |
| | 5. System validate approval action |
| | 6. System update artisan profile status to 'APPROVED' in `artisan_profiles` table and upgrade user role to 'Artisan' with status 'ACTIVE' in `users` table [C1: DB Update Success] [FR100_2] |
| | 7. System prompt success message [M1: Profile approved] and refresh queues |
| | 8. System return to pending profiles list |
| | 9. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Reject profile**<br>A1.1 Administrator select "Reject" menu and input rejection reasons<br>A1.2 System update profile status to 'REJECTED' in `artisan_profiles` and `users` table in DB<br>A1.3 System prompt success message [M2: Profile rejected]<br>A1.4 Return to Step 1<br><br>**A2: View & Moderate Active Verified Artisans**<br>A2.1 Administrator navigates to "Active Artisans" tab<br>A2.2 System dynamically query verified artisan masters from DB joined with `artisan_profiles`<br>A2.3 Administrator can inspect active studio credentials, verify SSM numbers, and live-toggle operational status (Active / Suspended)<br>A2.4 Use case ends<br><br>**A3: Auto-Refresh Moderation Queues**<br>A3.1 Administrator clicks "Refresh" button on header bar<br>A3.2 System concurrently fetches latest Pending Artisans, Active Artisans, and Registered Users via `refreshAllData()`<br>A3.3 System update UI and display toast notification [M4: All moderation data refreshed]<br>A3.4 Return to Step 1<br><br>**A4: Moderate Workshop Relocation Requests (Relocation Moderation Queue)**<br>A4.1 Administrator navigates to "Relocation Requests" queue / tab<br>A4.2 System display pending relocation submissions side-by-side with current studio premise address and proposed coordinates (latitude, longitude) & relocation justification reason [FR100_4]<br>A4.3 Administrator reviews submitted details, inspects physical premises on interactive map, and selects either "Approve" or "Reject"<br>A4.4 If Approved: System updates artisan studio address and coordinates in `artisan_profiles` table, updates relocation status to 'APPROVED' in DB, and prompts success [M5: Relocation approved]<br>A4.5 If Rejected: System updates relocation status to 'REJECTED', retains original workshop premise address, and prompts success [M6: Relocation rejected]<br>A4.6 Return to Step 1 | |
| **MESSAGE** | |
| M1 : "PROFILE APPROVED SUCCESSFULLY: ARTISAN ROLE ACTIVATED"<br>M2 : "PROFILE REJECTED"<br>M3 : "USER ACCOUNT SUSPENDED BY ADMINISTRATOR"<br>M4 : "ALL ARTISAN, USER, AND MODERATION DATA REFRESHED"<br>M5 : "WORKSHOP RELOCATION APPROVED: STUDIO PREMISE LOCATION UPDATED"<br>M6 : "WORKSHOP RELOCATION REJECTED: ORIGINAL PREMISE RETAINED" | |
| **CONSTRAINTS** | |
| C1 : Profile status column in DB must be explicitly updated to 'APPROVED', 'REJECTED', or 'SUSPENDED'<br>C2 : Active artisans list must synchronize live with database records joined via foreign key `artisan_profiles.user_id`<br>C3 : Workshop premise addresses and coordinates can only be modified through administrative relocation approval workflow | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR100_1** | System dynamically retrieve and display live pending artisan profiles and verification documents from Cloud DB |
| **FR100_2** | System perform verification, CRUD, and status moderation operations on artisan profiles and user roles |
| **FR100_3** | System provide dedicated Active Artisans directory tab with real-time operational status toggling |
| **FR100_4** | System provide dedicated workshop relocation moderation queue supporting side-by-side comparison of current and proposed premise coordinates with approve/reject workflow |

---

### USE CASE : UC101_ADMIN_USER_MANAGEMENT

| BASIC FLOW | |
| :---: | :---: |
| **ADMINISTRATOR** | **SYSTEM** |
| | 1. Use case begins when system retrieves and displays registered users table (Administrators, Artisans, Tourists) from DB joined with `artisan_profiles` [FR101_1] |
| 2. Administrator search and filter users by 3 core platform roles (All Roles, Tourist, Artisan, Admin) or status (All Statuses, Active, Suspended) [A4: Role-Based Filtering] | |
| | 3. System display filtered user records with distinct role badges (Admin [Protected], Artisan, Tourist, Dual Role) and live account statuses |
| 4. Administrator select a non-admin user and click "Suspend Account" [A1: Reactivate account] [A2: Reset credentials] [A2-1: Admin credential protection] [A3: Admin suspension attempt blocked] | |
| | 5. System prompt confirmation dialog and reason input |
| 6. Administrator confirm suspension action | |
| | 7. System update user status to 'SUSPENDED' in DB and revoke active session tokens [C1: Immediate Session Revocation] [FR101_2] |
| | 8. System prompt success message [M1: User suspended] and refresh user list |
| | 9. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Reactivate account**<br>A1.1 Administrator select suspended user and click "Reactivate Account"<br>A1.2 System update user status to 'ACTIVE' (or 'APPROVED') in DB<br>A1.3 System prompt success message [M2: Account reactivated]<br>A1.4 Return to Step 3<br><br>**A2: Reset user credentials**<br>A2.1 Administrator select user and click "Reset Password"<br>A2.2 System dispatch secure password reset token email to user's registered address<br>A2.3 System prompt success message [M3: Reset link sent]<br>A2.4 Return to Step 3<br><br>**A2-1: Admin credential protection (Credential Tamper Protection)**<br>A2-1.1 Administrator attempts to trigger password reset on an account with role 'Admin'<br>A2-1.2 System detect target account has administrative privileges, disable credential reset action, and display security restriction [M5: Admin credential reset blocked] [C4: Admin Credential Protection]<br>A2-1.3 System reject reset request to prevent administrative takeover<br>A2-1.4 Return to Step 3<br><br>**A3: Admin suspension attempt blocked (Admin Protection)**<br>A3.1 Administrator attempts to suspend an account with role 'Admin'<br>A3.2 System detect administrator role, disable suspend action, and render `Admin (Protected)` shield badge [C2: Admin Protection]<br>A3.3 System reject suspension action and prevent privilege tampering<br>A3.4 Use case ends<br><br>**A4: Role-Based Filtering**<br>A4.1 Administrator selects role filter dropdown (`All Roles`, `Tourist`, `Artisan`, `Admin`)<br>A4.2 System dynamically filter registered users and update metric counter cards in real-time<br>A4.3 Return to Step 3 | |
| **MESSAGE** | |
| M1 : "USER ACCOUNT SUSPENDED: Login access revoked"<br>M2 : "USER ACCOUNT REACTIVATED SUCCESSFULLY"<br>M3 : "PASSWORD RESET EMAIL SENT TO USER"<br>M4 : "ADMIN SECURITY RESTRICTION: ADMINISTRATOR ACCOUNTS ARE PROTECTED AND CANNOT BE SUSPENDED"<br>M5 : "ADMIN SECURITY RESTRICTION: ADMINISTRATOR CREDENTIALS CANNOT BE RESET THROUGH USER MANAGEMENT" | |
| **CONSTRAINTS** | |
| C1 : Suspending an account MUST immediately block authentication and invalidate active tokens<br>C2 : Administrator accounts are strictly protected from suspension by any administrator in the UI<br>C3 : Role filter dropdown strictly reflects the 3 core platform roles (Tourist, Artisan, Admin)<br>C4 : Administrator credentials cannot be reset or modified via the user management console | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR101_1** | System retrieve, search, and filter all registered users by the 3 core roles (Tourist, Artisan, Admin) and status |
| **FR101_2** | System allow administrators to suspend, reactivate, and manage user security states in DB |
| **FR101_3** | System enforce Admin Account Protection preventing administrative accounts from being suspended |
| **FR101_4** | System enforce administrative credential protection blocking password resets on any administrator account from the user management console |

---

### USE CASE : UC102_ADMIN_PORTAL_LOGIN

| BASIC FLOW | |
| :---: | :---: |
| **ADMINISTRATOR** | **SYSTEM** |
| | 1. Use case begins when administrator accesses Web Moderation Console (`https://warisan-kita.vercel.app` or `/admin`) and system prompts for Administrator Credentials [M1: Enter admin credentials] [FR102_1] |
| 2. Administrator enter Admin Username / Email and Master Password | |
| | 3. System perform real-time field validation (non-empty fields, password min 8 characters) [C1: Password length] [A1: Invalid format] [FR102_2] |
| | 4. System query database, verify administrator cryptographic credentials, and enforce Administrator RBAC role [A2: Authentication failed] [A3: Non-admin account rejected] [FR102_3] |
| | 5. System establish secure administrator session token, persist session in storage, and route administrator to Moderation Dashboard (Overview, Artisan Verification Queue, Active Artisans, User Management, Workshop Relocation Requests, Quest Approvals, Forum Moderation, System Settings) [M2: Admin login successful] [FR102_4] |
| | 6. System display Admin Moderation Center with real-time statistics and pending verification counts |
| | 7. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Invalid format**<br>A1.1 System prompt inline validation error [M3: Password must be at least 8 characters / Please enter admin username]<br>A1.2 Return to Step 2<br><br>**A2: Authentication failed**<br>A2.1 System detect invalid credentials or incorrect master password<br>A2.2 System prompt error message [M4: Invalid administrator credentials: Access denied]<br>A2.3 Return to Step 2<br><br>**A3: Non-admin account rejected**<br>A3.1 System detect authenticated account does not possess 'Admin' role (e.g. Tourist or Artisan account)<br>A3.2 System display modal dialog: "Mobile App Required — Tourist and Artisan features require the Warisan Kita Mobile App"<br>A3.3 System deny web console access and return to Step 2<br><br>**A4: Automatic Session Restoration on Browser Refresh**<br>A4.1 Administrator reloads or refreshes browser while on `/admin`<br>A4.2 System verify active session token in Supabase / LocalStorage asynchronously<br>A4.3 System restore administrative session and refresh live data without kicking administrator to login screen [C5: Session Persistence] [FR102_5]<br>A4.4 Use case ends<br><br>**A5: Administrative Governance & Provisioning**<br>A5.1 System enforces root-level administrative governance; creation of administrator accounts is restricted from frontend client UI and managed directly via Supabase Console / DB seeds [C6: Admin Governance]<br>A5.2 Use case ends | |
| **MESSAGE** | |
| M1 : "MALAYSIAN HERITAGE MODERATION CONSOLE: PLEASE ENTER ADMIN CREDENTIALS"<br>M2 : "LOGIN SUCCESSFUL: AUTHENTICATED AS SYSTEM ADMINISTRATOR"<br>M3 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M4 : "INVALID ADMINISTRATOR CREDENTIALS: ACCESS DENIED"<br>M5 : "MOBILE APP REQUIRED: TOURIST AND ARTISAN FEATURES REQUIRE THE WARISAN KITA MOBILE APP" | |
| **CONSTRAINTS** | |
| C1 : Password length $\ge$ 8 characters<br>C2 : Login access to the Moderation Web Portal is strictly restricted to accounts with role 'Admin'<br>C3 : Self-service password recovery is strictly disabled on the administrative web console<br>C4 : Non-admin users attempting web access MUST be blocked and directed to the mobile native application<br>C5 : Active administrative sessions MUST persist across browser page reloads and refreshes<br>C6 : Administrator accounts must be provisioned via database governance rather than client UI | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR102_1** | System provide dedicated desktop web authentication interface for System Administrators with enterprise security branding |
| **FR102_2** | System validate administrative credentials in real-time and enforce role-based access control (RBAC) |
| **FR102_3** | System restrict portal access strictly to authorized administrator roles and reject consumer accounts |
| **FR102_4** | System initialize administrative session and render the multi-tab Moderation Dashboard |
| **FR102_5** | System automatically restore authenticated administrative sessions upon browser reload or navigation |
