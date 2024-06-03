This repository contains information about the DRM protection of the TrollStore version of CopyLog. Also attached above is a Swift script for self-generation of licenses. 

UPD 03.06.2024 - This DRM is using in DynamicStage and in CopyLog (JB) too. Just need to update license generation according to them.


# How is the license compiled?

At the moment, it is known that two fields are being checked: `LicenseV2` and `Request256`. The license file is located at the path /var/mobile/Library/Preferences/me.tomt000.copylog.other.plist. 
So how does generation happen?

1) Everything starts with the `LicenseV2` field. To begin with, a string of the following format is compiled: "947066a0b35b3bf2ecd4d697cc6e6700" + udid_ Device + `random_chars` + iPhoneModel. An MD5 hash is taken from the resulting string. It is not left, 5-6 characters from the end are removed from it, and after that `random_chars` are added after 16 characters from the end (two random characters). This completes the `LicenseV2` generation stage.
2) Then go to the `Request256` field. An encrypted string is written here, containing selectors that probably need to be called for the program to work. AES128 encryption is used, without the initialization vector with a key size of 256 bits (32 characters). The key for encryption/decryption is compiled according to the following format: `MACv2`+`random_chars`+`MACv2`+14+`random_chars`+`random_chars`. `MACv2` is the EthernetAddress of your device, to the first octet of which the number 2 is added. (It was F8 - it will become FA, it was B0 - it will become B2). Where does `random_chars` come from? It is taken from the first paragraph. 16 characters are counted from the end, 17-18 characters are our `random_chars`. I think the logic is clear.
3) When the program needs to check the license (it does not know the key), it generates it manually according to paragraph two. Thus, all two fields are of great importance in license generation/verification.

# DRM-server
I also attached the full implementation of its DRM server, the necessary parameters are input. `status` is `LicenseV2`, and `bufferRsa` is `Request256`. Before writing it to the plist, you need to re-encode `bufferRsa` in base64 format. There are params and It's description:
1) udid - UniqueDeviceID of iPhone
2) model - model of iPhone (iPhone12,1; iPhone 12,3 and so on)
3) ma - `MACv2` (read above)

# P.S
You can use this for your own personal purposes, for your own DRM. Very good resistance to analysis. It is worth saying that CopyLog is not vulnerable to injection of tweaks, because the import/export tables are broken.
