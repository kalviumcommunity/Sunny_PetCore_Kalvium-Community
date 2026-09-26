# Product Requirements Document (PRD)

# PetCore — Centralized Veterinary Health Records

**Version:** 1.1  
**Status:** Draft  
**Platform:** Mobile Application  
**Technology:** Dart, Flutter, Firebase Auth, Cloud Firestore, Firebase Storage

---

## 1. Product Overview

### Product Name

**PetCore**

### Product Description

PetCore is a cross-platform mobile application designed for a chain of veterinary clinics operating across multiple branches. It provides a centralized veterinary health-record system so authorized veterinarians and clinic staff can access and update a pet's medical history regardless of which branch the pet owner visits.

The application centralizes vaccination history, treatment notes, prescriptions, consultation records, follow-ups, and relevant medical documents.

### Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Programming Language | Dart | Application development |
| Frontend / UI | Flutter | Cross-platform mobile application |
| Authentication | Firebase Authentication | User identity and sessions |
| Database | Cloud Firestore | Pet, owner, clinic, and medical records |
| File Storage | Firebase Storage | Medical reports, prescriptions, images, and documents |
| Runtime | Emulator / Physical Device | Application execution |

---

# 2. Problem Statement

A chain of veterinary clinics operates across **[X] branches**, but each clinic maintains its own records for vaccination history and treatment notes. When a pet owner visits a different branch, the attending veterinarian may have no access to prior history.

The current problem should be quantified using a verified baseline before launch:

| Problem Area | Current Baseline | Measurement Method |
|---|---:|---|
| Number of clinic branches | **[X] branches** | Confirm with clinic management |
| Repeat/cross-branch visits affected by missing records | **[Y]%** | Audit a defined sample of recent visits |
| Average time lost retrieving or reconstructing prior records | **[Z] minutes per affected visit** | Time a sample of affected consultations |
| Duplicate-medication incidents linked to unavailable prior records | **[N] incidents per month** | Review incident/medical records |

These values must be populated from actual clinic records or a documented baseline study; they are not assumed product metrics.

This fragmented record-keeping can result in:

- Incomplete understanding of a pet's previous medical history
- Duplicate or unnecessary medication
- Missed vaccination and follow-up requirements
- Repeated diagnostic or treatment procedures
- Increased consultation time
- Dependence on pet owners to verbally provide previous medical information

The core problem is the absence of a centralized medical record that can be securely accessed by authorized staff across all clinic branches.

---

# 3. Product Goal

Build a centralized veterinary health-record application that allows authorized clinic staff to securely access and update a pet's medical history from any branch.

### Primary Goal

> Enable veterinarians at any authorized branch to access a pet's relevant medical history during a consultation, reducing dependence on manually shared records and supporting continuity of care.

---

# 4. Target Users

## 4.1 Primary Users

### Veterinarians

Veterinarians will use PetCore to:

- Search for pets
- View medical history
- Review previous treatments
- Review vaccination history
- View prescriptions
- Add consultation notes
- Add treatment records
- Record vaccinations
- Record follow-ups
- Upload relevant medical documents

## 4.2 Secondary Users

### Clinic Staff / Receptionists

Clinic staff will use the system to:

- Register pet owners
- Register pets
- Search existing pet records
- Update basic pet information
- Manage basic appointment/follow-up information

## 4.3 Administrative Users

### Administrators

Administrators will:

- Manage branches
- Manage staff accounts
- Assign user roles
- Control access permissions
- Manage system-level configuration

## 4.4 Future Users

### Pet Owners

A future version may allow pet owners to:

- View their pets
- View vaccination history
- View prescriptions
- Receive reminders
- Access medical documents

Pet-owner-facing functionality is not required for the initial MVP unless specifically added to scope.

---

# 5. Stakeholders

| Stakeholder | Role | Interest |
|---|---|---|
| Veterinarians | Primary users | Access and update medical records |
| Clinic Staff | Secondary users | Register and maintain pet information |
| Clinic Managers | Business stakeholders | Improve continuity and clinic operations |
| Pet Owners | End users | Ensure continuity of their pet's healthcare |
| Administrators | System owners | Manage users, branches, and permissions |
| Development Team | Product builders | Design, build, test, and maintain the application |

### Launch Approvers

The following named individuals must provide sign-off before the MVP is launched:

