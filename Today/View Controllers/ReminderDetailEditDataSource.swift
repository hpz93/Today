//
//  DetailEditDataSource.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class ReminderDetailEditDataSource: NSObject {
    // ReminderSection contains metadata that the table view needs, such as the section identifiers and the number of sections.
    enum ReminderSection: Int, CaseIterable {
        case title
        case dueDate
        case notes
        
        var displayText: String {
            switch self {
            case .title:
                return "Title"
            case .dueDate:
                return "Date"
            case .notes:
                return "Notes"
            }
        }
        
        // This property returns the number of rows in each section.
        var numRows: Int {
            switch self {
            case .title, .notes: return 1
            case .dueDate: return 2
            }
        }
        
        func cellIdentifier(for row: Int) -> String {
            switch self {
            case .title:
                return "EditTitleCell"
            case .dueDate:
                return row == 0 ? "EditDateLabelCell" : "EditDateCell"
            case .notes:
                return "EditNotesCell"
            }
        }
    }
    
    static var dateLabelCellIdentifier: String {
        return ReminderSection.dueDate.cellIdentifier(for: 0)
    }
    
    var reminder: Reminder
    
    init(reminder: Reminder) {
        self.reminder = reminder
    }
    
    // This helper mehtod helps the data source method tableView(_:cellForRowAt:).
    // It creates new cells for any section in the table view.
    private func dequeueAndConfigureCell(for indexPath: IndexPath, from tableView: UITableView) -> UITableViewCell {
        // Why indexPath.section
        guard let section = ReminderSection(rawValue: indexPath.section) else {
            fatalError("Section index out of range")
        }
        // Why indexPath.row
        let identifier = section.cellIdentifier(for: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        switch section {
        case .title:
            if let titleCell = cell as? EditTitleCell {
                titleCell.configure(title: reminder.title)
            }
        case .dueDate:
            if indexPath.row == 0 {
                cell.textLabel?.text = reminder.dueDate.description
            } else {
                if let dueDateCell = cell as? EditDateCell {
                    dueDateCell.configure(date: reminder.dueDate)
                }
            }
        case .notes:
            if let notesCell = cell as? EditNotesCell {
                notesCell.configure(notes: reminder.notes)
            }
        }
        return cell
    }
}

// MARK: - Data Source Methods

extension ReminderDetailEditDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return ReminderSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ReminderSection(rawValue: section)?.numRows ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dequeueAndConfigureCell(for: indexPath, from: tableView)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = ReminderSection(rawValue: section) else {
            fatalError("Section index out of range")
        }
        return section.displayText
    }
}
