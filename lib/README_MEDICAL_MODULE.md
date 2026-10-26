# PetCore Medical Module

The medical module records a pet's consultations, treatments, vaccinations,
prescriptions, follow-ups, and uploaded medical documents. Its screens provide
a combined medical-history timeline, follow-up tracking, and forms for creating
medical records.

## Firestore collections

The module uses these six collections:

- `consultations` - symptoms, diagnosis, clinical notes, treatment given, and
  an optional follow-up date.
- `treatments` - symptoms, diagnosis, treatment, medicine, dosage, duration,
  notes, and an optional follow-up date.
- `vaccinations` - vaccine name, date given, next due date, dosage, and notes.
- `prescriptions` - medicine, dosage, frequency, duration, and instructions.
- `followups` - the related record, follow-up date, status, and notes.
- `documents` - metadata and a download URL for a file stored in Firebase
  Storage under `documents/{petId}/`.

## Opening a pet's medical history

From a Pet Profile action, push `MedicalHistoryScreen` and pass the pet's
existing `petId`. For example:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MedicalHistoryScreen(petId: pet.petId),
  ),
);
```

Import the screen from `screens/medical_history_screen.dart`. The screen
provides navigation to consultation and treatment forms; vaccination,
prescription, follow-up, and document screens can likewise be opened with the
same pet ID.

## Record ownership and cross-branch visibility

Consultations, treatments, vaccinations, prescriptions, and follow-ups are
tagged with `petId`, `vetId`, and `branchId`. The medical-history and
follow-up queries use the pet ID rather than restricting records to the
current vet or branch, so records remain visible across branches. The existing
documents schema stores `petId`, `branchId`, and `uploadedBy` (rather than
`vetId`); document queries are also pet-scoped and are not filtered by branch.
