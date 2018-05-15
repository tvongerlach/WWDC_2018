import UIKit
import PlaygroundSupport
enum DNSMode {
    case Decoding
    case Encoding
}
/*:
 # DNS Message Decoding and Encoding Playground
 
  **To fully experience this playground run it with the assistant editor opened and set to Live View.**
 
 This playground is an exploration of the Domain Name Service (DNS) binary message format. DNS is an integral part of the internet, and its purpose is to map human readable domain names such as www.apple.com to their corresponding IP addresses. [A detailed discussion of DNS messages can be found in RFC 1305.](https://tools.ietf.org/html/rfc1035#section-4.1.1)
 
  ## How to interact with the UI
 To better understand the structure of DNS messages sent between DNS servers and clients I created an interactive UI. You can click on any byte, represented as hex values, to  explore its meaning, and you can also click on any section or resource record to find what part of the binary message it corresponds to. Finally, you can convert all characters pertaining to a domain name into their respective character values, to better understand how these DNS messages are formed.
 
 ## Set Up
The playground can be run in two modes, Decoding and Encoding mode. By setting the mode variable you can decide if you would like to inspect a decoded or encoded DNS message. If in decoding mode you can chagne the resourceName variable to any binary filename that you wish to decode and inspect visually. If you are in encoding mode you can change the hostName variable to any name you would like to encode.
 */
let mode = DNSMode.Decoding

let resourceName = "ubc_query"
let filePath = Bundle.main.path(forResource: resourceName, ofType: "bin")
guard let data = FileManager.default.contents(atPath: filePath!) else {
    fatalError()
}

let hostName = "www.apple.com"
guard let encoder = DNSEncoder(hostName: hostName) else {
    fatalError()
}

/*:
 ## Header Decoding
 We first decode the header which is 12 bytes long. The image below shows the format of the header section where each cell represents a pixel. The details can be found in [Section 4.1.1](https://tools.ietf.org/html/rfc1035#section-4.1.1) of the RFC 1305.
 
 ![Header Section](headerSection.png)
 */
var id: UInt16
var qr: UInt8
var opcode: UInt8
var authoratativeAnswer: Bool
var recursionDesired: Bool
var recursionAvailable: Bool
var rcode: UInt8
var questionCount: UInt16
var answerCount: UInt16
var nameServerCount: UInt16
var additionalRecordsCount: UInt16

let idData = data.subdata(in: 0..<2)
id = idData.withUnsafeBytes { $0.pointee }

let firstFlagOctetData = data.subdata(in: 2..<3)
let firstFlagOctet: UInt8 = firstFlagOctetData.withUnsafeBytes { $0.pointee }

qr = firstFlagOctet >> 7

opcode = (firstFlagOctet >> 3) & 0b00001111

authoratativeAnswer = ((firstFlagOctet >> 2) & 0b00000001) == 1

recursionDesired = (firstFlagOctet & 0x1) == 1

let secondFlagOctetData = data.subdata(in: 3..<4)
let secondFlagOctet: UInt8 = secondFlagOctetData.withUnsafeBytes { $0.pointee }

recursionAvailable = (secondFlagOctet >> 7) == 1

rcode = secondFlagOctet & 0b00001111

let qcData = data.subdata(in: 4..<6)
let anData = data.subdata(in: 6..<8)
let nsData = data.subdata(in: 8..<10)
let aaData = data.subdata(in: 10..<12)

questionCount = qcData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
    return pointer.pointee.bigEndian
})
answerCount = anData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
    return pointer.pointee.bigEndian
})
nameServerCount = nsData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
    return pointer.pointee.bigEndian
})
additionalRecordsCount = aaData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
    return pointer.pointee.bigEndian
})

/*:
 ## Domain Name Decoding
The function decodeDomainName() decodes a domain name in the message starting at a specified index. The isBytePointer() function is a helper to determine if a message is compressed. The details are specified in [Section 4.1.4](https://tools.ietf.org/html/rfc1035#section-4.1.4) of the RFC 1305.
 */

func isBytePointer(byte: UInt8) -> Bool {
    return (byte >> 6) == 0b11
}

