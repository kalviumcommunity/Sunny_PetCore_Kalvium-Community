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
