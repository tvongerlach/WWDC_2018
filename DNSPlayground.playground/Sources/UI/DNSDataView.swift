import UIKit

public final class DNSDataView: UIView {
    
    public var rootStack: UIStackView?
    public var dnsObject: DNSObject
    public var segmentControl: UISegmentedControl?
    public var scrollView = UIScrollView()
    public var dataLabels = [SelectableUILabel]()
    public var dataArray = [UInt8]()
    var bytesPerRow: Int = 13
    
    public init(for object: DNSObject) {
        
        self.dnsObject = object
        super.init(frame: .zero)
        
        setUpView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpView() {
        
        backgroundColor = .white
        
        rootStack = UIStackView()
        
        guard let rootStack = rootStack else {
            fatalError()
        }
        
        let dataCount = Double(dnsObject.rawData.count)
        let rows = Int(ceil(dataCount / Double(bytesPerRow)))
        
        //Setup RootStack Constraints and Properties
        addSubview(rootStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 20).isActive = true
        rootStack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        rootStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.90).isActive = true
        rootStack.spacing = 2
        rootStack.axis = .vertical
        rootStack.distribution = .fill
        
        var address = 0
        //Setup DataStacks and their properties
        for _ in 1...rows {
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .fill
            for i in 0...bytesPerRow {
                let label = SelectableUILabel()
                label.font = UIFont.systemFont(ofSize: 12)
                label.textColor = UIColor.black
                label.textAlignment = .center
                label.backgroundColor = .white
                if i != 0 {
                    dataLabels.append(label)
                }
                
                if (i == 0) {
                    
                    label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
                    label.textAlignment = .left
                    let a = String(format: "%02X", address)
                    label.text = "\(a):"
                    label.isUserInteractionEnabled = false
                    address += bytesPerRow
                }
                
                stackView.addArrangedSubview(label)
            }
            
            rootStack.addArrangedSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.centerXAnchor.constraint(equalTo: rootStack.centerXAnchor).isActive = true
            stackView.distribution = .fillEqually
        }
        
        for (index, data) in dnsObject.rawData.enumerated() {
            dataArray.append(data)
            let row = index / bytesPerRow
            let column = (index % bytesPerRow) + 1
            let hexString = String(format: "%02X", data)
            guard let stack = rootStack.subviews[row] as? UIStackView else {
                fatalError()
            }
            
            guard let field = stack.arrangedSubviews[column] as? UILabel else {
                fatalError()
            }
            field.text = hexString
            
            if index == (dnsObject.rawData.count - 1) {
                rootStack.setCustomSpacing(10, after: stack)
            }
        }
        
        let items = ["All values as Hex", "Domain names as Chars"]
        segmentControl = UISegmentedControl(items: items)
        guard let segmentControl = segmentControl else {
            return
        }
        segmentControl.selectedSegmentIndex = 0
        segmentControl.backgroundColor = UIColor.clear
        segmentControl.tintColor = .black
        segmentControl.addTarget(self, action: #selector(self.didChangeSegmentControl), for: UIControlEvents.valueChanged)
        rootStack.addArrangedSubview(segmentControl)
        rootStack.setCustomSpacing(10, after: segmentControl)
        
        scrollView.backgroundColor = .white
        rootStack.addArrangedSubview(scrollView)
        dataLabels.forEach{ $0.scrollView = scrollView }
        dataLabels.forEach { (label) in
            label.scrollView = scrollView
            label.allLabels = dataLabels
        }
        
        
        let scrollStack = UIStackView()
        scrollView.addSubview(scrollStack)
        
        scrollStack.axis = .vertical
        scrollStack.spacing = 4
        scrollStack.translatesAutoresizingMaskIntoConstraints = false
        scrollStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 3).isActive = true
        scrollStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        scrollStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -3).isActive = true
        scrollStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.97).isActive = true
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        
        let sectionView = SectionView(setupAs: .Header, object: dnsObject, dataLabels: dataLabels, parent: self)
        scrollStack.addArrangedSubview(sectionView)
        
        if dnsObject.questionCount > 0 {
            let questionSectionView = SectionView(setupAs: .Question, object: dnsObject, dataLabels: dataLabels, parent: self)
            scrollStack.addArrangedSubview(questionSectionView)
        }
        
        if dnsObject.answerCount > 0 {
            let answerSectionView = SectionView(setupAs: .Answer, object: dnsObject, dataLabels: dataLabels, parent: self)
            scrollStack.addArrangedSubview(answerSectionView)
        }
        
        if dnsObject.nameServerCount > 0 {
            let nameServerSectionView = SectionView(setupAs: .NameServer, object: dnsObject, dataLabels: dataLabels, parent: self)
            scrollStack.addArrangedSubview(nameServerSectionView)
        }
        
        if dnsObject.additionalRecordsCount > 0 {
            let additionalSectionView = SectionView(setupAs: .Additional, object: dnsObject, dataLabels: dataLabels, parent: self)
            scrollStack.addArrangedSubview(additionalSectionView)
        }
    }
    
    @objc func didChangeSegmentControl() {
        
        guard let control = segmentControl else {
            return
        }
        
        let data = dnsObject.rawData
        let records = dnsObject.answerRecords + dnsObject.nameServerRecords + dnsObject.additionalRecords
        
        for q in dnsObject.questionsRecords {
            
            for i in q.questionNameRange.lowerBound...q.questionNameRange.upperBound {
                setLabel(atIndex: i, textResultAsChar: true)
            }
        }
        
        for r in records {
            for i in r.hostNameRange.lowerBound...r.hostNameRange.upperBound {
                setLabel(atIndex: i, textResultAsChar: true)
            }
            for i in r.dataRange.lowerBound...r.dataRange.upperBound {
                
                if r.type == .CNAME || r.type == .NS {
                    setLabel(atIndex: i, textResultAsChar: true)
                } else {
                    setLabel(atIndex: i, textResultAsChar: false)
                }
            }
        }
        
    }
    
    func setLabel(atIndex i: Int, textResultAsChar: Bool) {
        
        if segmentControl?.selectedSegmentIndex == 0 {
            dataLabels[i].text = String(format: "%02X", dataArray[i])
        } else {
            let char = String(Character(UnicodeScalar(dataArray[i])))
            
            if textResultAsChar {
                
                if dataArray[i] < 65 || dataArray[i] > 122 {
                    dataLabels[i].text = "."
                } else {
                    dataLabels[i].text = char.lowercased()
                }
                
            } else {
                dataLabels[i].text = "\(dataArray[i])"
            }
        }
    }
}