func decodeDomainName(data: Data, index: inout Int) -> String {
    
    var string = ""
    
    var length: UInt8 = data.subdata(in: index..<(index+1)).withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> UInt8 in
        return pointer.pointee.bigEndian
    }
    
    while true {
        
        if (isBytePointer(byte: length)) {
            
            var offset: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
                return pointer.pointee.bigEndian
            })
            offset = offset & 0x3fff
            var tempIndex = Int(offset)
            let pointerValue = decodeDomainName(data: data, index: &tempIndex)
            string.append(pointerValue)
            string.append(".")
            index = index + 2
            break;
        }
        
        index = index + 1
        
        for _ in 0..<length {
            
            let c = data.subdata(in: index..<(index+1)).withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> UInt8 in
                return pointer.pointee.bigEndian
            })
            
            let char = Character(UnicodeScalar(c))
            string.append(char)
            index = index + 1
        }
        
        string.append(".")
        
        length = data.subdata(in: index..<(index+1)).withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> UInt8 in
            return pointer.pointee.bigEndian
        }
        
        if (length == 0) {
            index = index + 1
            break
        }
    }
    
    if (!string.isEmpty && (string.last! == ".")) {
        string.removeLast()
    }
    return string
}

/*:
 ## Resource Record Decoding
 The function decodeResourceRecord() decodes a resource record starting at a specified index. The format of a resource record is shown below. The details can be found in [Section 4.1.3](https://tools.ietf.org/html/rfc1035#section-4.1.3) of the RFC 1305.
 
 ![Header Section](recordFormat.png)
 */

func decodeResourceRecord(data: Data, index: inout Int) -> ResourceRecord? {
    
    let startIndex = index
    let name = decodeDomainName(data: data, index: &index)
    let nameRage: CountableClosedRange<Int> = startIndex...(index-1)
    
    let typeNum: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        return pointer.pointee.bigEndian
    }
    
    let typeRange: CountableClosedRange<Int> = index...(index+1)
    var type = RecordType.init(rawValue: typeNum)
    if type == nil {
        type = RecordType.Other
    }
    
    index += 2
    
    let recordClass: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        return pointer.pointee.bigEndian
    }
    let classRange: CountableClosedRange<Int> = index...(index+1)
    index += 2
    
    let ttl: UInt32 = data.subdata(in: index..<(index+4)).withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
        return pointer.pointee.bigEndian
    }
    
    let ttlRange: CountableClosedRange<Int> = index...(index+3)
    index += 4
    
    let rdLength: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        return pointer.pointee.bigEndian
    }
    
    let dataLengthRange: CountableClosedRange<Int> = index...(index+1)
    index += 2
    
    let dataRange: CountableClosedRange<Int> = index...(index + Int(rdLength) - 1)
    
    switch type! {
    case .A:
        
        let ip : UInt32 = data.subdata(in: index..<(index+4)).withUnsafeBytes { (pointer: UnsafePointer<UInt32>) -> UInt32 in
            return pointer.pointee.bigEndian
        }
        index = index + 4
        
        let b1 = UInt8(ip & 0xff)
        let b2 = UInt8((ip>>8) & 0xff)
        let b3 = UInt8((ip>>16) & 0xff)
        let b4 = UInt8((ip>>24) & 0xff)
        
        let ipString = "\(b4).\(b3).\(b2).\(b1)"
        
        let record = ResourceRecord(hostName: name, hostNameRange: nameRage, type: type!, typeRange: typeRange, ttl: "\(ttl)", ttlRange: ttlRange, recordClass: Int(recordClass), recordClassRange: classRange, dataLength: Int(rdLength), dataLengthRange: dataLengthRange, textResult: ipString, dataRange: dataRange)
        return record
        
    case .NS:
        
        let nsName = decodeDomainName(data: data, index: &index)
        
        let record = ResourceRecord(hostName: name, hostNameRange: nameRage, type: type!, typeRange: typeRange, ttl: "\(ttl)", ttlRange: ttlRange, recordClass: Int(recordClass), recordClassRange: classRange, dataLength: Int(rdLength), dataLengthRange: dataLengthRange, textResult: nsName, dataRange: dataRange)
        return record
        
    case .CNAME:
        
        let cName = decodeDomainName(data: data, index: &index)
        
        let record = ResourceRecord(hostName: name, hostNameRange: nameRage, type: type!, typeRange: typeRange, ttl: "\(ttl)", ttlRange: ttlRange, recordClass: Int(recordClass), recordClassRange: classRange, dataLength: Int(rdLength), dataLengthRange: dataLengthRange, textResult: cName, dataRange: dataRange)
        return record
        
    default:
        index = index + Int(rdLength)
        return nil
    }
}

