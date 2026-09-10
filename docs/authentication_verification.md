# Authentication verification

Authentication now requires a successful Supabase response. Cached profiles,
demo administrator credentials, local passwords and the former universal OTP
cannot authenticate users. Existing screens and repository method signatures
remain available.

## Backend prerequisites

- Administrators need an actual Supabase Auth account and a matching
  `public.users` row with an administrator role. The former demo admin login
  is intentionally removed.
- The existing `on_auth_user_created` trigger must create `public.users` and,
  for artisan registration, `artisan_profiles`. The app no longer substitutes
  client-created identities when authentication fails.
- For code-based signup verification, the Supabase signup email template must
  include the six-digit token expected by the existing verification screen.
- Allow the Android recovery redirect
  `io.supabase.warisankita://reset-callback` and the deployed web origin's
  `/forgot-password` URL in Supabase. Email link expiry is controlled by
  Supabase; the app no longer claims an independently enforced 15-minute expiry.

No live backend settings or database migrations were applied by this change.
The repository's schema includes permissive public update policies; these need
a separate backend authorization review before claiming production security.
Client-side role checks cannot secure a database with permissive policies.

## Regression coverage

The tests use an in-process HTTP backend with the real Supabase SDK. They cover
real versus demo admin login, literal username lookup, rejected verification,
unverified login, signup failures, cached sessions, suspended profiles, email
delivery failures, account-bound recovery, update failures, token reuse,
automatic email confirmation, and clearing login state after failure.

Existing profile, relocation, moderation, and account lifecycle tests remain
part of the full test suite. The old test accepting `DUMMY-TOKEN` as a valid
password reset was replaced with a verified recovery-session test.

## Live checks before supervisor demonstration

1. Register a test tourist; verify the received code and sign in using both
   email and a username containing an underscore. Repeat after restarting.
2. Try a wrong password, an unverified account, and an incorrect/expired code;
   none should enter the app. Confirm resend failures are displayed.
3. Sign in with a real administrator on the web. An incorrect password should
   show an authentication error, not the mobile-only message.
4. Request a password reset on Android. Open the actual email link, change the
   password, and confirm the old password fails and the new one works. Repeat
   with the app initially closed and initially open. An expired/reused link
   must not permit another change.
5. Confirm pending and approved artisans still reach the appropriate screens,
   a suspended account is rejected, and logout followed by reopening requires
   login.

These live checks require real email delivery, deployed database policies and
device deep links; simulated HTTP tests cannot certify those integrations.
