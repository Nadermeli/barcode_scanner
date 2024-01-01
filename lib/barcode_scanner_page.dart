import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String scannedBarcode = '';

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        scannedBarcode = result.rawContent;
      });

      // Check if the barcode exists in Firestore
      bool barcodeExists = await checkBarcodeInFirestore(scannedBarcode);

      if (barcodeExists) {
        // If barcode exists, display information in a toast
        showToast('Barcode found! Displaying information...');
        // Add logic to fetch and display information from Firestore if needed
      } else {
        // If barcode doesn't exist, ask the user to add details
        bool userWantsToAddDetails = await showAddDetailsDialog();

        if (userWantsToAddDetails) {
          // Add logic to handle user input for product name and price
          // and save it to Firestore
        }
      }
    } catch (e) {
      print('Error scanning barcode: $e');
    }
  }

  Future<bool> checkBarcodeInFirestore(String barcode) async {
    try {
      var query = await FirebaseFirestore.instance
          .collection('barcodes')
          .where('code', isEqualTo: barcode)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking barcode in Firestore: $e');
      return false;
    }
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
    // Add logic to display a toast message
    // You can use a package like fluttertoast or implement your own toast widget
    print(message);
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
