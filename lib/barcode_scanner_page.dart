import 'dart:io';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

      // Check if the barcode exists on the server
      bool barcodeExists = await checkBarcodeOnServer(scannedBarcode);

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

  Future<bool> checkBarcodeOnServer(String barcode) async {
    try {
      var request = http.Request(
          'GET',
          Uri.parse(
              'https://barcode-nadermeli.000webhostapp.com/api.php?code=$barcode'));

      var response = await request.send();
      if (response.statusCode == 200) {
        Map<String, dynamic> result =
            json.decode(await response.stream.bytesToString());
        return result.containsKey('code');
      } else {
        print('Failed to check barcode on the server');
        return false;
      }
    } catch (e) {
      if (e is SocketException) {
        print(
            'Error: Unable to connect to the server. Please check your internet connection.');
      } else if (e is HttpException) {
        print('HTTP error occurred: $e');
      } else {
        print('Error checking barcode on the server: $e');
      }
      return false;
    }
  }

  Future<void> fetchAndDisplayInformation(String barcode) async {
    try {
      print(barcode);
      var request = http.Request(
          'GET',
          Uri.parse(
              'https://barcode-nadermeli.000webhostapp.com/api.php?code=$barcode'));

      var response = await request.send();

      if (response.statusCode == 200) {
        Map<String, dynamic> result =
            json.decode(await response.stream.bytesToString());
        print(result);
        String productName =
            result['productName'] ?? 'Product Name not available';
        double productPrice = double.parse(result['productPrice'] ?? 0.0);

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
        print('Failed to fetch information from the server');
      }
    } catch (e) {
      print('Error fetching information from the server: $e');
    }
  }

  Future<void> addProductDetails(String barcode) async {
    // Show a dialog to get user input for product name and price
    String productName = await showInputDialog('Enter product name');
    String productPrice =
        await showInputDialog('Enter product price', isPrice: true);

    // Save the details to the server
    try {
      var headers = {
        'Content-Type': 'application/json',
      };
      var request = http.Request(
          'GET',
          Uri.parse(
              'https://barcode-nadermeli.000webhostapp.com/api.php?newcode=$barcode&productName=$productName&productPrice=$productPrice'));

      var response = await request.send();
      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> result =
              json.decode(await response.stream.bytesToString());
          showToast(result['message']);
        } catch (e) {
          print('Error decoding JSON response: $e');
          showToast('Error decoding server response. Please try again.');
        }
      } else {
        print(
            'Failed to add product details to the server. Status code: ${response.statusCode}');
        showToast('Failed to add product details. Please try again.');
      }
    } catch (e) {
      print('Error adding product details to the server: $e');
      showToast('Error adding product details. Please try again.');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
