//
//  ReminderListCell.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/7.
//

import UIKit

class ReminderListCell: UITableViewCell {
    
    // Type aliases are helpful for referring to an existing type with a name that’s more expressive.
    
    typealias DoneButtonAction = () -> Void
    
    // Using strong reference types for all outlets in this cell prevents changes in the size class from deallocating objects.
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var done: UIButton!
    
    var doneButtonAction: DoneButtonAction?
    
    // The IBAction attribute indicates that the instance method can connect to your UI file. When the system loads your view hierarchy, it uses that connection information to set your action method as the target of the view.
    
    @IBAction func doneButtonTriggered(_ sender: UIButton) {
        doneButtonAction?()
    }
}
