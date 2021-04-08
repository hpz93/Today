//
//  EditDateCell.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class EditDateCell: UITableViewCell {
    @IBOutlet var datePicker: UIDatePicker!
    
    func configure(date: Date) {
        datePicker.date = date
    }
}
