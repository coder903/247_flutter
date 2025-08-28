// lib/services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/inspection.dart';
import '../models/alarm_panel.dart';
import '../models/battery_test.dart';
import '../models/component_test.dart';
import '../models/device.dart';
import '../models/building.dart';
import '../models/customer.dart';
import '../repositories/inspection_repository.dart';
import '../repositories/battery_test_repository.dart';
import '../repositories/component_test_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/alarm_panel_repository.dart';
import '../repositories/building_repository.dart';
import '../repositories/customer_repository.dart';
import '../database/database_helper.dart';

class PDFService {
  static final PDFService instance = PDFService._init();
  PDFService._init();

  final _inspectionRepo = InspectionRepository();
  final _batteryRepo = BatteryTestRepository();
  final _componentRepo = ComponentTestRepository();
  final _deviceRepo = DeviceRepository();
  final _alarmPanelRepo = AlarmPanelRepository();
  final _buildingRepo = BuildingRepository();
  final _customerRepo = CustomerRepository();
  final _db = DatabaseHelper.instance;

  /// Generate comprehensive inspection report
  Future<File> generateInspectionReport(int inspectionId) async {
    // Fetch all necessary data
    final inspection = await _inspectionRepo.getById(inspectionId);
    if (inspection == null) throw Exception('Inspection not found');

    final property = await _alarmPanelRepo.getById(inspection.alarmPanelId);
    if (property == null) throw Exception('Property not found');

    final building = property.buildingId != null 
        ? await _buildingRepo.getById(property.buildingId!)
        : null;

    Customer? customer;

    if (property.customerId != null) {
      customer = await _customerRepo.getById(property.customerId!);
    }
    if (customer == null) throw Exception('Customer not found');

    if (property.customerId != null) {
      final customer = await _customerRepo.getById(property.customerId!);
    }

    if (customer == null) throw Exception('Customer not found');

    final batteryTests = await _batteryRepo.getByInspection(inspectionId);
    final componentTests = await _componentRepo.getByInspection(inspectionId);
    
    // Get devices for component tests
    final deviceMap = <int, Device>{};
    for (final test in componentTests) {
      if (!deviceMap.containsKey(test.deviceId)) {
        final device = await _deviceRepo.getById(test.deviceId);
        if (device != null) {
          deviceMap[device.id!] = device;
        }
      }
    }

    // Create PDF document
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
      ),
    );

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, customer, building),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildCoverPage(inspection, property, customer, building),
          pw.SizedBox(height: 20),
          _buildInspectionSummary(inspection, batteryTests, componentTests),
          pw.SizedBox(height: 20),
          if (batteryTests.isNotEmpty) ...[
            _buildBatteryTestSection(batteryTests),
            pw.SizedBox(height: 20),
          ],
          if (componentTests.isNotEmpty) ...[
            _buildComponentTestSection(componentTests, deviceMap),
            pw.SizedBox(height: 20),
          ],
          _buildDefectsSection(inspection, batteryTests, componentTests, deviceMap),
          pw.SizedBox(height: 40),
          _buildCertificationSection(inspection),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'inspection_${inspection.inspectionDate.toString().split(' ')[0]}_${property.name.replaceAll(' ', '_')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildHeader(pw.Context context, dynamic customer, dynamic building) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fire Alarm Inspection Report', 
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (building != null)
                pw.Text('${building.buildingName}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey400)),
      ),
      child: pw.Text(
        'Generated on ${DateTime.now().toString().split('.')[0]}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildCoverPage(
    Inspection inspection,
    dynamic property,
    dynamic customer,
    dynamic building,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'FIRE ALARM SYSTEM\nINSPECTION REPORT',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 40),
        _buildInfoSection('Property Information', [
          ['Property Name:', property.name],
          ['Building:', building?.buildingName ?? 'N/A'],
          ['Address:', building?.address ?? 'N/A'],
          ['City/State/ZIP:', '${building?.city ?? ''}, ${building?.state ?? ''} ${building?.zipCode ?? ''}'],
        ]),
        pw.SizedBox(height: 20),
        _buildInfoSection('Customer Information', [
          ['Company:', customer.companyName],
          ['Contact:', customer.contactName ?? 'N/A'],
          ['Phone:', customer.phone ?? 'N/A'],
          ['Email:', customer.email ?? 'N/A'],
        ]),
        pw.SizedBox(height: 20),
        _buildInfoSection('System Information', [
          ['Panel Manufacturer:', property.panelManufacturer ?? 'N/A'],
          ['Panel Model:', property.panelModel ?? 'N/A'],
          ['Monitoring Company:', property.monitoringCompany ?? 'N/A'],
          ['Account Number:', property.monitoringAccountNumber ?? 'N/A'],
        ]),
        pw.SizedBox(height: 20),
        _buildInfoSection('Inspection Details', [
          ['Inspection Date:', inspection.inspectionDate.toString().split(' ')[0]],
          ['Inspection Type:', inspection.inspectionType ?? 'Annual'],
          ['Inspector:', inspection.inspectorName ?? 'Unknown'],
          ['Panel Temperature:', '${inspection.panelTemperatureF ?? 'N/A'}°F'],
        ]),
      ],
    );
  }

  pw.Widget _buildInfoSection(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, 
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Table.fromTextArray(
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(5),
          columnWidths: {
            0: const pw.FixedColumnWidth(150),
            1: const pw.FlexColumnWidth(),
          },
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 12),
          border: null,
        ),
      ],
    );
  }

  pw.Widget _buildInspectionSummary(
    Inspection inspection,
    List<BatteryTest> batteryTests,
    List<ComponentTest> componentTests,
  ) {
    final batteryPassed = batteryTests.where((t) => t.passed == true).length;
    final batteryFailed = batteryTests.where((t) => t.passed == false).length;
    
    final componentPassed = componentTests.where((t) => t.testResult == 'Pass').length;
    final componentFailed = componentTests.where((t) => t.testResult == 'Fail').length;
    final componentNotTested = componentTests.where((t) => t.testResult == 'Not Tested').length;

    final overallPass = batteryFailed == 0 && componentFailed == 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INSPECTION SUMMARY', 
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryBox(
                  'Overall Result',
                  overallPass ? 'PASS' : 'FAIL',
                  overallPass ? PdfColors.green : PdfColors.red,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildSummaryBox(
                  'Status',
                  inspection.isComplete ? 'COMPLETE' : 'IN PROGRESS',
                  inspection.isComplete ? PdfColors.blue : PdfColors.orange,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text('Test Results:', 
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.all(5),
            headers: ['Test Type', 'Total', 'Passed', 'Failed', 'Not Tested'],
            data: [
              ['Batteries', '${batteryTests.length}', '$batteryPassed', '$batteryFailed', '0'],
              ['Components', '${componentTests.length}', '$componentPassed', '$componentFailed', '$componentNotTested'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 12),
            border: pw.TableBorder.all(width: 1),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 5),
          pw.Text(value, 
            style: pw.TextStyle(
              fontSize: 16, 
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBatteryTestSection(List<BatteryTest> tests) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('BATTERY TEST RESULTS', 
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          cellAlignment: pw.Alignment.center,
          cellPadding: const pw.EdgeInsets.all(5),
          headers: [
            'Position',
            'Barcode',
            'Rated\n(AH)',
            'Current\n(A)',
            'Min Req\n(A)',
            'Voltage\n(V)',
            'Temp\n(°F)',
            'Result',
          ],
          data: tests.map((test) => [
            test.position ?? 'N/A',
            test.barcode ?? 'N/A',
            test.ratedAmpHours.toString(),
            test.currentReading.toStringAsFixed(2),
            test.minCurrentRequired?.toStringAsFixed(2) ?? 'N/A',
            test.voltageReading?.toStringAsFixed(2) ?? 'N/A',
            test.temperatureF?.toStringAsFixed(1) ?? 'N/A',
            test.passed == true ? 'PASS' : 'FAIL',
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
          cellStyle: const pw.TextStyle(fontSize: 10),          
          border: pw.TableBorder.all(width: 1),
        ),
      ],
    );
  }

  pw.Widget _buildComponentTestSection(
    List<ComponentTest> tests,
    Map<int, Device> deviceMap,
  ) {
    // Group tests by device type
    final testsByType = <String, List<ComponentTestWithDevice>>{};
    
    for (final test in tests) {
      final device = deviceMap[test.deviceId];
      if (device != null) {
        final typeName = device.deviceTypeName ?? 'Unknown';
        testsByType.putIfAbsent(typeName, () => []);
        testsByType[typeName]!.add(ComponentTestWithDevice(test, device));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('COMPONENT TEST RESULTS', 
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...testsByType.entries.map((entry) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(entry.key, 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            _buildDeviceTypeTable(entry.key, entry.value),
            pw.SizedBox(height: 15),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildDeviceTypeTable(String deviceType, List<ComponentTestWithDevice> tests) {
    // Customize table based on device type
    List<String> headers;
    List<List<String>> data;

    switch (deviceType) {
      case 'Fire Extinguisher':
        headers = ['Barcode', 'Location', 'Size', 'Serviced', 'Hydro', 'Result'];
        data = tests.map((ctd) => [
          ctd.device.barcode ?? 'N/A',
          ctd.device.locationDescription ?? 'N/A',
          ctd.test.size ?? 'N/A',
          ctd.test.servicedDate?.toString().split(' ')[0] ?? 'N/A',
          ctd.test.hydroDate?.toString().split(' ')[0] ?? 'N/A',
          ctd.test.testResult ?? 'N/A',
        ]).toList();
        break;
      
      case 'Smoke Detector':
      case 'Heat Detector':
        headers = ['Barcode', 'Location', 'Sensitivity', 'Result', 'Notes'];
        data = tests.map((ctd) => [
          ctd.device.barcode ?? 'N/A',
          ctd.device.locationDescription ?? 'N/A',
          ctd.test.sensitivity ?? 'N/A',
          ctd.test.testResult ?? 'N/A',
          ctd.test.notes ?? '',
        ]).toList();
        break;
      
      case 'Horn/Strobe':
      case 'Horn':
      case 'Strobe':
        headers = ['Barcode', 'Location', 'Decibel Level', 'Result', 'Notes'];
        data = tests.map((ctd) => [
          ctd.device.barcode ?? 'N/A',
          ctd.device.locationDescription ?? 'N/A',
          ctd.test.decibelLevel ?? 'N/A',
          ctd.test.testResult ?? 'N/A',
          ctd.test.notes ?? '',
        ]).toList();
        break;
      
      case 'Emergency Light':
        headers = ['Barcode', 'Location', '24hr Check', 'Result', 'Notes'];
        data = tests.map((ctd) => [
          ctd.device.barcode ?? 'N/A',
          ctd.device.locationDescription ?? 'N/A',
          ctd.test.check24hrPost == true ? 'Yes' : 'No',
          ctd.test.testResult ?? 'N/A',
          ctd.test.notes ?? '',
        ]).toList();
        break;
      
      default:
        headers = ['Barcode', 'Location', 'Result', 'Notes'];
        data = tests.map((ctd) => [
          ctd.device.barcode ?? 'N/A',
          ctd.device.locationDescription ?? 'N/A',
          ctd.test.testResult ?? 'N/A',
          ctd.test.notes ?? '',
        ]).toList();
    }

    return pw.Table.fromTextArray(
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellStyle: const pw.TextStyle(fontSize: 10),      
      border: pw.TableBorder.all(width: 1),
    );
  }

  pw.Widget _buildDefectsSection(
    Inspection inspection,
    List<BatteryTest> batteryTests,
    List<ComponentTest> componentTests,
    Map<int, Device> deviceMap,
  ) {
    final failedBatteries = batteryTests.where((t) => t.passed == false).toList();
    final failedComponents = componentTests.where((t) => t.testResult == 'Fail').toList();

    if (failedBatteries.isEmpty && failedComponents.isEmpty && (inspection.defects?.isEmpty ?? true)) {
      return pw.SizedBox();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEFECTS & FAILED ITEMS', 
            style: pw.TextStyle(
              fontSize: 16, 
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            )),
          pw.SizedBox(height: 10),
          
          if (failedBatteries.isNotEmpty) ...[
            pw.Text('Failed Batteries:', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            ...failedBatteries.map((battery) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
              child: pw.Text('• ${battery.position ?? 'Unknown'} - Current: ${battery.currentReading}A (Min: ${battery.minCurrentRequired}A)'),
            )),
            pw.SizedBox(height: 10),
          ],
          
          if (failedComponents.isNotEmpty) ...[
            pw.Text('Failed Components:', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            ...failedComponents.map((test) {
              final device = deviceMap[test.deviceId];
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                child: pw.Text('• ${device?.deviceTypeName ?? 'Unknown'} - ${device?.locationDescription ?? 'Unknown location'} - ${test.notes ?? 'No notes'}'),
              );
            }),
            pw.SizedBox(height: 10),
          ],
          
          if (inspection.defects?.isNotEmpty ?? false) ...[
            pw.Text('Additional Defects/Notes:', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Text(inspection.defects!),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCertificationSection(Inspection inspection) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CERTIFICATION', 
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
            'I certify that the fire alarm system at the above location has been inspected in accordance with NFPA 72 and local requirements. All deficiencies noted above must be corrected to bring the system into compliance.',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Inspector Signature:', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1)),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Text(inspection.inspectorName ?? 'Unknown', style: const pw.TextStyle(fontSize: 12)),

                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 50),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date:', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1)),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Text(
                          inspection.completionDatetime?.toString().split(' ')[0] ?? 
                          inspection.inspectionDate.toString().split(' ')[0],
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Share PDF report
  Future<void> shareReport(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'Fire Alarm Inspection Report',
    );
  }

  /// Save PDF to permanent storage
  Future<File> savePermanently(File tempFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final permanentPath = '${directory.path}/reports/$fileName';
    
    // Create reports directory if it doesn't exist
    final reportsDir = Directory('${directory.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    
    // Copy file to permanent location
    return await tempFile.copy(permanentPath);
  }

  /// Queue PDF for upload when online
  Future<void> queueForUpload(File pdfFile, int inspectionId) async {
    final db = await _db.database;
    
    // Add to sync queue
    await db.insert('sync_queue', {
      'operation_type': 'UPLOAD_PDF',
      'table_name': 'inspection_reports',
      'record_id': inspectionId,
      'record_data': pdfFile.path,
      'priority': 8,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get all saved reports
  Future<List<File>> getSavedReports() async {
    final directory = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${directory.path}/reports');
    
    if (!await reportsDir.exists()) {
      return [];
    }
    
    final files = reportsDir.listSync()
        .where((entity) => entity is File && entity.path.endsWith('.pdf'))
        .map((entity) => entity as File)
        .toList();
    
    // Sort by modified date, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    return files;
  }
  
  /// Delete report
  Future<void> deleteReport(File reportFile) async {
    if (await reportFile.exists()) {
      await reportFile.delete();
    }
  }
}

// Helper class to combine test and device data
class ComponentTestWithDevice {
  final ComponentTest test;
  final Device device;
  
  ComponentTestWithDevice(this.test, this.device);
}