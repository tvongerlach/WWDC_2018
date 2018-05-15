import UIKit

public enum SectionViewType: String {
    case Header = "DNS Header"
    case Question = "Question Records"
    case Answer = "Answer Records"
    case NameServer = "Name Server Records"
    case Additional = "Additional Records"
}



public final class SectionView: UIView {
    
    var dnsObject: DNSObject
    var sectionType: SectionViewType
    var expandButtonView: UIImageView?
    var headerLabel: UILabel?
    var expanded = true
    var parent: DNSDataView
    var dataLabels = [SelectableUILabel]()
    var range: CountableClosedRange<Int>?
    let sectionStack = UIStackView()
    var detailViews = [UIView]()
    
    var selected = false {
        didSet {
            
            if selected {
                
                dataLabels.forEach{ $0.selected = false }
                let labels = Array(dataLabels[range!])
                labels.forEach{ $0.selected = true }
                setToHighlighted()
            } else {
                
                let labels = Array(dataLabels[range!])
                labels.forEach{ $0.selected = false }
                setToDefault()
                
            }
        }
    }
    
    
    
    public init(setupAs sectionType: SectionViewType, object: DNSObject, dataLabels: [SelectableUILabel], parent: DNSDataView) {
        self.parent = parent
        self.sectionType = sectionType
        self.dnsObject = object
        self.dataLabels = dataLabels
        super.init(frame: .zero)
        
        backgroundColor = .white
        clipsToBounds = true
        layer.borderWidth = 2
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(SectionView.tappedSelectionView))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGR)
        
        
        setUpSectionView(dataLabels: dataLabels)
    }
    
    @objc func tappedSelectionView() {
        selected = !selected
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setToDefault() {
        expandButtonView!.tintColor = .black
        headerLabel!.textColor = .black
        backgroundColor = .white
        for s in sectionStack.arrangedSubviews {
            s.backgroundColor = .white
            s.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    func setToHighlighted() {
        expandButtonView!.tintColor = .white
        headerLabel!.textColor = .white
        backgroundColor = .black
        
        for s in sectionStack.arrangedSubviews {
            s.backgroundColor = .black
            s.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    func setUpSectionView(dataLabels: [SelectableUILabel]) {
        
        addSubview(sectionStack)
        setUpSectionStackConstraints()
        setUpSectionHeader()
        
        
        switch sectionType {
        case .Header:
            range = 0...11
            let headerView = RecordView(with: dnsObject, dataLabels: dataLabels, parent: self)
            sectionStack.addArrangedSubview(headerView)
            setUpRecordViewConstraints(recordView: headerView)
            detailViews.append(headerView)
            
        case .Question:
            
            let qCount = dnsObject.questionsRecords.count
            if qCount > 0 {
                range = dnsObject.questionsRecords[0].questionNameRange.lowerBound...dnsObject.questionsRecords[qCount-1].questionClassRange.upperBound
            } else {
                range = nil
            }
            
            for questionRecord in dnsObject.questionsRecords {
                let questionView = RecordView(with: questionRecord, dataLabels: dataLabels)
                sectionStack.addArrangedSubview(questionView)
                setUpRecordViewConstraints(recordView: questionView)
                detailViews.append(questionView)
            }
            
        case .Answer:
            
            let aCount = dnsObject.answerRecords.count
            if aCount > 0 {
                range = dnsObject.answerRecords[0].hostNameRange.lowerBound...dnsObject.answerRecords[aCount-1].dataRange.upperBound
            } else {
                range = nil
            }
            
            for answerRecord in dnsObject.answerRecords {
                let answerView = RecordView(with: answerRecord, dataLabels: dataLabels)
                sectionStack.addArrangedSubview(answerView)
                setUpRecordViewConstraints(recordView: answerView)
                detailViews.append(answerView)
            }
            
        case .NameServer:
            
            let aCount = dnsObject.nameServerRecords.count
            if aCount > 0 {
                range = dnsObject.nameServerRecords[0].hostNameRange.lowerBound...dnsObject.nameServerRecords[aCount-1].dataRange.upperBound
            } else {
                range = nil
            }
            
            for nsRecord in dnsObject.nameServerRecords {
                let nsView = RecordView(with: nsRecord, dataLabels: dataLabels)
                sectionStack.addArrangedSubview(nsView)
                setUpRecordViewConstraints(recordView: nsView)
                detailViews.append(nsView)
            }
            
        case .Additional:
            
            let aCount = dnsObject.additionalRecords.count
            if aCount > 0 {
                range = dnsObject.additionalRecords[0].hostNameRange.lowerBound...dnsObject.additionalRecords[aCount-1].dataRange.upperBound
            } else {
                range = nil
            }
            
            for additionalRecord in dnsObject.additionalRecords {
                let additionalView = RecordView(with: additionalRecord, dataLabels: dataLabels)
                sectionStack.addArrangedSubview(additionalView)
                setUpRecordViewConstraints(recordView: additionalView)
                detailViews.append(additionalView)
            }
        }
        
        let labels = dataLabels[range!]
        labels.forEach{ $0.correspondingSectionView = self }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // change 2 to desired number of seconds
            self.expandButtonToggled()
        }
    }
    
    func setUpSectionStackConstraints() {
        
        sectionStack.translatesAutoresizingMaskIntoConstraints = false
        sectionStack.axis = .vertical
        sectionStack.spacing = 5
        sectionStack.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        sectionStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        sectionStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        sectionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
    }
    
    func setUpSectionHeader() {
        
        let headerStack = UIStackView.getNameValueStack(name: sectionType.rawValue, value: nil)
        if let label = headerStack.arrangedSubviews[0] as? UILabel {
            headerLabel = label
        }
        
        let imagePath = Bundle.main.path(forResource: "expand-button", ofType: "png")!
        let button = UIImage(contentsOfFile: imagePath)!
        let buttonView = UIImageView(image: button)
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        buttonView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        buttonView.image = buttonView.image!.withRenderingMode(.alwaysTemplate)
        buttonView.tintColor = UIColor.black
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(SectionView.expandButtonToggled))
        buttonView.isUserInteractionEnabled = true
        buttonView.addGestureRecognizer(tapGR)
        
        expandButtonView = buttonView
        
        headerStack.addArrangedSubview(buttonView)
        
        expandButtonView?.translatesAutoresizingMaskIntoConstraints = false
        
        sectionStack.addArrangedSubview(headerStack)
    }
    
    func setUpRecordViewConstraints(recordView: UIView) {
        
        recordView.translatesAutoresizingMaskIntoConstraints = false
        recordView.leadingAnchor.constraint(equalTo: sectionStack.leadingAnchor, constant: 5).isActive = true
        recordView.trailingAnchor.constraint(equalTo: sectionStack.trailingAnchor, constant: -5).isActive = true
    }
    
    @objc func expandButtonToggled() {
        
        guard let button = expandButtonView else {
            return
        }
        
        if button.transform == CGAffineTransform.identity {
            
            UIView.animate(withDuration: 0.5, animations: {
                self.detailViews.forEach { $0.isHidden = true }
                self.expanded = false
                self.layoutIfNeeded()
                button.transform = CGAffineTransform(rotationAngle: self.radians(90))
            }) { (true) in
            }
            
        } else {
            
            UIView.animate(withDuration: 0.5, animations: {
                self.detailViews.forEach { $0.isHidden = false }
                self.expanded = true
                self.transform = .identity
                button.transform = .identity
                self.layoutIfNeeded()
            }, completion: { (true) in
            })
        }
        
    }
    
    func radians(_ degrees: Double) -> CGFloat {
        return CGFloat(degrees * .pi / 180)
    }
}
