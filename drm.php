<?php

function generateRandomChars() {
    $chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $randomChars = $chars[rand(0, 61)] . $chars[rand(0, 61)];
    return $randomChars;
}

function encryptAES128($data, $key) {
    $encrypted = openssl_encrypt($data, 'aes-256-cbc', $key, 0, '');
    return base64_encode($encrypted);
}

function generateResult($udid, $model, $ma) {
    if (empty($udid)) {
        echo json_encode(['status' => 'error', 'error' => 'Missing UDID']);
        return;
    }

    if (empty($model)) {
        echo json_encode(['status' => 'error', 'error' => 'Missing model']);
        return;
    }

    $randomChars = generateRandomChars();

    $hashInput = md5('947066a0b35b3bf2ecd4d697cc6e6700' . $udid . $randomChars . $model);
    $modified1 = substr($hashInput, 0, -6) . substr($hashInput, -4);
    $modified2 = substr_replace($modified1, $randomChars, -16, 0);
    $hashedResult = $modified2;

    $key = $ma . $randomChars . $ma . '14' . $randomChars . $randomChars;
    $dataToEncrypt = 'CL_IIllIllIllIlIllllIIIIlIIlIlllIlIIlIlIIIlI:;CL_IIllIllIIllIIllllllIIIIIllIlllIIllIllIII:;CL_lIllIllIIlIlIIlIIIlIIlIIlllllllIIIIIIlIl';
    $encryptedResult = encryptAES128($dataToEncrypt, $key);

    $result = [
        'status' => $hashedResult,
        'bufferRsa' => base64_decode($encryptedResult)
    ];

    echo json_encode($result);
}

$udid = isset($_GET['udid']) ? $_GET['udid'] : "";
$model = isset($_GET['model']) ? $_GET['model'] : "";
$ma = isset($_GET['ma']) ? $_GET['ma'] : "";

generateResult($udid, $model, $ma);
?>
