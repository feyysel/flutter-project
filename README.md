Ride Sharing Mobile Application

Project Overview

Ride Sharing Mobile Application is a Flutter and Firebase based transportation platform that connects passengers with drivers traveling between cities.

The system allows drivers to post rides, passengers to book available rides, and both parties to communicate through a real-time booking workflow.

The application supports authentication, driver verification, ride management, booking management, earnings tracking, trip history, profile management, and notification support.

---

Technologies Used

Frontend

- Flutter
- Dart

Backend

- Supabase Authentication
- Supabase Storage
- supabase messaging

---

User Roles

The application contains two user roles:

Passenger

Passengers can:

- Register and login
- Search available rides
- Book rides
- Cancel booking before driver acceptance
- View ride activity
- View accepted ride details
- Edit profile information

Driver

Drivers can:

- Register and login
- Verify identity documents
- Post rides
- Manage ride requests
- Accept or decline passenger bookings
- Complete rides
- View earnings
- View ride history
- Edit profile information

---

Authentication System

The application uses Firebase Authentication.

Features:

- User Registration
- User Login
- Role-Based Authentication
- Forgot Password Support
- Session Persistence

Roles are stored in Firestore and used to determine whether a user accesses driver screens or passenger screens.

---

Driver Verification System

Before becoming a verified driver, users submit verification documents.

Required information:

- Profile Photo URL
- Vehicle Plate Number
- Vehicle Front Photo URL
- National ID Front URL
- National ID Back URL
- Driver License URL

Verification data is stored in Firestore.

---

Driver Verification Status

The system supports four verification states:

Not Verified

Driver has not submitted documents.

Under Review

Documents have been submitted and are awaiting approval.

Document Rejected

Verification was reviewed and rejected.

Verified

Driver is approved and allowed to provide rides.

Only verified drivers are allowed to post rides.

---

Ride Posting System

Verified drivers can create ride posts containing:

- Departure Location
- Destination
- Date
- Time
- Available Seats
- Price
- Driver Information

Ride posts are stored in Firestore and displayed in passenger ride listings.

---

Passenger Ride Booking System

Passengers can:

- Browse available rides
- Select a ride
- Send booking request

A booking request creates a document inside:

ride_requests

with status:

pending

---

Ride Request Workflow

Step 1 — Passenger Requests Ride

Status:
pending

Driver receives booking request.

---

Step 2 — Driver Decision

Driver may:

- Accept
- Decline

Status becomes:

accepted

or

declined

---

Step 3 — Ride Completion

After trip completion:

Status becomes:

completed

Ride information is copied into:

ride_history

collection.

---

Real-Time Ride Management

The application uses Firestore Streams.

Updates occur instantly when:

- New booking arrives
- Driver accepts ride
- Driver declines ride
- Ride is completed
- Driver updates status

No manual refresh is required.

---

Activity Screen Features

Passenger Activity

Passengers can view:

- Pending Requests
- Accepted Requests
- Completed Rides
- Driver Information

---

Driver Activity

Drivers can view:

- Incoming Requests
- Accepted Rides
- Passenger Information
- Completed Trips

---

Accepted Ride Connection Details

After acceptance:

Passenger Can See

- Driver Name
- Driver Phone Number
- Vehicle Plate Number

Driver Can See

- Passenger Name
- Passenger Phone Number

This information becomes visible only after the driver accepts the request.

---

Profile Management

Both drivers and passengers can edit:

- Name
- Phone Number
- Profile Image URL

Changes are saved directly to Firestore.

---

Driver Profile Dashboard

The driver dashboard displays:

Total Trips

Automatically calculated from completed rides.

Years Driving

Calculated from account age.

Acceptance Rate

Calculated using:

Accepted Requests / (Accepted Requests + Declined Requests)

---

Earnings System

Drivers can view:

- Total Earnings
- Ride Income
- Completed Trip Revenue

Earnings are updated from completed rides.

---

Trip History

Completed rides are stored permanently.

Both driver and passenger can review previous rides.

Stored information includes:

- Origin
- Destination
- Price
- Driver
- Passenger
- Completion Date

---

Notifications System

The project is prepared for Firebase Cloud Messaging.

Planned notifications:

Driver Notifications

- New booking request received

Passenger Notifications

- Ride accepted
- Ride completed

Notification tokens are stored inside user documents.

---

Database Structure

users

Stores:

- uid
- name
- email
- phone
- role
- profileImage
- verificationStatus
- plateNumber
- notificationToken

---

rides

Stores:

- rideId
- driverId
- driverName
- from
- to
- date
- time
- seats
- price
- status

---

ride_requests

Stores:

- passengerId
- passengerName
- passengerPhone
- driverId
- driverName
- from
- to
- status

---

ride_history

Stores:

- ride information
- completion date
- passenger data
- driver data

---

Security Features

- Firebase Authentication
- Role-based access
- Driver verification process
- Firestore cloud storage
- Protected user data

---

Current Application Status

Implemented Features:

✓ Registration

✓ Login

✓ Role Selection

✓ Forgot Password

✓ Driver Verification

✓ Verification Status Tracking

✓ Ride Posting

✓ Ride Booking

✓ Ride Acceptance

✓ Ride Completion

✓ Ride History

✓ Earnings Screen

✓ Driver Dashboard Statistics

✓ Passenger Activity

✓ Driver Activity

✓ Profile Editing

✓ Real-Time Firestore Updates

✓ Firebase Integration

---

Future Improvements

- Google Authentication
- Push Notifications
- Live Driver Location
- In-App Chat
- Ride Rating System
- Driver Reviews
- Payment Integration
- Map Integration
- Admin Dashboard
- Driver Verification Approval Panel
- Dark/Light Theme Support

---

Conclusion

The Ride Sharing Mobile Application provides a complete ride booking and management platform using Flutter and Firebase. The system supports secure authentication, driver verification, ride management, passenger booking, real-time updates, profile management, and trip tracking, creating a scalable foundation for a production-ready transportation service.
