import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  Future<void> fetchAndDisplayInformation(String barcode) async {
    try {
      var document = await FirebaseFirestore.instance
          .collection('barcodes')
          .doc(barcode)
          .get();

      if (document.exists) {
        String productName =
            document['productName'] ?? 'Product Name not available';
        double productPrice = document['productPrice'] ?? 0.0;

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
        print('Document does not exist');
        // Handle the case where the document does not exist
      }
    } catch (e) {
      print('Error fetching information from Firestore: $e');
    }
  }

  Future<void> addProductDetails(String barcode) async {
    // Show a dialog to get user input for product name and price
    String productName = await showInputDialog('Enter product name');
    double productPrice =
        await showInputDialog('Enter product price', isPrice: true);

    // Save the details to Firestore
    try {
      await FirebaseFirestore.instance.collection('barcodes').doc(barcode).set({
        'code': barcode,
        'productName': productName,
        'productPrice': productPrice,
      });

      showToast('Product details added successfully!');
    } catch (e) {
      print('Error adding product details to Firestore: $e');
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
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
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
