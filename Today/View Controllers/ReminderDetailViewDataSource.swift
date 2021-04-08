//
//  ReminderDetailViewDataSource.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class ReminderDetailViewDataSource: NSObject {
    // The CaseIterable protocol provides a property named allCases that you can use to iterate through the cases of the conforming enumeration.
    // Use this enumeration as you configure your table view cells.
    // Because the enumeration stores raw values, each case has a sequentially increasing integer raw value starting at 0.
    enum ReminderRow: Int, CaseIterable {
        case title
        case date
        case time
        case notes
        
        // Formats a date with the short presentation of the time and no date.
        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }()
        
        // Formats a date with the long presentation of the date and no time.
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .long
            return formatter
        }()
        
        // This method returns the appropriate text to display based on the current enumeration case.
        func displayText(for reminder: Reminder?) -> String? {
            switch self {
            case .title:
                return reminder?.title
            case .date:
//                return reminder?.dueDate.description
                guard let date = reminder?.dueDate else { return nil }
                return Self.dateFormatter.string(from: date)
            case .time:
//                return reminder?.dueDate.description
                guard let date = reminder?.dueDate else { return nil }
                return Self.timeFormatter.string(from: date)
            case .notes:
                return reminder?.notes
            }
        }
        
        // This property returns the appropriate image to display based on the current enumeration case.
        var cellImage: UIImage? {
            switch self {
            case .title:
                return nil
            case .date:
                return UIImage(systemName: "calender.circle")
            case .time:
                return UIImage(systemName: "clock")
            case .notes:
                return UIImage(systemName: "square.and.pencil")
            }
        }
    }
    
    private var reminder: Reminder
    
    init(reminder: Reminder) {
        self.reminder = reminder
        // Swift requires you to initialize all stored properties before calling super.init().
        super.init()
    }
}

extension ReminderDetailViewDataSource: UITableViewDataSource {
    static let reminderDetailCellIdentifier = "ReminderDetailCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ReminderRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReminderDetailViewDataSource.reminderDetailCellIdentifier, for: indexPath)
        let row = ReminderRow(rawValue: indexPath.row)
        cell.textLabel?.text = row?.displayText(for: reminder)
        cell.imageView?.image = row?.cellImage
        return cell
    }
}
