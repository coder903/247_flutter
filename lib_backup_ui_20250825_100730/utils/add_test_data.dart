// lib/utils/add_test_data.dart

import '../database/database_helper.dart';
import '../repositories/repositories.dart';
import '../models/models.dart';

class TestDataGenerator {
  static Future<void> addTestData() async {
    final buildingRepo = BuildingRepository();
    final customerRepo = CustomerRepository();
    final propertyRepo = PropertyRepository();
    final deviceRepo = DeviceRepository();
    
    try {
      // Add test building
      final building = await buildingRepo.insert(Building(
        buildingName: 'Oakwood Business Center',
        buildingCode: 'OBC-001',
        address: '123 Main Street',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94105',
        buildingType: 'Commercial',
        floors: 5,
        units: 20,
        accessNotes: 'Gate code: 1234#',
        contactName: 'John Manager',
        contactPhone: '415-555-0100',
      ));
      
      // Add test customer
      final customer = await customerRepo.insert(Customer(
        companyName: 'Acme Properties LLC',
        contactName: 'Jane Smith',
        email: 'jane@acmeproperties.com',
        phone: '415-555-0200',
        billingAddress: '456 Corporate Blvd',
        billingCity: 'San Francisco',
        billingState: 'CA',
        billingZip: '94105',
        portalAccess: true,
      ));
      
      // Add test properties
      final property1 = await propertyRepo.insert(Property(
        name: 'Building A - Main Panel',
        buildingId: building.id,
        customerId: customer.id,
        specificLocation: '1st Floor Electrical Room',
        accountNumber: 'ACM-001-A',
        monitoringOrg: 'SafeWatch Monitoring',
        monitoringPhone: '800-555-0300',
        controlUnitManufacturer: 'Notifier',
        controlUnitModel: 'NFS-320',
        primaryVoltage: '120VAC',
        primaryAmps: 20,
      ));
      
      final property2 = await propertyRepo.insert(Property(
        name: 'Building B - Secondary Panel',
        buildingId: building.id,
        customerId: customer.id,
        specificLocation: '3rd Floor Electrical Closet',
        accountNumber: 'ACM-001-B',
        monitoringOrg: 'SafeWatch Monitoring',
        monitoringPhone: '800-555-0300',
        controlUnitManufacturer: 'Simplex',
        controlUnitModel: '4100ES',
        primaryVoltage: '120VAC',
        primaryAmps: 15,
      ));
      
      // Add some devices to property1
      await deviceRepo.insert(Device(
        barcode: '24604830',
        propertyId: property1.id!,
        deviceTypeId: 5, // Horn/Strobe
        manufacturerId: 1, // System Sensor
        modelNumber: 'PC2PW',
        installationDate: DateTime(2020, 5, 15),
        locationDescription: '1st Floor Hallway - North',
        addressNum: '101',
      ));
      
      await deviceRepo.insert(Device(
        barcode: '24604831',
        propertyId: property1.id!,
        deviceTypeId: 1, // Smoke Detector
        manufacturerId: 2, // Bosch
        modelNumber: 'D273',
        installationDate: DateTime(2019, 3, 10),
        locationDescription: '2nd Floor Conference Room',
        addressNum: '201',
      ));
      
      print('Test data added successfully!');
      print('Buildings: 1');
      print('Customers: 1');
      print('Properties: 2');
      print('Devices: 2');
      
    } catch (e) {
      print('Error adding test data: $e');
    }
  }
  
  static Future<void> clearAllData() async {
    final db = await DatabaseHelper.instance.database;
    
    // Clear all data tables (in reverse order of dependencies)
    await db.delete('component_tests');
    await db.delete('battery_tests');
    await db.delete('service_tickets');
    await db.delete('inspections');
    await db.delete('devices');
    await db.delete('properties');
    await db.delete('customers');
    await db.delete('buildings');
    await db.delete('sync_queue');
    
    print('All data cleared!');
  }
}