import Foundation

public enum RecordType: UInt16 {
    case A = 1
    case NS = 2
    case CNAME = 5
    case Other = 99
}

public struct DNSObject {
    
    public var id: UInt16
    public var qr: UInt8
    public var opcode: UInt8
    public var authoratativeAnswer: Bool
    public var recursionDesired: Bool
    public var recursionAvailable: Bool
    public var rcode: UInt8
    
    public var questionCount: UInt16
    public var answerCount: UInt16
    public var nameServerCount: UInt16
    public var additionalRecordsCount: UInt16
    
    public var questionsRecords = [QuestionRecord]()
    public var questionsRecordsRange: CountableClosedRange<Int>?
    
    public var answerRecords = [ResourceRecord]()
    public var answerRecordsRange: CountableClosedRange<Int>?
    
    public var nameServerRecords = [ResourceRecord]()
    public var nameServerRange: CountableClosedRange<Int>?
    
    public var additionalRecords = [ResourceRecord]()
    public var additionalRecordsRange: CountableClosedRange<Int>?
    
    public var rawData: Data
    
    public init(id: UInt16, qr: UInt8, opcode: UInt8, authoratativeAnswer: Bool, recursionDesired: Bool, recursionAvailable: Bool, rcode: UInt8, questionCount: UInt16, answerCount: UInt16, nameServerCount: UInt16, additionalRecordsCount: UInt16, questionsRecords: [QuestionRecord], questionsRecordsRange: CountableClosedRange<Int>, answerRecords: [ResourceRecord], answerRecordsRange: CountableClosedRange<Int>, nameServerRecords: [ResourceRecord], nameServerRange: CountableClosedRange<Int>, additionalRecords: [ResourceRecord], additionalRecordsRange: CountableClosedRange<Int>, rawData: Data) {
        
        self.id = id
        self.qr = qr
        self.opcode = opcode
        self.authoratativeAnswer = authoratativeAnswer
        self.recursionDesired = recursionDesired
        self.recursionAvailable = recursionAvailable
        self.rcode = rcode
        
        self.questionCount = questionCount
        self.answerCount = answerCount
        self.nameServerCount = nameServerCount
        self.additionalRecordsCount = additionalRecordsCount
        
        self.questionsRecords = questionsRecords
        self.questionsRecordsRange = questionsRecordsRange
        
        self.answerRecords = answerRecords
        self.answerRecordsRange = answerRecordsRange
        
        self.nameServerRecords = nameServerRecords
        self.nameServerRange = nameServerRange
        
        self.additionalRecords = additionalRecords
        self.additionalRecordsRange = additionalRecordsRange
        
        self.rawData = rawData
    }
    
    public init(data: Data) {
        
        self.rawData = data
        
        let idData = data.subdata(in: 0..<2)
        self.id = idData.withUnsafeBytes { $0.pointee }
        
        let firstFlagOctetData = data.subdata(in: 2..<3)
        let firstFlagOctet: UInt8 = firstFlagOctetData.withUnsafeBytes { $0.pointee }
        
        self.qr = firstFlagOctet >> 7
        
        self.opcode = (firstFlagOctet >> 3) & 0b00001111
        
        self.authoratativeAnswer = ((firstFlagOctet >> 2) & 0b00000001) == 1
        
        self.recursionDesired = (firstFlagOctet & 0x1) == 1
        
        let secondFlagOctetData = data.subdata(in: 3..<4)
        let secondFlagOctet: UInt8 = secondFlagOctetData.withUnsafeBytes { $0.pointee }
        
        self.recursionAvailable = (secondFlagOctet >> 7) == 1
        
        self.rcode = secondFlagOctet & 0b00001111
        
        let qcData = data.subdata(in: 4..<6)
        let anData = data.subdata(in: 6..<8)
        let nsData = data.subdata(in: 8..<10)
        let aaData = data.subdata(in: 10..<12)
        
        self.questionCount = qcData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer.pointee.bigEndian
        })
        self.answerCount = anData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer.pointee.bigEndian
        })
        self.nameServerCount = nsData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer.pointee.bigEndian
        })
        self.additionalRecordsCount = aaData.withUnsafeBytes({ (pointer: UnsafePointer<UInt16>) -> UInt16 in
            return pointer.pointee.bigEndian
        })
        
        decodeDNSResponseBody(data: data)
    }
    
    mutating func decodeDNSResponseBody(data: Data) {
        
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
            
            let q = QuestionRecord(questionName: qName, questionNameRange: qNameRange, questionType: qType, questionTypeRange: qTypeRange, questionClass: qClass, questionClassRange: qClassRange)
            questionsRecords.append(q)
        }
        
        questionsRecordsRange = questionCount == 0 ? nil : 12...(index-1)
        
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
    }
    
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
    
}

