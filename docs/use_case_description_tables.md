# WARISAN KITA — USE CASE SPECIFICATIONS (AUTH & ADMIN MODULE)

---

### USE CASE : UC001_USER_LOGIN

| BASIC FLOW | |
| :---: | :---: |
| **USER** | **SYSTEM** |
| | 1. Use case begins when system prompt user to enter login credentials [M1: Enter credentials] [FR001_1] |
| 2. User enter username/handle or email, and password [A6: Forgot password] | |
| | 3. System perform real-time form validation (non-empty fields, email/handle regex check, password min 8 characters) [C1: Password length] [A1: Invalid format] [FR001_2] |
| | 4. System resolve username to registered email if handle provided, query DB, authenticate credentials, and verify Role-Based Access Control (RBAC) [A2: Authentication failed] [A3: Account suspended] [FR001_3] |
| | 5. System verify user role and active mode options [M2: Login successful] [A4: Artisan pending approval] [A5: Artisan active mode selection] |
| | 6. System display designated user dashboard (Admin Dashboard, Artisan Studio Dashboard, or Tourist Exploration Dashboard) |
| | 7. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Invalid format**<br>A1.1 System prompt inline validation error [M3: Password must be at least 8 characters / Please enter valid handle or email]<br>A1.2 Return to Step 2<br><br>**A2: Authentication failed**<br>A2.1 System prompt error message [M4: Invalid credentials]<br>A2.2 Return to Step 2<br><br>**A3: Account suspended**<br>A3.1 System detect status == 'SUSPENDED'<br>A3.2 System prompt error message [M5: Account suspended by administrator]<br>A3.3 Return to Step 2<br><br>**A4: Artisan pending approval**<br>A4.1 System detects artisan account status is 'PENDING_APPROVAL' or 'PENDING'<br>A4.2 System route artisan to Application Status Screen [M6: Pending admin review]<br>A4.3 System display 3-stage review timeline and lock studio editing controls<br>A4.4 User can click "Explore as Cultural Tourist while waiting" to browse crafts<br>A4.5 Use case ends<br><br>**A5: Artisan active mode selection (Master Artisan vs Cultural Tourist)**<br>A5.1 System detects account has Artisan privileges (or pending application)<br>A5.2 System display Role Selection Dialog [M7: Select active session mode] [FR001_4]<br>A5.3 User selects desired active session mode:<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Master Artisan** selected & status is **'APPROVED'**: System set active session and route user to Artisan Studio Dashboard [Return to Step 6]<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Master Artisan** selected & status is **'PENDING_APPROVAL'**: System route user directly to Application Status Screen [A4]<br>&nbsp;&nbsp;&nbsp;&nbsp;• If **Cultural Tourist** selected: System set active session and route user to Tourist Exploration Dashboard [Return to Step 6]<br>A5.4 Use case ends<br><br>**A6: Forgot password**<br>A6.1 User select "Forgot Password" on login screen<br>A6.2 System initiate Password Recovery Flow (Refer to **UC003_RESET_PASSWORD**)<br>A6.3 Use case ends | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER LOGIN CREDENTIALS"<br>M2 : "LOGIN SUCCESSFUL"<br>M3 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M4 : "INVALID CREDENTIALS"<br>M5 : "ACCOUNT SUSPENDED BY ADMINISTRATOR: CONTACT SUPPORT"<br>M6 : "ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL"<br>M7 : "ARTISAN ACCOUNT DETECTED: PLEASE SELECT YOUR ACTIVE SESSION MODE" | |
| **CONSTRAINTS** | |
| C1 : Password length $\ge$ 8 characters<br>C2 : Unapproved Artisan roles (status == 'PENDING_APPROVAL' or 'PENDING') MUST route to the Application Status Screen when Master Artisan mode is selected<br>C3 : User status == 'SUSPENDED' MUST strictly block authentication<br>C4 : Accounts with Artisan privileges MUST be offered session mode selection (Artisan Studio vs Tourist Explorer) upon login | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR001_1** | System prompt user to enter login credentials (supporting both username/handle and email) with multilingual UI support |
| **FR001_2** | System validate form fields in real-time, enforce min 8 character password constraint, and resolve handle identifiers to account email |
| **FR001_3** | System verify RBAC role and account approval status, routing user to the designated UI |
| **FR001_4** | System allow artisans to choose between Master Artisan Studio Mode and Cultural Tourist Exploration Mode |

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
| | 8. System create new Tourist account in database with role 'Tourist' and status 'ACTIVE' [M2: Registration successful] [FR002_4] |
| | 9. System redirect user to Tourist Exploration Dashboard (where user can browse crafts or apply for Master Artisan studio verification) [A5: Apply for Master Artisan studio] |
| | 10. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Invalid password**<br>A1.1 System prompt error message [M3: Password must be at least 8 characters]<br>A1.2 Return to Step 3<br><br>**A2: Mismatched passwords**<br>A2.1 System prompt error message [M4: Passwords do not match]<br>A2.2 Return to Step 3<br><br>**A3: Account already exists**<br>A3.1 System detect email is already registered in DB and display inline warning banner with 1-tap "Sign In" button<br>A3.2 System prompt error message [M5: Account already registered: Please sign in instead]<br>A3.3 Return to Step 3<br><br>**A4: Duplicate username handle**<br>A4.1 System detect chosen username handle is already taken by another registered user and display ❌ status badge<br>A4.2 System prompt error message [M6: Username already taken]<br>A4.3 Return to Step 3<br><br>**A5: Apply for Master Artisan Studio (In-App Onboarding Flow)**<br>A5.1 Authenticated tourist navigates to Tourist Profile (or Role Switcher) and selects "Apply for Master Artisan" [FR002_5]<br>A5.2 System display Artisan Studio Application Form prompting studio details and optional document attachments<br>A5.3 User enters Studio Name, Craft Category, SSM Reg No., State, Bio, and optionally uploads verification proofs (SSM PDF, Kraftangan Master Certificate PDF, workshop photos) [A5-1: Missing studio details] [FR002_6]<br>A5.4 System validate inputs, enforce unique username handle, and save artisan studio profile with status 'PENDING_APPROVAL' in DB [C3: Pending default]<br>A5.5 System route user to Application Status Screen [M7: Application submitted]<br>A5.6 *[Upon Admin Approval in UC100]*: System upgrades user role to 'Artisan' with status 'ACTIVE' in DB<br>A5.7 Use case ends<br><br>**A5-1: Missing studio registration details**<br>A5-1.1 System detect required studio name or SSM / Kraftangan license number is missing<br>A5-1.2 System prompt error message [M8: Please provide required studio registration details]<br>A5-1.3 Return to Step A5.3 | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER REGISTRATION DETAILS"<br>M2 : "REGISTRATION SUCCESSFUL: WELCOME CULTURAL EXPLORER"<br>M3 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M4 : "PASSWORDS DO NOT MATCH"<br>M5 : "ACCOUNT ALREADY REGISTERED: PLEASE SIGN IN INSTEAD"<br>M6 : "USERNAME ALREADY TAKEN: PLEASE CHOOSE A UNIQUE USERNAME"<br>M7 : "ARTISAN APPLICATION SUBMITTED: PENDING ADMIN APPROVAL"<br>M8 : "PLEASE PROVIDE REQUIRED STUDIO REGISTRATION DETAILS"<br>M9 : "INVALID FILE FORMAT: PLEASE UPLOAD A PDF, PNG, OR JPG DOCUMENT" | |
| **CONSTRAINTS** | |
| C1 : Password length $\ge$ 8 characters with live 4-level strength meter (Weak, Fair, Good, Strong) and security requirement checklist<br>C2 : Password input string == Confirm Password input string<br>C3 : Artisan account application status MUST initialize strictly as "PENDING_APPROVAL" in DB<br>C4 : Username handles (@handle) MUST be 3–20 alphanumeric characters / underscores and strictly unique across all accounts in DB<br>C5 : Supporting document uploads MUST be in PDF, PNG, or JPG formats | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR002_1** | System provide clean single-page registration interface for all onboarding users as Cultural Tourists with live feedback |
| **FR002_2** | System evaluate password strength in real-time and provide interactive security requirement checklist chips |
| **FR002_3** | System validate matching password confirmation states in real-time during registration |
| **FR002_4** | System perform debounced live check for unique username handles and assign initial RBAC role ('Tourist') with status 'ACTIVE' |
| **FR002_5** | System provide dedicated in-app Master Artisan studio application flow for registered tourists |
| **FR002_6** | System provide document attachment pipeline supporting optional SSM certificates, Kraftangan accreditations, and workshop photos |

