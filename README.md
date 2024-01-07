This repository contains information about the DRM protection of the TrollStore version of CopyLog. Also attached above is a Swift script for self-generation of licenses. 

# How is the license compiled?

At the moment, it is known that two fields are being checked: `LicenseV2` and `Request256`. The license file is located at the path /var/mobile/Library/Preferences/me.tomt000.copylog.other.plist. 
So how does generation happen?

1) Everything starts with the `LicenseV2` field. To begin with, a string of the following format is compiled: "947066a0b35b3bf2ecd4d697cc6e6700" + udid_ Device + `random_chars` + iPhoneModel. An MD5 hash is taken from the resulting string. It is not left, 5-6 characters from the end are removed from it, and after that `random_chars` are added after 16 characters from the end (two random characters). This completes the `LicenseV2` generation stage.
2) Then go to the `Request256` field. An encrypted string is written here, containing selectors that probably need to be called for the program to work. AES128 encryption is used, without the initialization vector.
3) When the program needs to check the license (it does not know the key), it generates it manually according to paragraph two. Thus, all two fields are of great importance in license generation/verification.

# P.S
You can use this for your own personal purposes, for your own DRM. Very good resistance to analysis. It is worth saying that CopyLog is not vulnerable to injection of tweaks, because the import/export tables are broken.