| Approver | Name | Required Sign-off |
|---|---|---|
| Product Owner | **[Name to be confirmed]** | Product scope, acceptance criteria, and launch readiness |
| Clinical/Veterinary Lead | **[Name to be confirmed]** | Veterinary workflow, medical-record fields, and clinical usability |
| Technical Lead | **[Name to be confirmed]** | Architecture, security, data migration, and production readiness |
| Clinic Operations Lead | **[Name to be confirmed]** | Branch workflow, staff adoption, and operational readiness |

No production launch should proceed until all required approvers have explicitly signed off.

---

# 6. Business Impact

## Operational Impact

A centralized record system reduces the need for branches to maintain isolated medical histories and allows veterinarians to retrieve previous information without relying entirely on manually shared records.

## Healthcare Workflow Impact

Veterinarians can review previous treatments, prescriptions, vaccinations, and notes before making decisions during a consultation.

## User Experience Impact

Pet owners do not need to repeatedly explain or carry their pet's complete medical history when visiting another branch.

## Data Continuity

Medical records remain associated with the pet rather than being isolated to the branch where the record was originally created.

---

# 7. Proposed Solution

PetCore will maintain a centralized digital profile for every registered pet.

Each pet will have a unique record containing:

- Owner information
- Basic pet information
- Medical history
- Vaccination history
- Treatment history
- Prescriptions
- Consultation notes
- Follow-up information
- Medical documents

Authorized users from different branches can access the same pet record according to their assigned permissions.

### High-Level Flow

```text
Pet Owner
    |
    v
Clinic Staff / Veterinarian
    |
    v
Search Pet
    |
    v
Centralized Pet Profile
    |
    +--> Vaccination History
    |
    +--> Treatment History
    |
    +--> Prescriptions
    |
    +--> Consultation Notes
    |
    +--> Follow-ups
    |
    +--> Medical Documents
```

---

# 8. Core User Journey

## 8.1 New Pet Registration

```text
Pet Owner visits clinic
        |
        v
Staff registers owner
        |
        v
Staff registers pet
        |
        v
Unique Pet ID created
        |
        v
Pet medical record created
        |
        v
Veterinarian records consultation
        |
        v
Treatment / vaccination / prescription recorded
```

## 8.2 Existing Pet Visiting Another Branch

```text
Pet Owner visits another branch
        |
        v
Veterinarian / Staff searches Pet
        |
        v
Existing Pet Record Found
        |
        v
Medical History Reviewed
        |
        v
New Consultation Recorded
        |
        v
Central Record Updated
        |
        v
Updated history available to authorized branches
```

---

# 9. Functional Requirements

## FR-01 — User Authentication

The system shall allow authorized users to securely log in.

Authentication shall use Firebase Authentication.

The system shall support user roles such as:

- Administrator
- Veterinarian
- Clinic Staff

---

## FR-02 — Role-Based Access Control

The system shall restrict actions according to the user's role.

| Feature | Admin | Veterinarian | Staff |
|---|---:|---:|---:|
| Login | Yes | Yes | Yes |
| Register Pet | Yes | Yes | Yes |
| View Medical History | Yes | Yes | Yes |
| Add Consultation | Yes | Yes | No |
| Add Treatment | Yes | Yes | No |
| Add Vaccination | Yes | Yes | No |
| Add Prescription | Yes | Yes | No |
| Upload Medical Document | Yes | Yes | No |
| Manage Users | Yes | No | No |
| Manage Branches | Yes | No | No |

---

# 10. Pet Management

Authorized staff shall be able to create and maintain pet profiles.

### Pet Profile Fields

- Pet ID
- Pet name
- Species
- Breed
- Gender
- Date of birth / approximate age
- Weight
- Color
- Owner ID
- Profile image
- Registration date
- Associated branch

---

# 11. Owner Management

The system shall maintain owner information.

### Owner Fields

- Owner ID
- Name
- Phone number
- Email
- Address
- Registered pets

One owner may have multiple pets.

```text
OWNER
  |
  +-- PET
  |
  +-- PET
  |
  +-- PET
```

---

# 12. Pet Search

Authorized users shall be able to search for an existing pet.

### Search Options

- Pet ID
- Pet name
- Owner phone number
- Owner name

For the MVP, Pet ID and owner phone number should be prioritized.

### Search Flow

```text
Search Pet
    |
    v
Matching Results
    |
    v
Select Pet
    |
    v
Pet Profile
    |
    v
Medical History
```

---

# 13. Medical History

The medical history is the core feature of PetCore.

Each pet shall have a chronological history of relevant medical events.

### Medical Record

A medical record may contain:

- Date
- Record type
- Symptoms
- Diagnosis
- Treatment
- Medication
- Dosage
- Veterinarian
- Branch
- Notes
- Follow-up date
- Attached documents