---

### USE CASE : UC003_RESET_PASSWORD

| BASIC FLOW | |
| :---: | :---: |
| **USER** | **SYSTEM** |
| | 1. Use case begins when user select "Forgot Password" on login screen [FR003_1] |
| | 2. System prompt user to enter registered email address [M1: Enter registered email] |
| 3. User enter registered email address and submit | |
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
| **A1: Email not found**<br>A1.1 System prompt error message [M4: Email not registered]<br>A1.2 Return to Step 2<br><br>**A2: Invalid format**<br>A2.1 System prompt error message [M5: Password must be at least 8 characters]<br>A2.2 Return to Step 9<br><br>**A3: Mismatched passwords**<br>A3.1 System prompt error message [M6: Passwords do not match]<br>A3.2 Return to Step 9<br><br>**A4: Expired or invalid token**<br>A4.1 System detect token is expired (> 15 mins) or already consumed<br>A4.2 System prompt error message [M7: Reset link expired]<br>A4.3 System redirect to Step 2 | |
| **MESSAGE** | |
| M1 : "PLEASE ENTER YOUR REGISTERED EMAIL ADDRESS"<br>M2 : "PASSWORD RESET LINK HAS BEEN SENT TO YOUR EMAIL"<br>M3 : "PASSWORD RESET SUCCESSFUL: YOU MAY NOW LOGIN"<br>M4 : "EMAIL ADDRESS NOT FOUND IN SYSTEM"<br>M5 : "PASSWORD MUST BE AT LEAST 8 CHARACTERS"<br>M6 : "PASSWORDS DO NOT MATCH"<br>M7 : "PASSWORD RESET LINK IS EXPIRED OR INVALID: PLEASE REQUEST A NEW ONE" | |
| **CONSTRAINTS** | |
| C1 : Password reset tokens must expire after 15 minutes<br>C2 : Password length $\ge$ 8 characters evaluated with live strength meter<br>C3 : Password input string == Confirm Password input string<br>C4 : Tokens must be strictly single-use and invalidated immediately upon password update | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR003_1** | System provide a password recovery entry point on the authentication screen |
| **FR003_2** | System verify existence of registered email in DB |
| **FR003_3** | System generate cryptographic tokens and dispatch recovery emails |
| **FR003_4** | System validate new password complexity with Password Strength Meter and update hashed credentials in DB |

