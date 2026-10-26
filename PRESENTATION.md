# PetCore Presentation Guide

## Project Scope

PetCore is a Flutter veterinary records application backed by Firebase. This workstream delivers the access and control layer: authentication, user profiles, roles, branch assignment, protected navigation, dashboard data, and document access.

## Architecture

```text
Firebase Authentication
          |
          v
      AuthGate
          |
          v
   User profile (role + branchId)
          |
          v
 RolePermissions + Firebase Rules
          |
          v
 Protected Dashboard and features
          |
          v
 Branch-scoped clinical records and documents
```

## Demonstration Flow

1. Start the app while signed out and show the login screen.
2. Submit empty fields and invalid credentials to show validation and error feedback.
3. Sign in with an administrator account.
4. Open Users and assign a role and active branch.
5. Sign out and sign in as a veterinarian.
6. Show that the veterinarian receives Dashboard and Pets access, but not Users, Branches, or Owners.
7. Show the assigned branch on the dashboard.
8. Create a consultation or vaccination and confirm the dashboard displays only records from that branch.
9. Upload a medical document from a pet and show progress, success feedback, and the document list.
10. Sign out and confirm the protected dashboard is no longer available.

## Role Matrix

| Feature | ADMIN | VETERINARIAN | CLINIC STAFF |
| --- | --- | --- | --- |
| Dashboard | Yes | Yes | Yes |
| Owners | Yes | No | Yes |
| Pets | Yes | Yes | Yes |
| Users | Yes | No | No |
| Branches | Yes | No | No |
| Clinical record creation | Assigned branch | Assigned branch | No |

## Security Controls

- Firebase Authentication gates the application entry point.
- Client navigation hides unavailable features and each protected screen checks permissions again.
- Dashboard clinical data is filtered by the signed-in user's `branchId`.
- Firestore rules restrict medical collections to the user's branch, except administrators.
- Storage rules restrict document paths to the user's branch.
- Users without a branch assignment cannot view branch-scoped clinical data or upload documents.
- `firestore.rules` and `storage.rules` must be deployed before a shared Firebase environment is used.

## Validation

From the Flutter project directory:

```bash
flutter pub get
flutter analyze
flutter test
firebase deploy --only firestore:rules,storage
```

The local development environment used during implementation did not include the Flutter or Firebase CLI, so runtime tests and deployed rule tests must be run on a configured Flutter/Firebase machine.

## Final Acceptance Checklist

- [ ] Firebase configuration is present for the target platforms.
- [ ] Email/password authentication is enabled.
- [ ] Test users exist for all three roles.
- [ ] Each operational test user has an active branch assignment.
- [ ] Firebase rules are deployed.
- [ ] Login, logout, role navigation, branch filtering, dashboard records, and document upload are demonstrated.
- [ ] `flutter analyze` and `flutter test` pass.
