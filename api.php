<?php
header('Content-Type: application/json'); 

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
// MySQL database credentials
$host = 'localhost';
$user = 'id21769254_if0_35714126';
$password = 'Y3u-jkx4CNuQtCx';
$database = 'id21769254_if0_35714126_barcodescanner';

// Create a connection to MySQL
$connection = new mysqli($host, $user, $password, $database);

// Check the connection
if ($connection->connect_error) {
    die("Connection failed: " . $connection->connect_error);
}

// Function to check if a barcode exists in the database
function checkBarcode($code) {
    global $connection;
    
    $code = $connection->real_escape_string($code);

    $query = "SELECT * FROM barcodes WHERE code = '$code'";
    $result = $connection->query($query);

    return $result->num_rows > 0;
}

// Function to fetch information for a barcode
function fetchInformation($code) {
    global $connection;

    $code = $connection->real_escape_string($code);

    $query = "SELECT * FROM barcodes WHERE code = '$code'";
    $result = $connection->query($query);

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        return $row;
    } else {
        return null;
    }
}

// Function to add product details for a barcode
function addProductDetails($code, $productName, $productPrice) {
    global $connection;

    $code = $connection->real_escape_string($code);
    $productName = $connection->real_escape_string($productName);
    $productPrice = $connection->real_escape_string($productPrice);

    $query = "INSERT INTO barcodes (code, productName, productPrice) VALUES ('$code', '$productName', '$productPrice')";
    $result = $connection->query($query);

    return $result;
}
 
// Main API logic
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['code'])) {
        // Check barcode
        $code = $_GET['code'];

        if (checkBarcode($code)) {
            $barcodeInfo = fetchInformation($code);
            echo json_encode($barcodeInfo);
        } else {
            echo json_encode(['message' => 'Barcode not found']);
        }
    } elseif (isset($_GET['productName']) && isset($_GET['productPrice'])) {
        // Add product details
        $code = $_GET['newcode'];
        $productName = $_GET['productName'];
        $productPrice = $_GET['productPrice'];

        if (addProductDetails($code, $productName, $productPrice)) {
            echo json_encode(['message' => 'Product details added successfully']);
        } else {
            echo json_encode(['message' => 'Failed to add product details']);
        }
    } else {
        echo json_encode(['message' => 'Invalid request parameters']);
    }
} else {
    echo json_encode(['message' => 'Invalid request method']);
}


// Close the MySQL connection
$connection->close();
?>