---

### USE CASE : UC100_MODERATE_ARTISAN_PROFILE

| BASIC FLOW | |
| :---: | :---: |
| **ADMINISTRATOR** | **SYSTEM** |
| | 1. Use case begins when system retrieve and display pending artisan profile applications from DB [FR100_1] |
| 2. Administrator select an artisan application to review | |
| | 3. System display artisan profile details, SSM business registration number & optional PDF, Kraftangan Master Certificate, and studio workshop photos |
| 4. Administrator select "Approve" menu [A1: Reject profile] [A2: Suspend user] | |
| | 5. System validate approval action |
| | 6. System update artisan profile status to 'APPROVED' in the database and upgrade user role to 'Artisan' [C1: DB Update Success] [FR100_2] |
| | 7. System prompt success message [M1: Profile approved] |
| | 8. System return to pending profiles list |
| | 9. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Reject profile**<br>A1.1 Administrator select "Reject" menu and input rejection reasons<br>A1.2 System update profile status to 'REJECTED' in DB<br>A1.3 System prompt success message [M2: Profile rejected]<br>A1.4 Return to Step 1<br><br>**A2: Suspend user**<br>A2.1 Administrator select "Suspend User" in User Management<br>A2.2 System update user status to 'SUSPENDED' in DB<br>A2.3 System prompt success message [M3: User suspended]<br>A2.4 Return to Step 1 | |
| **MESSAGE** | |
| M1 : "PROFILE APPROVED SUCCESSFULLY"<br>M2 : "PROFILE REJECTED"<br>M3 : "USER ACCOUNT SUSPENDED BY ADMINISTRATOR" | |
| **CONSTRAINTS** | |
| C1 : Profile status column in DB must be explicitly updated to 'APPROVED', 'REJECTED', or 'SUSPENDED' | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR100_1** | System retrieve and display pending artisan profiles and verification documents |
| **FR100_2** | System perform verification, CRUD, and status moderation operations on artisan profiles |

---

### USE CASE : UC101_ADMIN_USER_MANAGEMENT

| BASIC FLOW | |
| :---: | :---: |
| **ADMINISTRATOR** | **SYSTEM** |
| | 1. Use case begins when system retrieve and display registered users table (Administrators, Artisans, Tourists) from DB [FR101_1] |
| 2. Administrator search and filter users by role or status (Active, Pending, Suspended) | |
| | 3. System display filtered user records with activity status and verification details |
| 4. Administrator select a specific user and click "Suspend Account" [A1: Reactivate account] [A2: Reset credentials] | |
| | 5. System prompt confirmation dialog and reason input |
| 6. Administrator confirm suspension action | |
| | 7. System update user status to 'SUSPENDED' in DB and revoke active session tokens [C1: Immediate Session Revocation] [FR101_2] |
| | 8. System prompt success message [M1: User suspended] and refresh user list |
| | 9. Use case ends |
| **ALTERNATE FLOW** | |
| **A1: Reactivate account**<br>A1.1 Administrator select suspended user and click "Reactivate Account"<br>A1.2 System update user status to 'ACTIVE' (or 'APPROVED') in DB<br>A1.3 System prompt success message [M2: Account reactivated]<br>A1.4 Return to Step 3<br><br>**A2: Reset credentials**<br>A2.1 Administrator select user and click "Reset Password"<br>A2.2 System send password reset token email to user<br>A2.3 System prompt success message [M3: Reset link sent]<br>A2.4 Return to Step 3 | |
| **MESSAGE** | |
| M1 : "USER ACCOUNT SUSPENDED: Login access revoked"<br>M2 : "USER ACCOUNT REACTIVATED SUCCESSFULLY"<br>M3 : "PASSWORD RESET EMAIL SENT TO USER" | |
| **CONSTRAINTS** | |
| C1 : Suspending an account MUST immediately block authentication and invalidate active tokens<br>C2 : Administrators cannot suspend their own primary super-admin account | |
| **FUNCTIONAL REQUIREMENTS** | |
| **FR101_1** | System retrieve, search, and filter all registered users by role and status |
| **FR101_2** | System allow administrators to suspend, reactivate, and manage user security states in DB |
