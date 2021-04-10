//
//  ReminderListDataSource.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit

class ReminderListDataSource: NSObject {
    // Because the property is lazy, the initializer executes the first time the property is accessed.
    // DateFormatter is a powerful class for creating strings from Date values in a variety of formats.
    private lazy var dateFormatter = RelativeDateTimeFormatter()
    
    // These methods serve as a stable interface you’ll maintain later when your underlying data is no longer a simple array.
    // Update a reminder at row index.
    func update(_ reminder: Reminder, at row: Int) {
        Reminder.testData[row] = reminder
    }
    
    // Retrieve a reminder for row.
    func reminder(at row: Int) -> Reminder {
        return Reminder.testData[row]
    }
}

// MARK: - Data Source Methods

// The data source object focuses on fetching, updating, and storing data.
// So use this object to separate the data source logic from the view controller logic.
// Because the superclass of ReminderListDataSource doesn’t conform to UITableViewDataSource, you’re no longer overriding the data source methods.
extension ReminderListDataSource: UITableViewDataSource {
    static let reminderListCellIdentifier = "ReminderListCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Reminder.testData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReminderListDataSource.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
            fatalError("Unable to dequeue ReminderCell")
        }
        let reminder = Reminder.testData[indexPath.row]
        let dateText = dateFormatter.localizedString(for: reminder.dueDate, relativeTo: Date())
/**
Encapsulate the imformation with access control and the configure method.
//         let image = reminder.isComplete ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
//        cell.titleLabel.text = reminder.title
//        cell.dateLabel.text = reminder.dueDate.description
//        // Update the Done button to display the appropriate completion status.
//        cell.doneButton.setBackgroundImage(image, for: .normal)
//        cell.doneButtonAction = {
//            Reminder.testData[indexPath.row].isComplete.toggle()
//            // Reload the table rows for completed reminders.
//            tableView.reloadRows(at: [indexPath], with: .none)
//        }
*/
        cell.configure(title: reminder.title, dateText: dateText, isDone: reminder.isComplete) {
            Reminder.testData[indexPath.row].isComplete.toggle()
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        return cell
    }
}
