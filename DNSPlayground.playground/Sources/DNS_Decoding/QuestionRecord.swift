import Foundation

public struct QuestionRecord {
    public var questionName: String
    public var questionNameRange: CountableClosedRange<Int>
    
    public var questionType: UInt16
    public var questionTypeRange: CountableClosedRange<Int>
    
    public var questionClass: UInt16
    public var questionClassRange: CountableClosedRange<Int>
    
    public init(questionName: String, questionNameRange: CountableClosedRange<Int>, questionType: UInt16, questionTypeRange: CountableClosedRange<Int>, questionClass: UInt16, questionClassRange: CountableClosedRange<Int>) {
        
        self.questionName = questionName
        self.questionNameRange = questionNameRange
        
        self.questionType = questionType
        self.questionTypeRange = questionTypeRange
        
        self.questionClass = questionClass
        self.questionClassRange = questionClassRange
        
    }
    
}
