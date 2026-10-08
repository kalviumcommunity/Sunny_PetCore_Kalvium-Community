# Sunny_PetCore_Kalvium-Community
PetCore is a Flutter-based veterinary medical record platform for securely managing and accessing pet vaccination and treatment history across clinic branches.

## Phase 1 Setup

Phase 1 includes Firebase Authentication, user profiles, login/logout, session routing, and protected dashboard navigation.

Before running the app:

1. Create or select a Firebase project.
2. Register each target Flutter platform with that project.
3. Add the generated Firebase configuration files to the platform folders.
4. Enable Email/Password under Firebase Authentication.
5. Create at least one test user in Firebase Authentication.
6. Run `flutter pub get`, then `flutter run` from this directory.

After the first successful sign-in, PetCore creates a document in the `users` collection using the Firebase user ID. New profiles currently receive the temporary default role `CLINIC STAFF` and an empty `branchId`; role and branch administration belongs to later phases.

If Firebase is not configured, the app displays a setup error instead of using fake in-memory data.

## Phase 2 Session Management

The app listens to Firebase Authentication state changes on startup. Signed-out users can only see the login screen; signed-in users are routed to the protected dashboard. The dashboard logout action returns the user to login, and Firebase preserves the authenticated session between app launches according to its platform defaults.

Login validates required fields locally and displays specific feedback for invalid credentials, disabled accounts, network failures, and rate limiting. Authentication-stream failures provide a retry action.

## Phase 3 User Management

After authentication, PetCore creates a `users/{uid}` profile containing the user's name, email, role, and branch ID. The protected Users screen lists stored profiles and lets the signed-in user update their name, role, and branch assignment. Role-based restrictions are intentionally reserved for Phase 4.
