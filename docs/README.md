# alarm_tool

Project Structure
lib/
├── main.dart
├── config/
│   ├── app_config.dart
│   ├── themes.dart
│   └── constants.dart
├── models/
│   ├── building.dart
│   ├── customer.dart
│   ├── property.dart
│   ├── device.dart
│   ├── inspection.dart
│   ├── battery_test.dart
│   ├── component_test.dart
│   ├── service_ticket.dart
│   └── sync_status.dart
├── database/
│   ├── database_helper.dart
│   ├── tables/
│   │   └── schema.dart
│   └── sync/
│       ├── sync_manager.dart
│       └── sync_queue.dart
├── services/
│   ├── api_service.dart
│   ├── barcode_service.dart
│   ├── photo_service.dart
│   ├── offline_queue_service.dart
│   └── auth_service.dart
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── auth/
│   │   └── login_screen.dart
│   ├── buildings/
│   ├── devices/
│   ├── inspections/
│   └── sync/
├── widgets/
│   ├── common/
│   │   └── app_drawer.dart
│   └── forms/
│       ├── battery_test_form.dart
│       └── device_form.dart
└── utils/
    ├── validators.dart
    ├── battery_calculator.dart
    └── formatters.dart

---- Status
Here's a prompt for the next conversation:

---

# Fire Inspection Flutter App - Continuation

## Project Status
I'm building a Flutter app for fire alarm inspection with offline SQLite storage that syncs with a PostgreSQL/Flask backend. The app is for technicians to inspect fire safety devices in buildings, with barcode scanning, photo capture, and automatic pass/fail calculations (especially for batteries using the 85% rule).

## Completed Work
1. **Project Setup**: Flutter project configured with all dependencies (sqflite, camera, barcode scanner, etc.)
2. **Database**: SQLite schema created matching Flask models, with tables for buildings, devices, inspections, battery tests, service tickets, and sync queue
3. **Basic UI**: Login screen and home dashboard with 4 main modes (Site Survey, Inspection, Service Tickets, Reports)
4. **Authentication**: Basic auth service with dummy login (needs Flask API integration)
5. **Core Utilities**: Battery calculator for 85% rule, validators, themes

## Project Files in Knowledge Base
- Complete Flutter project structure uploaded
- Flask backend views.py for API reference
- Meeting transcript with requirements
- Database models from Flask backend
- Project outline with detailed requirements

## Three Main Workflows Needed
1. **Site Survey Mode**: Walk building → Add devices → Scan/apply barcodes → Take photos
2. **Inspection Mode**: Select property → Test devices → Auto-calculate battery pass/fail → Generate reports
3. **Service Ticket Mode**: Create tickets from issues → Track parts → Document repairs

## Next Priority Tasks
1. **Create Data Models**: Building, Customer, Property, Device, Inspection, BatteryTest, ComponentTest, ServiceTicket models matching the SQLite schema
2. **Implement Site Survey Workflow**: 
   - Building/property selection screen
   - Device add/edit form with barcode scanner
   - Photo capture and local storage
3. **Build Inspection Workflow**:
   - Property list/selection
   - Battery test form with dropdown for amp-hours (7, 12, 18, 26, 35, etc.)
   - Auto-calculation of pass/fail
   - Device-specific test forms
4. **Offline Sync System**: Queue operations when offline, sync when connected
5. **API Integration**: Connect to Flask endpoints for data sync

## Key Technical Requirements
- Batteries pass if current reading ≥ 85% of rated amp-hours
- Store photos locally with GPS from EXIF
- Support pre-printed barcode scanning (8-12 digit numeric)
- Work completely offline, sync when online
- Three separate workflows for different inspection phases

The app is running successfully on macOS and can be deployed to phones. Ready to implement core functionality.

---

This prompt provides context for continuing development focusing on the data models and main workflows.
