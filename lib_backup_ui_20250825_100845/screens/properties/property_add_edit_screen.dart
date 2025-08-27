// lib/screens/properties/property_add_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/barcode_scanner_service.dart';

class PropertyAddEditScreen extends StatefulWidget {
  final Property? property;
  final int? buildingId;
  final int? customerId;
  
  const PropertyAddEditScreen({
    super.key,
    this.property,
    this.buildingId,
    this.customerId,
  });

  @override
  State<PropertyAddEditScreen> createState() => _PropertyAddEditScreenState();
}

class _PropertyAddEditScreenState extends State<PropertyAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyRepository _propertyRepo = PropertyRepository();
  final BuildingRepository _buildingRepo = BuildingRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _specificLocationController = TextEditingController();
  final _monitoringOrgController = TextEditingController();
  final _monitoringPhoneController = TextEditingController();
  final _monitoringEmailController = TextEditingController();
  final _phoneLine1Controller = TextEditingController();
  final _phoneLine2Controller = TextEditingController();
  final _controlUnitManufacturerController = TextEditingController();
  final _controlUnitModelController = TextEditingController();
  final _firmwareRevisionController = TextEditingController();
  final _disconnectingMeansLocationController = TextEditingController();
  final _qrCodeController = TextEditingController();
  
  // Dropdown selections
  Building? _selectedBuilding;
  Customer? _selectedCustomer;
  String _transmissionMeans = 'DACT';
  String _primaryVoltage = '120VAC';
  int _primaryAmps = 20;
  String _overcurrentProtectionType = 'Breaker';
  int _overcurrentAmps = 20;
  
  // Lists for dropdowns
  List<Building> _buildings = [];
  List<Customer> _customers = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _specificLocationController.dispose();
    _monitoringOrgController.dispose();
    _monitoringPhoneController.dispose();
    _monitoringEmailController.dispose();
    _phoneLine1Controller.dispose();
    _phoneLine2Controller.dispose();
    _controlUnitManufacturerController.dispose();
    _controlUnitModelController.dispose();
    _firmwareRevisionController.dispose();
    _disconnectingMeansLocationController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load buildings and customers
      final buildings = await _buildingRepo.getAll();
      final customers = await _customerRepo.getAll();
      
      setState(() {
        _buildings = buildings;
        _customers = customers;
      });
      
      // If editing, populate form
      if (widget.property != null) {
        _populateForm(widget.property!);
      } else {
        // Set defaults for new property
        if (widget.buildingId != null) {
          _selectedBuilding = _buildings.firstWhere(
            (b) => b.id == widget.buildingId,
            orElse: () => _buildings.first,
          );
        }
        if (widget.customerId != null) {
          _selectedCustomer = _customers.firstWhere(
            (c) => c.id == widget.customerId,
            orElse: () => _customers.first,
          );
        }
        
        // Generate QR code for new property
        _qrCodeController.text = await _propertyRepo.generateUniqueQrCode();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _populateForm(Property property) {
    _nameController.text = property.name;
    _accountNumberController.text = property.accountNumber ?? '';
    _specificLocationController.text = property.specificLocation ?? '';
    _monitoringOrgController.text = property.monitoringOrg ?? '';
    _monitoringPhoneController.text = property.monitoringPhone ?? '';
    _monitoringEmailController.text = property.monitoringEmail ?? '';
    _phoneLine1Controller.text = property.phoneLine1 ?? '';
    _phoneLine2Controller.text = property.phoneLine2 ?? '';
    _controlUnitManufacturerController.text = property.controlUnitManufacturer ?? '';
    _controlUnitModelController.text = property.controlUnitModel ?? '';
    _firmwareRevisionController.text = property.firmwareRevision ?? '';
    _disconnectingMeansLocationController.text = property.disconnectingMeansLocation ?? '';
    _qrCodeController.text = property.qrCode ?? '';
    
    _transmissionMeans = property.transmissionMeans;
    _primaryVoltage = property.primaryVoltage;
    _primaryAmps = property.primaryAmps;
    _overcurrentProtectionType = property.overcurrentProtectionType;
    _overcurrentAmps = property.overcurrentAmps;
    
    // Set selected building and customer
    if (property.buildingId != null) {
      _selectedBuilding = _buildings.firstWhere(
        (b) => b.id == property.buildingId,
        orElse: () => _buildings.first,
      );
    }
    if (property.customerId != null) {
      _selectedCustomer = _customers.firstWhere(
        (c) => c.id == property.customerId,
        orElse: () => _customers.first,
      );
    }
  }

  Future<void> _scanQrCode() async {
    try {
      final scannedCode = await BarcodeScannerService.scanBarcode(
        context: context,
        title: 'Scan QR Code',
        instructionText: 'Scan the property QR code',
      );
      if (scannedCode != null) {
        setState(() {
          _qrCodeController.text = scannedCode;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: $e')),
      );
    }
  }

  Future<void> _generateNewQrCode() async {
    try {
      final newCode = await _propertyRepo.generateUniqueQrCode();
      setState(() {
        _qrCodeController.text = newCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New QR code generated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating QR code: $e')),
      );
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check required relationships
    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a building')),
      );
      return;
    }
    
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Check if QR code is unique (if changed)
      if (widget.property == null || widget.property!.qrCode != _qrCodeController.text) {
        final exists = await _propertyRepo.qrCodeExists(_qrCodeController.text);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This QR code is already in use')),
          );
          setState(() => _isSaving = false);
          return;
        }
      }
      
      final property = Property(
        id: widget.property?.id,
        buildingId: _selectedBuilding!.id,
        customerId: _selectedCustomer!.id,
        name: _nameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isNotEmpty ? _accountNumberController.text.trim() : null,
        specificLocation: _specificLocationController.text.trim().isNotEmpty ? _specificLocationController.text.trim() : null,
        qrCode: _qrCodeController.text.trim(),
        monitoringOrg: _monitoringOrgController.text.trim().isNotEmpty ? _monitoringOrgController.text.trim() : null,
        monitoringPhone: _monitoringPhoneController.text.trim().isNotEmpty ? _monitoringPhoneController.text.trim() : null,
        monitoringEmail: _monitoringEmailController.text.trim().isNotEmpty ? _monitoringEmailController.text.trim() : null,
        phoneLine1: _phoneLine1Controller.text.trim().isNotEmpty ? _phoneLine1Controller.text.trim() : null,
        phoneLine2: _phoneLine2Controller.text.trim().isNotEmpty ? _phoneLine2Controller.text.trim() : null,
        transmissionMeans: _transmissionMeans,
        controlUnitManufacturer: _controlUnitManufacturerController.text.trim().isNotEmpty ? _controlUnitManufacturerController.text.trim() : null,
        controlUnitModel: _controlUnitModelController.text.trim().isNotEmpty ? _controlUnitModelController.text.trim() : null,
        firmwareRevision: _firmwareRevisionController.text.trim().isNotEmpty ? _firmwareRevisionController.text.trim() : null,
        primaryVoltage: _primaryVoltage,
        primaryAmps: _primaryAmps,
        overcurrentProtectionType: _overcurrentProtectionType,
        overcurrentAmps: _overcurrentAmps,
        disconnectingMeansLocation: _disconnectingMeansLocationController.text.trim().isNotEmpty ? _disconnectingMeansLocationController.text.trim() : null,
        createdAt: widget.property?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (widget.property == null) {
        await _propertyRepo.insert(property);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property created successfully')),
          );
        }
      } else {
        await _propertyRepo.update(property);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated successfully')),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving property: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving property: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.property == null ? 'New Property' : 'Edit Property'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? 'New Property' : 'Edit Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Property Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Property name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Building>(
                      value: _selectedBuilding,
                      decoration: const InputDecoration(
                        labelText: 'Building *',
                        border: OutlineInputBorder(),
                      ),
                      items: _buildings.map((building) {
                        return DropdownMenuItem(
                          value: building,
                          child: Text(building.buildingName ?? 'Unnamed Building'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBuilding = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a building';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                      ),
                      items: _customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer,
                          child: Text(customer.companyName ?? 'Unnamed Customer'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a customer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specificLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Specific Location',
                        border: OutlineInputBorder(),
                        helperText: 'e.g., 3rd Floor Electrical Room',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // QR Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qrCodeController,
                      decoration: InputDecoration(
                        labelText: 'QR Code *',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanQrCode,
                              tooltip: 'Scan QR Code',
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _generateNewQrCode,
                              tooltip: 'Generate New Code',
                            ),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'QR code is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Monitoring Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monitoringOrgController,
                      decoration: const InputDecoration(
                        labelText: 'Monitoring Organization',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monitoringPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Monitoring Phone',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monitoringEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Monitoring Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneLine1Controller,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Line 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneLine2Controller,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Line 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _transmissionMeans,
                      decoration: const InputDecoration(
                        labelText: 'Transmission Means',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'DACT', child: Text('DACT')),
                        DropdownMenuItem(value: 'Internet', child: Text('Internet')),
                        DropdownMenuItem(value: 'Cellular', child: Text('Cellular')),
                        DropdownMenuItem(value: 'Radio', child: Text('Radio')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _transmissionMeans = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Control Unit Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control Unit Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controlUnitManufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controlUnitModelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firmwareRevisionController,
                      decoration: const InputDecoration(
                        labelText: 'Firmware Revision',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Power Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _primaryVoltage,
                            decoration: const InputDecoration(
                              labelText: 'Primary Voltage',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '120VAC', child: Text('120VAC')),
                              DropdownMenuItem(value: '240VAC', child: Text('240VAC')),
                              DropdownMenuItem(value: '277VAC', child: Text('277VAC')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _primaryVoltage = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _primaryAmps.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Primary Amps',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _primaryAmps = int.tryParse(value) ?? 20;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _overcurrentProtectionType,
                            decoration: const InputDecoration(
                              labelText: 'Overcurrent Protection',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Breaker', child: Text('Breaker')),
                              DropdownMenuItem(value: 'Fuse', child: Text('Fuse')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _overcurrentProtectionType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _overcurrentAmps.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Overcurrent Amps',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _overcurrentAmps = int.tryParse(value) ?? 20;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _disconnectingMeansLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Disconnecting Means Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProperty,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.property == null ? 'Create Property' : 'Update Property'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}