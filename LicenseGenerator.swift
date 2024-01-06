//
//  LicenseGenerator.swift
//  CLCracker
//
//  Created by Maksim on 06.01.2024.
//

import Foundation
import CommonCrypto

typealias MGCopyAnswer = (@convention(c) (CFString) -> CFString)

class LicenseGenerator {
    
    static func GenerateLicense() -> String? {
        let handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW)
        let copyAnswerSymbol = dlsym(handle, "MGCopyAnswer")
        let copyAnswerFunction = unsafeBitCast(copyAnswerSymbol, to: MGCopyAnswer.self)
        let UDID = copyAnswerFunction("UniqueDeviceID" as CFString) as String // UDID
        Console.shared.log("[+] UDID: " + UDID)
        let EthernetAddressV1 = copyAnswerFunction("EthernetMacAddress" as CFString) as String // MACv1
        var EthernetAddressV2 = "" // MACv2
        let components = EthernetAddressV1.components(separatedBy: ":")
        if components.count >= 1 {
            if var firstOctet = UInt8(components[0], radix: 16) {
                firstOctet += 2
                let modifiedString = String(format: "%02X%@", firstOctet, components[1...].joined(separator: ""))
                let finalString = modifiedString.lowercased().replacingOccurrences(of: ":", with: "")
                EthernetAddressV2 = finalString
            }
        }
        Console.shared.log("[+] MACv2: " + UDID)
        return GenerateLicenseWrapper(UDID: UDID, model: getDeviceModel(), MACv2: EthernetAddressV2)
    }
    
    static func GenerateLicenseWrapper(UDID: String, model: String, MACv2: String) -> String? {
        let LicenseV2field = LicenseGenerator.generateLicenseV2String(UDID: UDID, Model: model)
        let Request256field = LicenseGenerator.generateRequest256(key: LicenseGenerator.generateRequest256Key(MACv2: MACv2)!)
        let Request256fieldBase64 = LicenseGenerator.encodeRequest256field(Request256field!)
        return generateXMLString(LicenseV2field: LicenseV2field!, Request256fieldBase64: Request256fieldBase64!)
    }
    
    static func MD5(_ string: String) -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = string.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
    
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    static func generateLicenseV2String(UDID: String, Model: String) -> String? {
        let originalString = "947066a0b35b3bf2ecd4d697cc6e6700" + UDID + "a1" + Model
        
        var md5String = MD5(originalString)
        
        let indexToRemove5 = md5String!.index(md5String!.endIndex, offsetBy: -5)
        let indexToRemove6 = md5String!.index(md5String!.endIndex, offsetBy: -6)
        md5String!.remove(at: indexToRemove5)
        md5String!.remove(at: indexToRemove6)
        
        let insertionIndex = md5String!.index(md5String!.endIndex, offsetBy: -16)
        let substringToInsert = "a1"
        md5String!.insert(contentsOf: substringToInsert, at: insertionIndex)
        
        return md5String
    }
    
    static func generateRequest256Key(MACv2: String) -> String? {
        let result = MACv2 + "a1" + MACv2 + "14a1a1"
        return result
    }
    
    static func generateRequest256(key: String) -> String? {
        let text = "CL_IIllIllllIlIllllIIIIlIIlIlllIlIIlIlIIIlI:;CL_IIllIllIIllIIllllllIIIIIllIlllIIllIllIII:;CL_lIllIllIIlIlIIlIIIlIIlIIlllllllIIIIIIlIl"
        guard let plaintextData = text.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        let bufferSize = plaintextData.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        var numBytesEncrypted: size_t = 0
        
        let status = keyData.withUnsafeBytes { keyBytes in
            plaintextData.withUnsafeBytes { dataBytes in
                CCCrypt(CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        keyData.count,
                        nil,
                        dataBytes.baseAddress,
                        plaintextData.count,
                        &buffer,
                        bufferSize,
                        &numBytesEncrypted)
            }
        }
        
        if status == kCCSuccess {
            let encryptedData = Data(bytes: buffer, count: numBytesEncrypted)
            return encryptedData.base64EncodedString()
        }
        
        return nil
    }
    
    static func encodeRequest256field(_ request256field: String) -> String? {
        guard let requestData = request256field.data(using: .utf8) else {
            return nil
        }
        
        let base64String = requestData.base64EncodedString()
        return base64String
    }
    
    static func generateXMLString(LicenseV2field: String, Request256fieldBase64: String) -> String {
        
        let xmlString =
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>DidShowSetup</key>
            <integer>1</integer>
            <key>LicenseV2</key>
            <string>\(LicenseV2field)</string>
            <key>Request256</key>
            <data>
            \(Request256fieldBase64)
            </data>
            <key>Version</key>
            <string>144BC3</string>
        </dict>
        </plist>
        """
        
        return xmlString
    }
}