### Example

```text
Bruno
--------------------------------

12 Sep 2026
Vaccination
Rabies Vaccine
Dr. Sharma
Branch A

05 Aug 2026
Treatment
Skin Infection
Medication prescribed
Dr. Singh
Branch B

20 Jul 2026
Consultation
Fever and lethargy
Dr. Sharma
Branch A
```

---

# 14. Vaccination Management

Veterinarians shall be able to record vaccinations.

### Vaccination Fields

- Vaccine name
- Date administered
- Next due date
- Dosage
- Veterinarian
- Branch
- Notes

The next due date will allow the system to support future vaccination reminders.

---

# 15. Treatment Management

Veterinarians shall be able to create treatment records.

### Treatment Fields

- Date
- Symptoms
- Diagnosis
- Treatment provided
- Medication
- Dosage
- Duration
- Veterinarian
- Branch
- Notes
- Follow-up date

---

# 16. Prescription Management

Veterinarians shall be able to create prescriptions associated with consultations.

### Prescription Fields

- Medicine name
- Dosage
- Frequency
- Duration
- Instructions
- Date
- Veterinarian
- Branch

Historical prescriptions shall remain associated with the pet's medical history.

---

# 17. Consultation Management

Veterinarians shall be able to create a consultation record.

### Consultation Fields

- Consultation date
- Pet
- Veterinarian
- Branch
- Symptoms
- Diagnosis
- Clinical notes
- Treatment
- Prescription
- Follow-up date
- Attachments

---

# 18. Medical Document Management

Authorized users shall be able to upload relevant medical documents.

Examples include:

- Blood reports
- X-ray reports
- Lab reports
- Prescription images
- Medical certificates
- Other relevant veterinary documents

Files shall be stored using Firebase Storage.

Document metadata shall be stored in Cloud Firestore.

---

# 19. Branch Management

Every medical record shall be associated with the branch where it was created.

### Branch Information

- Branch ID
- Branch name
- Address
- Contact information
- Active/inactive status

Each record should identify:

- Branch
- Veterinarian
- Creation date

This provides traceability across the clinic network.

---

# 20. Dashboard

The veterinarian dashboard should provide quick access to commonly used functions.

### Dashboard Information

- Today's consultations
- Upcoming follow-ups
- Vaccinations due
- Recently viewed pets

### Quick Actions

- Search Pet
- Register Pet
- New Consultation
- Add Vaccination
- Add Treatment

---

# 21. Follow-Up Tracking

Veterinarians shall be able to specify a follow-up date when creating a consultation or treatment record.

The system should display upcoming follow-ups.

Example:

```text
Upcoming Follow-ups

Bruno
Skin infection review
Due: 20 Sep 2026

Milo
Post-surgery check
Due: 24 Sep 2026
```

---

# 22. Notifications

The MVP may display upcoming vaccination and follow-up information inside the application.

Push notifications can be considered as a future enhancement.

---

# 23. User Stories

## US-01

As a veterinarian, I want to search for a pet using its unique ID, so that I can access its medical history before starting treatment.

## US-02

As a veterinarian, I want to view previous treatments, so that I can make the current consultation with awareness of the pet's treatment history.

## US-03

As a veterinarian, I want to view vaccination history and due dates, so that I can identify upcoming or missed vaccinations.

## US-04

As a veterinarian, I want to add consultation notes, so that the next authorized veterinarian can understand the pet's previous condition and treatment.

## US-05

As clinic staff, I want to register a new pet and associate it with its owner, so that the pet can be uniquely identified and its future medical records can be linked to the correct owner.

## US-06

As a veterinarian, I want to upload medical reports, so that relevant diagnostic information remains available across branches.

## US-07

As an administrator, I want to manage staff accounts and roles, so that only authorized users can access sensitive records.

## US-08

As a clinic manager, I want medical records to show the branch and veterinarian that created them, so that records remain traceable across the clinic network.

---

# 24. MVP Scope

## In Scope — V1

- Firebase Authentication
- User roles
- Branch management
- Owner registration
- Pet registration
- Unique Pet ID
- Pet search
- Centralized medical history
- Vaccination records
- Treatment records
- Consultation notes
- Prescription records
- Follow-up dates
- Medical document uploads
- Veterinarian dashboard
- Firebase Storage integration
- Firestore database
- Existing-record migration planning and validation

## Out of Scope — V1

