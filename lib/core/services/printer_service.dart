import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aconita_mart_pos/data/models/order.dart';

class BluetoothDevice {
  final String name;
  final String address;

  BluetoothDevice({required this.name, required this.address});
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // SharedPreferences keys
  static const String _keyPrinterMac = 'printer_mac';
  static const String _keyPrinterName = 'printer_name';
  static const String _keyPaperSize = 'paper_size';

  String? _connectedAddress;
  String? _connectedName;
  String _paperSize = '58'; // default 58mm

  bool get isConnected => _connectedAddress != null;
  String? get connectedDeviceName => _connectedName;
  String? get connectedDeviceAddress => _connectedAddress;
  String get paperSize => _paperSize;

  /// Initialize printer service - load saved settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedAddress = prefs.getString(_keyPrinterMac);
    _connectedName = prefs.getString(_keyPrinterName);
    _paperSize = prefs.getString(_keyPaperSize) ?? '58';

    // Try to reconnect to saved printer
    if (_connectedAddress != null && _connectedAddress!.isNotEmpty) {
      await connect(BluetoothDevice(
        name: _connectedName ?? 'Unknown',
        address: _connectedAddress!,
      ));
    }
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    final isAvailable = await PrintBluetoothThermal.bluetoothEnabled;
    return isAvailable;
  }

  /// Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    final List<BluetoothInfo> devices =
        await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map((d) => BluetoothDevice(name: d.name, address: d.macAdress))
        .toList();
  }

  /// Connect to device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
      if (result) {
        _connectedAddress = device.address;
        _connectedName = device.name;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyPrinterMac, device.address);
        await prefs.setString(_keyPrinterName, device.name);
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _connectedAddress = null;
    _connectedName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterMac);
    await prefs.remove(_keyPrinterName);
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    if (_connectedAddress == null) {
      final prefs = await SharedPreferences.getInstance();
      _connectedAddress = prefs.getString(_keyPrinterMac);
      _connectedName = prefs.getString(_keyPrinterName);
      if (_connectedAddress == null) return false;
    }

    final status = await PrintBluetoothThermal.connectionStatus;
    return status;
  }

  /// Get saved printer info
  Future<Map<String, String?>> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mac': prefs.getString(_keyPrinterMac),
      'name': prefs.getString(_keyPrinterName),
    };
  }

  /// Try to reconnect to saved printer
  Future<bool> reconnectSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString(_keyPrinterMac);
    final savedName = prefs.getString(_keyPrinterName);

    if (savedMac == null || savedMac.isEmpty) return false;

    final currentStatus = await PrintBluetoothThermal.connectionStatus;
    if (currentStatus) {
      _connectedAddress = savedMac;
      _connectedName = savedName;
      return true;
    }

    return await connect(BluetoothDevice(
      name: savedName ?? 'Printer',
      address: savedMac,
    ));
  }

  /// Set paper size ('58' or '80')
  Future<void> setPaperSize(String size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaperSize, size);
  }

  /// Get saved paper size
  Future<String> getSavedPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPaperSize) ?? '58';
  }

  /// Get PaperSize enum from string
  PaperSize getPaperSizeEnum() {
    return _paperSize == '80' ? PaperSize.mm80 : PaperSize.mm58;
  }

  /// Ensure printer is connected, try to reconnect if needed
  Future<bool> ensureConnected() async {
    final prefs = await SharedPreferences.getInstance();
    _paperSize = prefs.getString(_keyPaperSize) ?? '58';

    if (await checkConnection()) {
      return true;
    }

    return await reconnectSavedPrinter();
  }

  /// Print order receipt
  Future<bool> printReceipt(Order order) async {
    if (!await ensureConnected()) {
      throw Exception('Printer tidak terhubung. Silakan hubungkan printer di Pengaturan.');
    }

    try {
      final bytes = await _generateOrderReceiptBytes(order);
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception('Gagal mencetak: ');
    }
  }

  /// Print test page
  Future<bool> printTest() async {
    if (!await ensureConnected()) {
      throw Exception('Printer tidak terhubung. Silakan hubungkan printer di Pengaturan.');
    }

    try {
      final bytes = await _generateTestBytes();
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception('Gagal mencetak: ');
    }
  }

  Future<List<int>> _generateOrderReceiptBytes(Order order) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(getPaperSizeEnum(), profile);
    List<int> bytes = [];

    final fCurrency = NumberFormat('#,###', 'id_ID');
    final fDate = DateFormat('dd/MM/yyyy HH:mm');

    bytes += generator.text(
      'ACONITA MART',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Koperasi Karyawan & Konsumen',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.row([
      PosColumn(text: 'No: ' + order.orderNo, width: 12),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Waktu: ' + fDate.format(order.orderDate), width: 12),
    ]);
    if (order.memberName != null && order.memberName!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Anggota: ' + order.memberName!, width: 12),
      ]);
    }
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    for (final item in order.items) {
      bytes += generator.row([
        PosColumn(text: item.productName, width: 12, styles: const PosStyles(bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(text: item.quantity.toString() + ' x Rp ' + fCurrency.format(item.unitPrice), width: 7),
        PosColumn(
          text: 'Rp ' + fCurrency.format(item.subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.row([
      PosColumn(text: 'Total:', width: 6),
      PosColumn(
        text: 'Rp ' + fCurrency.format(order.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    if (order.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon/Potongan:', width: 6),
        PosColumn(
          text: '-Rp ' + fCurrency.format(order.discountAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Bayar (' + order.paymentMethod.toUpperCase() + '):', width: 6),
      PosColumn(
        text: 'Rp ' + fCurrency.format(order.paidAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (order.changeAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Kembali:', width: 6),
        PosColumn(
          text: 'Rp ' + fCurrency.format(order.changeAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima Kasih Atas Belanja Anda',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Maju Bersama Anggota Koperasi',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> _generateTestBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(getPaperSizeEnum(), profile);
    List<int> bytes = [];

    bytes += generator.text(
      'ACONITA MART POS',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Printer Test OK',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Paper Size: ' + _paperSize + 'mm',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
