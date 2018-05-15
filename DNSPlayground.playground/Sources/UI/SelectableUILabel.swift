import UIKit

public class SelectableUILabel: UILabel {
    
    public var correspondingViews = [UIStackView]()
    public var correspondingRect: CGRect?
    public var scrollView: UIScrollView?
    public var correspondingSectionView: SectionView?
    public var adjacentLabels = [SelectableUILabel]()
    public var allLabels = [SelectableUILabel]()
    
    
    var selected: Bool = false {
        didSet {
            
            if selected {
                
                //                font = UIFont.systemFont(ofSize: font.pointSize, weight: .semibold)
                backgroundColor = .black
                textColor = .white
                correspondingViews.forEach { (stack) in
                    for v in stack.arrangedSubviews {
                        if (v.backgroundColor != .black) {
                            v.backgroundColor = .black
                        }
                        
                        if let l = v as? UILabel {
                            if l.textColor != .white {
                                l.textColor = .white
                            }
                        }
                    }
                }
                
                if let sectionView = correspondingSectionView {
                    if sectionView.expanded == false {
                        sectionView.expandButtonToggled()
                    }
                }
                
            } else {
                //                font = UIFont.systemFont(ofSize: font.pointSize, weight: .regular)
                backgroundColor = .white
                textColor = .black
                correspondingViews.forEach { (stack) in
                    for v in stack.arrangedSubviews {
                        if (v.backgroundColor != .white) {
                            v.backgroundColor = .white
                        }
                        
                        if let l = v as? UILabel {
                            if l.textColor != .black {
                                l.textColor = .black
                            }
                        }
                    }
                }
                
                if let sectionView = correspondingSectionView {
                    if sectionView.expanded == true {
                        sectionView.expandButtonToggled()
                    }
                    sectionView.setToDefault()
                }
                
                
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(SelectableUILabel.labelTapped))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGR)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func labelTapped() {
        
        var currentState = selected
        allLabels.forEach { $0.selected = false }
        correspondingSectionView?.selected = false
        
        selected = !currentState
        adjacentLabels.forEach{ $0.selected = selected }
        
    }
    
    public static func setProperties(labels: [SelectableUILabel], views: [UIStackView], rect: CGRect?, scrollView: UIScrollView?) {
        
        for label in labels {
            let alabels = labels.filter{ $0 != label }
            label.adjacentLabels = alabels
            label.correspondingViews = views
            label.scrollView = scrollView
            label.correspondingRect = rect
        }
    }
    
}

