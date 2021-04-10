//
//  EditTitleCell.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class EditTitleCell: UITableViewCell {
    // Using a type alias, you can more easily refer to the closure type (String) -> Void.
    typealias TitleChangeAction = (String) -> Void
    
    @IBOutlet var titleTextField: UITextField!
    
    private var titleChangeAction: TitleChangeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleTextField.delegate = self
    }
    
    func configure(title: String, changeAction: @escaping TitleChangeAction) {
        titleTextField.text = title
        titleChangeAction = changeAction
    }
}

// MARK: - Delegate Methods

// The UITextFieldDelegate protocol defines several methods that the text field calls when the text changes.
extension EditTitleCell: UITextFieldDelegate {
    // This delegate method gives you the updated text after a change.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let originalText = textField.text {
            // Because the delegate method takes an NSRange as a parameter, you use the NSString method replacingCharacters(in:with:), which takes an NSRange parameter.
            let title = (originalText as NSString).replacingCharacters(in: range, with: string)
            // When the user changes the title, the cell calls the closure.
            titleChangeAction?(title)
        }
        return true
    }
}
