# Property Setup Quick Start Guide

## Overview
You've successfully identified a critical missing feature! The app needs properties to function, but there was no way to create them on the device. I've now added complete property management functionality.

## What's New

### 1. **Property Add/Edit Screen** (`property_add_edit_screen.dart`)
- Complete form for creating and editing properties
- QR code generation and scanning
- Links to buildings and customers
- Inspection frequency settings
- Site contact information
- Access notes and alarm codes

### 2. **Updated Property List** (`property_list_screen.dart`)
- Add new properties with the + button
- Search functionality
- Long-press for options menu
- Edit existing properties
- Activate/deactivate properties
- Shows device count and last inspection

### 3. **Building Management** (`building_list_screen.dart`)
- Simple interface to add/edit buildings
- Required before creating properties
- Stores building name and address

### 4. **Customer Management** (`customer_list_screen.dart`)
- Add/edit customer companies
- Contact information
- Also required before creating properties

## Setup Steps on Your iPhone

### Step 1: Create a Customer
1. Open the app and go to Properties screen
2. Tap the menu (⋮) in the top right
3. Select "Manage Customers"
4. Tap the + button
5. Enter customer details:
   - Company Name (required)
   - Contact Name
   - Phone
   - Email
   - Billing Address
6. Tap "Add"

### Step 2: Create a Building
1. From the Properties screen menu (⋮)
2. Select "Manage Buildings"
3. Tap the + button
4. Enter building details:
   - Building Name (required)
   - Address
   - City, State, ZIP
5. Tap "Add"

### Step 3: Create a Property
1. From the Properties screen, tap the + button
2. Fill in the form:
   - Select the Building you created
   - Select the Customer you created
   - Property Name (optional)
   - Account Number (optional)
   - QR Code (auto-generated)
   - Inspection settings
3. Tap "Create Property"

### Step 4: Start an Inspection
1. From the Properties list, tap on your new property
2. This will start a new inspection
3. Complete the inspection workflow as before

## Key Features

### QR Code Management
- Automatically generates unique codes
- Format: `FAS-XXXXXXXX` (8 random characters)
- Can scan existing codes with camera
- Regenerate button if needed

### Property Status
- Active/Inactive toggle
- Inactive properties shown in grey
- Can't start inspections on inactive properties

### Search & Filter
- Search by property name, building, customer, or account number
- Real-time filtering as you type

### Offline Support
- All property management works offline
- Syncs automatically when online
- Uses the same BaseRepository pattern

## Testing Checklist

- [ ] Create at least one customer
- [ ] Create at least one building  
- [ ] Create a property linking both
- [ ] Edit the property details
- [ ] Start an inspection on the new property
- [ ] Deactivate and reactivate a property
- [ ] Test the search functionality
- [ ] Verify data persists after app restart

## Common Issues

### "Please select a building/customer"
You must create at least one building and one customer before creating properties.

### QR Code Already Exists
The system prevents duplicate QR codes. Use the regenerate button (🔄) to get a new one.

### Property Not Showing
Make sure the property is marked as Active. Inactive properties appear greyed out.

## Next Steps

Once you have properties set up:
1. Add devices to your properties (coming next)
2. Run full inspections
3. Generate PDF reports
4. Test sync functionality

## Code Integration

The new files need to be added to your project:
1. `lib/screens/properties/property_add_edit_screen.dart`
2. `lib/screens/properties/building_list_screen.dart`
3. `lib/screens/properties/customer_list_screen.dart`
4. Update `lib/screens/properties/property_list_screen.dart`

Make sure to import them properly in your navigation.

## Technical Notes

- All new screens follow the existing patterns
- Use BaseRepository for automatic sync
- Soft deletes maintained
- Form validation included
- Error handling throughout
- Works completely offline