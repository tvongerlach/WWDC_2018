import UIKit

public enum RecordViewType {
    case Header
    case Question
    case ResourceRecord
}

public final class RecordView: UIView {
    
    let stackView = UIStackView()
    
    var recordType: RecordViewType
    var parentView: SectionView?
    var questionRecord: QuestionRecord?
    var dnsObject: DNSObject?
    var resourceRecord: ResourceRecord?
    var dataLabels: [SelectableUILabel]?
    
    var selected = false {
        
        didSet {
            
            guard let records = resourceRecord, let dlabels = dataLabels else {
                return
            }
            
            let range = records.hostNameRange.lowerBound...records.dataRange.upperBound
            
            if selected {
                
                dlabels.forEach{ $0.selected = false }
                let labels = Array(dlabels[range])
                labels.forEach{ $0.selected = true }
                backgroundColor = UIColor.black
                
            } else {
                
                let labels = Array(dlabels[range])
                labels.forEach{ $0.selected = false }
                backgroundColor = UIColor.white
                
            }
        }
    }
    
    public convenience init(with dnsObject: DNSObject, dataLabels: [SelectableUILabel], parent: SectionView) {
        self.init(setupAs: .Header)
        self.dataLabels = dataLabels
        self.dnsObject = dnsObject
        self.parentView = parent
        setUpHeaderAsHeaderView()
    }
    
    public convenience init(with resourceRecord: ResourceRecord, dataLabels: [SelectableUILabel]) {
        self.init(setupAs: .ResourceRecord)
        self.dataLabels = dataLabels
        self.resourceRecord = resourceRecord
        setUpResourceRecordView()
    }
    
    public convenience init(with question: QuestionRecord, dataLabels: [SelectableUILabel]) {
        self.init(setupAs: .Question)
        self.dataLabels = dataLabels
        self.questionRecord = question
        setUpAsQuestionView()
    }
    