- Online payments
- Video consultations
- AI diagnosis
- AI-generated prescriptions
- Pharmacy management
- Inventory management
- Insurance processing
- Billing/accounting
- Advanced analytics
- Wearable device integration
- External veterinary-system integration
- Multi-language support
- Advanced push notification system

Future features may be moved into the V2 backlog.

---

# 25. Non-Functional Requirements

## Performance

- Main screens should load within approximately 2–3 seconds under normal network conditions.
- Pet searches should return results quickly enough to support a consultation workflow.
- Medical history should be displayed without unnecessary navigation.

## Security

- Firebase Authentication shall handle user authentication.
- Firestore Security Rules shall restrict database access.
- Firebase Storage Security Rules shall restrict medical documents.
- Users shall only perform actions permitted by their role.
- Sensitive medical records shall not be publicly accessible.

## Availability

The application should provide access to records whenever an authorized user has an internet connection and Firebase services are available.

## Usability

The primary workflow should be simple:

```text
Search Pet
    ->
Open Pet
    ->
Review History
    ->
Add Consultation
```

---

# 26. Technical Architecture

```text
                    Flutter App
                         |
              +----------+----------+
              |                     |
              v                     v
      Firebase Authentication   Cloud Firestore
              |                     |
              |              +------+------+
              |              |             |
              |              v             v
              |           Pet Data    Medical Records
              |                           |
              |                           |
              +---------------------------+
                          |
                          v
                  Firebase Storage
                          |
                          v
                Medical Documents
```

### Technology Responsibilities

| Requirement | Technology |
|---|---|
| Application UI | Flutter |
| Application language | Dart |
| User authentication | Firebase Auth |
| User sessions | Firebase Auth |
| Pet records | Cloud Firestore |
| Owner records | Cloud Firestore |
| Branch records | Cloud Firestore |
| Medical records | Cloud Firestore |
| Vaccination records | Cloud Firestore |
| Prescription records | Cloud Firestore |
| Medical files | Firebase Storage |
| Application execution | Emulator / Device |

---

# 27. Firestore Data Model

A proposed Firestore structure:

```text
users/
  {userId}
    - name
    - email
    - role
    - branchId
    - createdAt

branches/
  {branchId}
    - name
    - address
    - contact
    - status

owners/
  {ownerId}
    - name
    - phone
    - email
    - address
    - createdAt

pets/
  {petId}
    - name
    - species
    - breed
    - gender
    - dob
    - weight
    - color
    - ownerId
    - imageUrl
    - createdAt

pets/{petId}/medical_records/
  {recordId}
    - type
    - symptoms
    - diagnosis
    - treatment
    - notes
    - veterinarianId
    - branchId
    - createdAt
    - followUpDate

pets/{petId}/vaccinations/
  {vaccinationId}
    - vaccineName
    - administeredDate
    - nextDueDate
    - dosage
    - veterinarianId
    - branchId
    - notes

pets/{petId}/prescriptions/
  {prescriptionId}
    - medicine
    - dosage
    - frequency
    - duration
    - instructions
    - veterinarianId
    - branchId
    - createdAt

pets/{petId}/documents/
  {documentId}
    - fileName
    - fileUrl
    - uploadedBy
    - branchId
    - uploadedAt
```

---

# 28. Data Flow

```text
User
 |
 v
Flutter Application
 |
 +--------------------+
 |                    |
 v                    v
Firebase Auth      Firestore
 |                    |
 |              Pet & Medical
 |                  Records
 |                    |
 +---------+----------+
           |
           v
    Authorized Branch
       Access

Flutter Application
        |
        v
Firebase Storage
        |
        v
Medical Documents
```

---

# 29. KPIs and Success Metrics

The current problem statement does not provide baseline measurements. Therefore, the following are proposed product targets and should be validated during testing or a pilot.

| KPI | Measurement Method | Initial Target | Timeline |
|---|---|---:|---|
| Pet record retrieval | Percentage of successful searches | ≥95% | Pilot |
| Pet search time | Time from search to record display | ≤10 seconds | Pilot |
| Cross-branch record access | Successful authorized access attempts | ≥95% | Pilot |
| Required record completion | Percentage of records with required fields | ≥90% | First 30 days |
| Authentication success | Successful login attempts | ≥98% | Testing |
| Vaccination due-date coverage | Vaccination records containing due dates where applicable | ≥90% | First 30 days |

These targets are project targets, not measurements of the current clinic process.

---

