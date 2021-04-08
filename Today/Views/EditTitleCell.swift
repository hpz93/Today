//
//  EditTitleCell.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class EditTitleCell: UITableViewCell {
    @IBOutlet var titleTextField: UITextField!
    
    func configure(title: String) {
        titleTextField.text = title
    }
}
