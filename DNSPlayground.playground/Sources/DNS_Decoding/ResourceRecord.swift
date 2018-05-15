import Foundation

public struct ResourceRecord {
    
    public var hostName: String
    public var hostNameRange: CountableClosedRange<Int>
    
    public var type: RecordType
    public var typeRange: CountableClosedRange<Int>
    
    public var ttl: String
    public var ttlRange: CountableClosedRange<Int>
    
    public var recordClass: Int
    public var recordClassRange: CountableClosedRange<Int>
    
    public var dataLength: Int
    public var dataLengthRange: CountableClosedRange<Int>
    
    public var textResult: String?
    public var dataRange: CountableClosedRange<Int>
    
    public init(hostName: String, hostNameRange: CountableClosedRange<Int>, type: RecordType, typeRange: CountableClosedRange<Int>, ttl: String, ttlRange: CountableClosedRange<Int>, recordClass: Int, recordClassRange: CountableClosedRange<Int>, dataLength: Int, dataLengthRange: CountableClosedRange<Int>, textResult: String, dataRange: CountableClosedRange<Int> ) {
        
        self.hostName = hostName
        self.hostNameRange = hostNameRange
        
        self.type = type
        self.typeRange = typeRange
        
        self.ttl = ttl
        self.ttlRange = ttlRange
        
        self.recordClass = recordClass
        self.recordClassRange = recordClassRange
        
        self.dataLength = dataLength
        self.dataLengthRange = dataLengthRange
        
        self.textResult = textResult
        self.dataRange = dataRange
        
    }
}