# 30. Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Unauthorized access to medical records | Medium | High | Firebase Auth, RBAC, and Security Rules |
| Wrong pet selected during consultation | Medium | High | Unique Pet ID and owner verification |
| Duplicate pet profiles | Medium | Medium | Search existing records before registration |
| Internet unavailable | Medium | High | Clear connection/error states; consider offline support later |
| Incorrect medical information entered | Medium | High | Required fields and confirmation before saving |
| Firebase usage/cost increases | Low | Medium | Monitor usage and optimize reads/storage |
| Unsupported uploaded files | Low | Medium | File type and size restrictions |
| Low staff adoption | Medium | Medium | Simple workflow and onboarding |

---

# 31. Data Migration

Existing branch-level pet and medical records must be accounted for before PetCore is launched.

### Migration Requirements

- Identify all existing record sources used by each branch.
- Determine which existing records are eligible for migration into PetCore.
- Define a common data format for owner, pet, vaccination, treatment, prescription, consultation, and document records.
- Map existing branch records to the PetCore owner, pet, branch, and medical-record structures.
- Resolve duplicate pet and owner records before importing them.
- Preserve the original branch association and available historical dates for migrated records.
- Validate migrated records against the source records before they become available for clinical use.
- Record migration status and exceptions for records that cannot be migrated automatically.
- Maintain a backup or read-only copy of the original records during the migration and validation period.
- Complete migration validation and obtain the required sign-off before relying on migrated records in production.

### Migration Acceptance Criteria

The migration is considered ready when:

- Existing branch data sources have been inventoried.
- Migration mappings have been reviewed and approved.
- Duplicate and conflicting records have a documented resolution process.
- A test migration has been completed successfully.
- Migrated records have been sampled and reconciled against their source records.
- Migration exceptions are documented and assigned for resolution.
- The Product Owner, Clinical/Veterinary Lead, Technical Lead, and Clinic Operations Lead have approved the migration for launch.

---

# 31. Assumptions

The project currently assumes:

1. Each pet can have a unique identifier.
2. Clinic branches have internet connectivity.
3. Authorized staff will use individual accounts.
4. Staff will enter medical information digitally.
5. Firebase services are suitable for the project's intended requirements.
6. Users have smartphones or compatible devices.
7. Branches belong to the same clinic organization and can share records under appropriate authorization.

These assumptions should be validated before or during implementation.

---

# 32. Future Enhancements

Potential future versions may include:

- Pet-owner mobile portal
- Push notifications
- Automated vaccination reminders
- Appointment booking
- Online payments
- Pharmacy management
- Inventory management
- Advanced reporting
- Analytics dashboard
- Multi-language support
- Offline-first functionality
- External veterinary system integrations
- AI-assisted record summarization

These features should remain outside the MVP unless the project scope is formally expanded.

---

# 33. Definition of Done

The MVP will be considered complete when:

- [ ] Users can securely log in.
- [ ] User roles are implemented.
- [ ] Branches can be associated with users.
- [ ] Staff can register owners.
- [ ] Staff can register pets.
- [ ] Each pet has a unique identifier.
- [ ] Authorized users can search for pets.
- [ ] Authorized users can view medical history.
- [ ] Veterinarians can add consultations.
- [ ] Veterinarians can add treatments.
- [ ] Veterinarians can add vaccinations.
- [ ] Veterinarians can create prescriptions.
- [ ] Follow-up dates can be recorded.
- [ ] Medical documents can be uploaded.
- [ ] Records show the responsible veterinarian and branch.
- [ ] Authorized users from another branch can access records.
- [ ] Unauthorized users cannot access restricted records.
- [ ] Data persists correctly in Firebase.
- [ ] Existing branch records included in the migration scope are migrated and validated.
- [ ] Migration exceptions are documented and assigned for resolution.
- [ ] Required launch approvers have signed off.
- [ ] The primary search-to-history-to-consultation workflow works on a physical device or emulator.

---

# 34. MVP Success Scenario

A successful MVP should support the following scenario:

> A pet named Bruno visits Branch A and receives treatment for a skin condition. The veterinarian records the consultation, treatment, medication, and follow-up date in PetCore. Two weeks later, Bruno visits Branch B. The veterinarian at Branch B searches for Bruno using the Pet ID, immediately accesses the previous treatment and prescription, reviews the follow-up information, and records the new consultation. The updated record becomes available to other authorized branches.

This demonstrates the core value proposition of the product: **continuity of veterinary medical records across branches.**

---

# 35. Product Definition

> **PetCore is a centralized veterinary health-record platform that enables authorized clinic staff across branches to access and update a pet's medical history, supporting continuity of care and reducing dependence on fragmented branch-level records.**
