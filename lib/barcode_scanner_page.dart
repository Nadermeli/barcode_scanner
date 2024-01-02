import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String scannedBarcode = '';
  late Database database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    database = await openDatabase(
      join(await getDatabasesPath(), 'barcode_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE barcodes(code TEXT PRIMARY KEY, productName TEXT, productPrice REAL)',
        );
      },
      version: 1,
    );
  }

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        scannedBarcode = result.rawContent;
      });

      // Check if the barcode exists in the local database
      bool barcodeExists = await checkBarcodeInDatabase(scannedBarcode);

      if (barcodeExists) {
        // If barcode exists, display information
        fetchAndDisplayInformation(scannedBarcode);
      } else {
        // If barcode doesn't exist, ask the user to add details
        bool userWantsToAddDetails = await showAddDetailsDialog();

        if (userWantsToAddDetails) {
          // Add logic to handle user input for product name and price
          await addProductDetails(scannedBarcode);
        }
      }
    } catch (e) {
      print('Error scanning barcode: $e');
    }
  }

  Future<bool> checkBarcodeInDatabase(String barcode) async {
    try {
      List<Map<String, dynamic>> result = await database.query(
        'barcodes',
        where: 'code = ?',
        whereArgs: [barcode],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking barcode in database: $e');
      return false;
    }
  }

  Future<void> fetchAndDisplayInformation(String barcode) async {
    try {
      List<Map<String, dynamic>> result = await database.query(
        'barcodes',
        where: 'code = ?',
        whereArgs: [barcode],
      );

      if (result.isNotEmpty) {
        String productName =
            result[0]['productName'] ?? 'Product Name not available';
        double productPrice = result[0]['productPrice'] ?? 0.0;

        // Display the information (implement your own UI logic)
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Product Information'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Name: $productName'),
                  Text('Product Price: \$${productPrice.toStringAsFixed(2)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        print('Record not found in the database');
      }
    } catch (e) {
      print('Error fetching information from database: $e');
    }
  }

  Future<void> addProductDetails(String barcode) async {
    // Show a dialog to get user input for product name and price
    String productName = await showInputDialog('Enter product name');
    double productPrice =
        await showInputDialog('Enter product price', isPrice: true);

    // Save the details to the local database
    try {
      await database.insert('barcodes', {
        'code': barcode,
        'productName': productName,
        'productPrice': productPrice,
      });

      showToast('Product details added successfully!');
    } catch (e) {
      print('Error adding product details to database: $e');
    }
  }

  Future<String> showInputDialog(String title, {bool isPrice = false}) async {
    TextEditingController inputController = TextEditingController();
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: inputController,
            keyboardType: isPrice ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(inputController.text);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> showAddDetailsDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Barcode Not Found'),
          content: Text('Do you want to add details for this barcode?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // User doesn't want to add details
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User wants to add details
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scanned Barcode:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              scannedBarcode,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanBarcode,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
