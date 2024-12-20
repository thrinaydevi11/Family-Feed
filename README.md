# FAMILY FEED

## TABLE OF CONTENT
1.Overview

2.Product Spec

3.Wireframes

4.Schema

## Overview

FamilyFeed is an iOS application that helps users manage and organize their family members' information, including personal details, birth charts, and important dates. Built with SwiftUI and Parse Backend, it provides secure user authentication and efficient data management.

## 1. Product Overview
```
Product Name: FamilyFeed
Platform: iOS (SwiftUI)
Backend: Parse Server (Back4App)
Authentication: Email/Password
Data Storage: Parse + Cloud Storage
```
## 2 Features
### 2.1 Authentication
```
User Management:
├── Registration
│   ├── Username
│   ├── Email
│   ├── Password
│   └── Full Name
└── Login
    ├── Username/Email
    └── Password

Session Handling:
├── Auto-login
├── Secure logout
└── Error handling
```

### 2.2 Family Member Management
```
Member Information:
├── Basic Details
│   ├── Name
│   ├── Relationship
│   ├── Date of Birth
│   └── Birth Place
├── Birth Chart
│   ├── Upload from camera
│   ├── Upload from gallery
│   └── View/Display
└── Important Dates
    ├── Add dates
    ├── Categorize (Birthday, Anniversary, etc.)
    └── Enable reminders
```
##3. Technical Implementation
### 3.1 Models
```
User Model:
├── objectId: String
├── username: String
├── email: String
├── password: String
└── fullName: String

FamilyMember Model:
├── objectId: String
├── userId: String
├── name: String
├── relationship: String
├── dateOfBirth: Date
├── birthPlace: String
├── birthChart: String?
└── importantDates: [ImportantDate]?

ImportantDate Model:
├── id: String
├── date: Date
├── description: String
├── category: DateCategory
└── reminder: Bool
```

### 3.2 ViewModels
```
AuthViewModel:
├── User Management
│   ├── signUp()
│   ├── login()
│   └── signOut()
└── State Management
    ├── currentUser
    ├── errorMessage
    └── isLoading

FamilyMembersViewModel:
├── Data Operations
│   ├── fetchFamilyMembers()
│   ├── addFamilyMember()
│   ├── updateMember()
│   └── deleteMember()
├── Image Handling
│   ├── uploadBirthChart()
│   └── handleImageSelection()
└── Date Management
    ├── addImportantDate()
    ├── removeImportantDate()
    └── getUpcomingDates()
```
### 3.3 Views
```
Main Views:
├── ContentView
├── LaunchScreenView
├── AuthView
│   ├── LoginView
│   └── SignUpView
└── MainView
    └── FamilyMemberDetailView

Supporting Views:
├── ImagePicker
├── LocationSearchView
└── Custom Components
    ├── DetailRow
    └── EditableDetailRow
```

## 4. Data Schema

### 4.1Users Table
```
Fields:
├── objectId (String, Primary Key)
├── username (String, Unique)
├── email (String, Unique)
├── password (String, Encrypted)
└── fullName (String)
```

### 4.2FamilyMembers Table
```
Fields:
├── objectId (String, Primary Key)
├── userId (String, Foreign Key)
├── name (String)
├── relationship (String)
├── dateOfBirth (Date)
├── birthPlace (String)
├── birthChart (String, Optional)
├── importantDates (Array)
└── ACL (Parse ACL)
```

## 5. Key Features Implementation
### 5.1 Location Search
```
Components:
├── LocationSearchService
│   ├── MKLocalSearchCompleter
│   └── Worldwide search
├── LocationSearchView
│   ├── Search suggestions
│   └── Place selection
└── Integration
    └── Birth place selection
```
### 5.2 Image Handling
```
Features:
├── Source Selection
│   ├── Camera
│   └── Photo Library
├── Processing
│   ├── Compression
│   └── Size validation
└── Storage
    ├── Parse File
    └── URL management
```

## 6. Security Requirements
```
Data Protection:
├── User Authentication
├── ACL Implementation
└── Private Data Access

File Security:
├── Secure Upload
└── Protected Storage
```

## 7. Future Enhancements
```
Planned Features:
├── Family Tree Visualization
├── Event Notifications
├── Data Export/Import
├── Family Member Sharing
└── Advanced Search
```

## WIREFRAMES
![IMG_2065](https://github.com/user-attachments/assets/0633499d-d50c-48b4-b57b-dfcf789ef13e)

### FIGMA Digital Wire Frame LINKS
https://www.figma.com/design/CPbO0hsA3dxLu5n8svh14e/Project-WireFrame?node-id=0-1&m=dev&t=8RHlyY6hT1gP8MqN-1

https://www.figma.com/proto/CPbO0hsA3dxLu5n8svh14e/Project-WireFrame?node-id=0-1&t=8RHlyY6hT1gP8MqN-1

## SCHEMA

### USER TABLE

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| objectId | String | PRIMARY KEY, AUTO-GEN | Unique identifier |
| username | String | UNIQUE, NOT NULL | User's username |
| email | String | UNIQUE, NOT NULL | User's email address |
| password | String | NOT NULL | Encrypted password |
| emailVerified | Boolean | DEFAULT false | Email verification status |
| createdAt | DateTime | AUTO-GEN | Account creation timestamp |
| updatedAt | DateTime | AUTO-GEN | Last update timestamp |

### Table 2: FamilyMembers
| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| objectId | String | PRIMARY KEY, AUTO-GEN | Unique identifier |
| userId | String | FOREIGN KEY (Users) | Reference to user |
| name | String | NOT NULL | Family member's name |
| relation | String | NOT NULL | Relationship type |
| image | File | NULL | Profile photo |
| dateAdded | DateTime | AUTO-GEN | Member addition date |
| createdAt | DateTime | AUTO-GEN | Record creation date |
| updatedAt | DateTime | AUTO-GEN | Last update timestamp |
| notes | String | NULL | Additional notes |
| birthDate | DateTime | NULL | Birth date |

### Table 3: ContactInfo (Embedded in FamilyMembers)
| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| phone | String | NULL | Contact phone number |
| email | String | NULL | Contact email |
| address | String | NULL | Physical address |

### Indexes
| Table | Column(s) | Type | Description |
|-------|-----------|------|-------------|
| Users | email | UNIQUE | Fast email lookups |
| Users | username | UNIQUE | Fast username lookups |
| FamilyMembers | userId | INDEX | Quick user filtering |
| FamilyMembers | name | INDEX | Name search optimization |

### Relationships
| Parent Table | Child Table | Relationship Type | Description |
|-------------|-------------|-------------------|-------------|
| Users | FamilyMembers | One-to-Many | User owns multiple family members |

## GIF
![Final Project gif](https://github.com/user-attachments/assets/d8c1ffb7-37e7-4c65-bf47-50417e1a4cd5)

##  video Representation

[https://youtu.be/5ucCnvAuR7c](https://youtu.be/Wfn2W2wOu6g)
