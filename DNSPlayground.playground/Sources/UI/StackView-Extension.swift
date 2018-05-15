import UIKit

public extension UIStackView {
    
    public static func getNameValueStack(name: String, value: String?) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let typeLabel = UILabel()
        typeLabel.text = name
        stack.addArrangedSubview(typeLabel)
        
        if let value = value {
            let typeValue = UILabel()
            typeValue.text = value
            stack.addArrangedSubview(typeValue)
            stack.distribution = .fill
            typeValue.textAlignment = .right
            
            typeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            typeValue.font = UIFont.systemFont(ofSize: 14, weight: .light)
            
            typeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
        } else {
            
            typeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            
        }
        
        return stack
    }
}
