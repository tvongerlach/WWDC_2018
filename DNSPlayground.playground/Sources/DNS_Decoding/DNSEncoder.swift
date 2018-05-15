import UIKit
public struct DNSEncoder {
    
    var queryID: UInt16
    var recursionDesired: Bool
    var hostName: String
    public var encodedQuery: Data
    
    public init?(hostName: String) {
        self.init(queryID: 0x1a1a, recursionDesired: false, hostName: hostName)
    }
    
    public init?(queryID: UInt16, recursionDesired: Bool, hostName: String) {
        
        self.queryID = queryID
        self.recursionDesired = recursionDesired
        self.hostName = hostName
        self.encodedQuery = Data()
        
        let id = splitUInt16(i: queryID)
        encodedQuery.append(contentsOf: id)
        
        let firstFlagOctet: UInt8 = recursionDesired ? 0x01 : 0x00
        let secondFlagOctet: UInt8 = 0x00
        encodedQuery.append(firstFlagOctet)
        encodedQuery.append(secondFlagOctet)
        
        //Query, Answer, and Additional Count
        encodedQuery.append(contentsOf: [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        let strings = hostName.split(separator: ".")
        for label in strings {
            
            let length = UInt8(label.count)
            encodedQuery.append(length)
            encodedQuery.append(contentsOf: label.utf8.map { UInt8($0) })
        }
        encodedQuery.append(0x00)
        encodedQuery.append(contentsOf: [0x00, 0x01, 0x00, 0x01])
        
    }
    
    func splitUInt16(i: UInt16) -> [UInt8] {
        
        let one = UInt8(i >> 8)
        let two = UInt8(i & 0x00FF)
        return [one, two]
    }
    
}
