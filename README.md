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

## Phase 4 Role-Based Access Control

The supported roles are `ADMIN`, `VETERINARIAN`, and `CLINIC STAFF`. Access is least-privilege by default:

- `ADMIN`: Dashboard, owners, pets, and user management.
- `VETERINARIAN`: Dashboard and pets.
- `CLINIC STAFF`: Dashboard, owners, and pets.

Unknown or unassigned roles only receive the dashboard and cannot access operational screens. The Users screen also checks the role itself, so hiding its navigation item is not the only protection.

## Phase 5 Branch Management

Administrators can add, view, edit, and deactivate branches from the protected Branches screen. Each branch stores a name, address, phone number, and active status in the `branches` collection. User profiles are assigned to active branches through a branch selector, and the authenticated user's assigned branch is shown on the dashboard.

## Phase 6 Dashboard Foundation

The dashboard now includes today's consultations, upcoming follow-ups, vaccinations due within the next 30 days (including overdue records), recently viewed pets for the current session, and pet search by ID, name, or species. Quick actions are available for pet registration and clinical records according to role. Consultations, vaccinations, and treatments are stored in the `clinical_records` collection with pet, date, veterinarian, branch, notes, and follow-up/due-date data.

## Phase 12 Security and Testing

Firebase Authentication protects the application entry point. The role matrix protects navigation and feature actions, while the signed-in user's `branchId` scopes clinical dashboard and document reads. Users without a branch assignment cannot view branch-scoped clinical data or upload documents.

Deploy the checked-in rules before using a shared Firebase project:

```bash
firebase deploy --only firestore:rules,storage
```

The repository includes `firestore.rules`, `storage.rules`, and `firebase.json`. The test suite covers role permissions, branch assignment data, branch-filtered dashboard records, and shared protected UI states. Run it with `flutter test` on a machine with the Flutter SDK installed.

## Local Showcase Mode

`lib/main.dart` currently has `demoMode` enabled so the app can run without Firebase for a local showcase. It uses in-memory Firestore data and these development-only accounts:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@petcore.local` | `PetCoreAdmin2026!` |
| Veterinarian | `vet@petcore.local` | `PetCoreVet2026!` |
| Clinic staff | `staff@petcore.local` | `PetCoreStaff2026!` |

Set `demoMode` to `false` in `lib/main.dart` to restore the Firebase startup flow. Never use these credentials in production.

## Phase 13 Final Presentation

The complete demonstration flow, role matrix, security controls, validation commands, and release checklist are documented in [PRESENTATION.md](PRESENTATION.md).