/*:
 ## Question Record Decoding
 Next we will decode the question section of the DNS message. The format of a question section is shown below. The details can be found in [Section 4.1.2](https://tools.ietf.org/html/rfc1035#section-4.1.2) of the RFC 1305.
 
 ![Header Section](messageFormat.png)
 */
var questionsRecords = [QuestionRecord]()
var questionsRecordsRange: CountableClosedRange<Int>?

var answerRecords = [ResourceRecord]()
var answerRecordsRange: CountableClosedRange<Int>?

var nameServerRecords = [ResourceRecord]()
var nameServerRange: CountableClosedRange<Int>?

var additionalRecords = [ResourceRecord]()
var additionalRecordsRange: CountableClosedRange<Int>?

var index: Int = 12

for _ in 0..<questionCount {
    
    let startIndex = index
    let qName = decodeDomainName(data: data, index: &index)
    let qNameRange = startIndex...(index-1)
    
    let qType: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        return pointer.pointee.bigEndian
    }
    let qTypeRange = index...(index+1)
    index += 2
    
    let qClass: UInt16 = data.subdata(in: index..<(index+2)).withUnsafeBytes { (pointer: UnsafePointer<UInt16>) -> UInt16 in
        return pointer.pointee.bigEndian
    }
    let qClassRange = index...(index+1)
    index += 2
    
    let question = QuestionRecord(questionName: qName, questionNameRange: qNameRange, questionType: qType, questionTypeRange: qTypeRange, questionClass: qClass, questionClassRange: qClassRange)
    questionsRecords.append(question)
    
}
questionsRecordsRange = questionCount == 0 ? nil : 12...(index-1)

/*:
 ## Record Decoding
 Finally, we will decode all the resource records (i.e. Answer RRs, Authority RRs, and Additional RRs), using the decodeResourceRecord() function from above.
 */

let answerStartRange = index
for _ in 0..<answerCount {
    if let record = decodeResourceRecord(data: data, index: &index) {
        answerRecords.append(record)
    }
}
answerRecordsRange = answerCount == 0 ? nil : answerStartRange...(index-1)


let nameServerStartRange = index
for _ in 0..<nameServerCount {
    if let record = decodeResourceRecord(data: data, index: &index) {
        nameServerRecords.append(record)
    }
}
nameServerRange = nameServerCount == 0 ? nil : nameServerStartRange...(index-1)

let additionalRangeStart = index
for _ in 0..<additionalRecordsCount {
    if let record = decodeResourceRecord(data: data, index: &index) {
        additionalRecords.append(record)
    }
}
additionalRecordsRange = additionalRecordsCount == 0 ? nil :additionalRangeStart...(index-1)


/*:
 ## Creating the DNS Object
 Here we create the DNSObject with the fields we decoded above. We then pass the object to our view controller to explore the message interactively.
 */
let decodedDNSObject = DNSObject(id: id, qr: qr, opcode: opcode, authoratativeAnswer: authoratativeAnswer, recursionDesired: recursionDesired, recursionAvailable: recursionAvailable, rcode: rcode, questionCount: questionCount, answerCount: answerCount, nameServerCount: nameServerCount, additionalRecordsCount: additionalRecordsCount, questionsRecords: questionsRecords, questionsRecordsRange: questionsRecordsRange!, answerRecords: answerRecords, answerRecordsRange: answerRecordsRange!, nameServerRecords: nameServerRecords, nameServerRange: nameServerRange!, additionalRecords: additionalRecords, additionalRecordsRange: additionalRecordsRange!, rawData: data)

class MyViewController : UIViewController {
    
    let dnsObject: DNSObject
    
    public init(dnsObject: DNSObject) {
        
        
        
        self.dnsObject = dnsObject
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = DNSDataView(for: dnsObject)
        self.view = view
    }
}

if mode == DNSMode.Decoding {
    PlaygroundPage.current.liveView = MyViewController(dnsObject: decodedDNSObject)
} else {
    
    let object = DNSObject(data: encoder.encodedQuery)
    PlaygroundPage.current.liveView = MyViewController(dnsObject: object)
}
