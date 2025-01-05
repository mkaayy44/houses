<?php
// Set headers to handle CORS, caching, and content type
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token");
header("Content-Type: application/json; charset=UTF-8");

// Database connection
$con = mysqli_connect("localhost", "root", "", "houses");

// Check connection
if (mysqli_connect_errno()) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to connect to MySQL: " . mysqli_connect_error()]);
    exit;
}

// SQL query to fetch house data
$sql = "
    SELECT houses.hid, houses.name, houses.size, houses.price, categories.name AS category
    FROM houses
    INNER JOIN categories ON houses.cid = categories.cid
";

if ($result = mysqli_query($con, $sql)) {
    $houses = [];

    // Fetch rows and store them in the array
    while ($row = mysqli_fetch_assoc($result)) {
        $houses[] = $row;
    }

    // Return data as JSON
    echo json_encode($houses);

    // Free result set and close connection
    mysqli_free_result($result);
    mysqli_close($con);
} else {
    http_response_code(500);
    echo json_encode(["error" => "Failed to execute query: " . mysqli_error($con)]);
    mysqli_close($con);
}
?>
