//
//  EditNotesCell.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class EditNotesCell: UITableViewCell {
    @IBOutlet var notesTextView: UITextView!
    
    func configure(notes: String?) {
        notesTextView.text = notes
    }
}