    public init(setupAs recordType: RecordViewType) {
        self.recordType = recordType
        super.init(frame: .zero)
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
        clipsToBounds = true
        layer.cornerRadius = 5
        
        addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        
        if recordType == .ResourceRecord {
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.tappedRecordView))
            isUserInteractionEnabled = true
            addGestureRecognizer(tapGR)
        }
        
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedRecordView() {
        selected = !selected
    }
    
    func setUpHeaderAsHeaderView() {
        
        guard let dnsObject = dnsObject, let labels = dataLabels else {
            return
        }
        
        let id = String(format: "0X%04X", dnsObject.id.bigEndian)
        let idStack = UIStackView.getNameValueStack(name: "Transaction ID:", value: id)
        let rect = convert(bounds, to: parentView!.parent.scrollView)
        SelectableUILabel.setProperties(labels: [labels[0], labels[1]], views: [idStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let responseValue = dnsObject.qr == 0 ? "0 (Message is a query)" : "1 (Message is a response)"
        let responseStack = UIStackView.getNameValueStack(name: "Response:", value: responseValue)
        
        let opCodeStack = UIStackView.getNameValueStack(name: "Opcode:", value: "\(dnsObject.opcode)")
        
        let authoratativeValue = dnsObject.authoratativeAnswer ? "1 (Authoratative Server)" : "0 (Non Authoratative Server)"
        let authoratativeStack = UIStackView.getNameValueStack(name: "Authoratative:", value: authoratativeValue)
        
        let truncatedStack = UIStackView.getNameValueStack(name: "Truncated", value: "0 (Message is not truncated)")
        
        let recursionDesiredStack = UIStackView.getNameValueStack(name: "Recursion Desired:", value: "0 (No)")
        
        SelectableUILabel.setProperties(labels: [labels[2]], views: [responseStack, opCodeStack, authoratativeStack, truncatedStack, recursionDesiredStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let recursionAvailableStack = UIStackView.getNameValueStack(name: "Recursion Available:", value: "0 (Not Available)")
        
        let replyCodeStack = UIStackView.getNameValueStack(name: "Reply Code:", value: "0 (No error)")
        
        SelectableUILabel.setProperties(labels: [labels[3]], views: [recursionAvailableStack, replyCodeStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let questionCountStack = UIStackView.getNameValueStack(name: "Questions:", value: "\(dnsObject.questionCount)")
        SelectableUILabel.setProperties(labels: [labels[4], labels[5]], views: [questionCountStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let answerCountStack = UIStackView.getNameValueStack(name: "Answers:", value: "\(dnsObject.answerCount)")
        SelectableUILabel.setProperties(labels: [labels[6], labels[7]], views: [answerCountStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let nsCountStack = UIStackView.getNameValueStack(name: "Nameservers:", value: "\(dnsObject.nameServerCount)")
        SelectableUILabel.setProperties(labels: [labels[8], labels[9]], views: [nsCountStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        let additionalCountStack = UIStackView.getNameValueStack(name: "Additional records:", value: "\(dnsObject.additionalRecordsCount)")
        SelectableUILabel.setProperties(labels: [labels[10], labels[11]], views: [additionalCountStack], rect: rect, scrollView: parentView!.parent.scrollView)
        
        stackView.addArrangedSubview(idStack)
        stackView.addArrangedSubview(responseStack)
        stackView.addArrangedSubview(opCodeStack)
        stackView.addArrangedSubview(authoratativeStack)
        stackView.addArrangedSubview(truncatedStack)
        stackView.addArrangedSubview(recursionDesiredStack)
        stackView.addArrangedSubview(recursionAvailableStack)
        stackView.addArrangedSubview(replyCodeStack)
        stackView.addArrangedSubview(questionCountStack)
        stackView.addArrangedSubview(answerCountStack)
        stackView.addArrangedSubview(nsCountStack)
        stackView.addArrangedSubview(additionalCountStack)
    }
    
    func setUpAsQuestionView() {
        
        guard let questionRecord = questionRecord else {
            return
        }
        
        let nameStack = UIStackView.getNameValueStack(name: "Name:", value: questionRecord.questionName)
        let nameLabels = Array(self.dataLabels![questionRecord.questionNameRange.lowerBound...questionRecord.questionNameRange.upperBound])
        SelectableUILabel.setProperties(labels: nameLabels, views: [nameStack], rect: nil, scrollView: nil)
        
        let typeStack = UIStackView.getNameValueStack(name: "Type:", value: "1 (A) (Host Address)")
        let typeLabels = Array(dataLabels![questionRecord.questionTypeRange.lowerBound...questionRecord.questionTypeRange.upperBound])
        SelectableUILabel.setProperties(labels: typeLabels, views: [typeStack], rect: nil, scrollView: nil)
        
        let classStack = UIStackView.getNameValueStack(name: "Class:", value: "0x0001 (Internet)")
        let classLabels = Array(dataLabels![questionRecord.questionClassRange.lowerBound...questionRecord.questionClassRange.upperBound])
        SelectableUILabel.setProperties(labels: classLabels, views: [classStack], rect: nil, scrollView: nil)
        
        stackView.addArrangedSubview(nameStack)
        stackView.addArrangedSubview(typeStack)
        stackView.addArrangedSubview(classStack)
    }
    
    func setUpResourceRecordView() {
        
        guard let resourceRecord = resourceRecord else {
            return
        }
        
        let nameStack = UIStackView.getNameValueStack(name: "Name:", value: resourceRecord.hostName)
        let nameLabels = Array(dataLabels![resourceRecord.hostNameRange.lowerBound...resourceRecord.hostNameRange.upperBound])
        SelectableUILabel.setProperties(labels: nameLabels, views: [nameStack], rect: nil, scrollView: nil)
        
        var typeValue = ""
        var dataLabelText = ""
        switch resourceRecord.type {
        case .CNAME:
            typeValue = "5 (CNAME)"
            dataLabelText = "Cname:"
        case .NS:
            typeValue = "2 (Nameserver)"
            dataLabelText = "Name Server:"
        default:
            typeValue = "1 (A) (Host Address)"
            dataLabelText = "Address:"
        }
        let typeStack = UIStackView.getNameValueStack(name: "Type:", value: typeValue)
        let typeLabels = Array(dataLabels![resourceRecord.typeRange.lowerBound...resourceRecord.typeRange.upperBound])
        SelectableUILabel.setProperties(labels: typeLabels, views: [typeStack], rect: nil, scrollView: nil)
        
        let classStack = UIStackView.getNameValueStack(name: "Class:", value: "0x0001 (Internet)")
        let classLabels = Array(dataLabels![resourceRecord.recordClassRange.lowerBound...resourceRecord.recordClassRange.upperBound])
        SelectableUILabel.setProperties(labels: classLabels, views: [classStack], rect: nil, scrollView: nil)
        
        let ttlStack = UIStackView.getNameValueStack(name: "Time to live:", value: resourceRecord.ttl)
        let ttlLabels = Array(dataLabels![resourceRecord.ttlRange.lowerBound...resourceRecord.ttlRange.upperBound])
        SelectableUILabel.setProperties(labels: ttlLabels, views: [ttlStack], rect: nil, scrollView: nil)
        
        let dataLengthStack = UIStackView.getNameValueStack(name: "Data length:", value: "\(resourceRecord.dataLength)")
        let dataLengthLabels = Array(dataLabels![resourceRecord.dataLengthRange.lowerBound...resourceRecord.dataLengthRange.upperBound])
        SelectableUILabel.setProperties(labels: dataLengthLabels, views: [dataLengthStack], rect: nil, scrollView: nil)
        
        let dataStack = UIStackView.getNameValueStack(name: dataLabelText, value: resourceRecord.textResult!)
        let ddataLabels = Array(dataLabels![resourceRecord.dataRange.lowerBound...resourceRecord.dataRange.upperBound])
        SelectableUILabel.setProperties(labels: ddataLabels, views: [dataStack], rect: nil, scrollView: nil)
        
        stackView.addArrangedSubview(nameStack)
        stackView.addArrangedSubview(typeStack)
        stackView.addArrangedSubview(classStack)
        stackView.addArrangedSubview(ttlStack)
        stackView.addArrangedSubview(dataLengthStack)
        stackView.addArrangedSubview(dataStack)
        
    }
}
