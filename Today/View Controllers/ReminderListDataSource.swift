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
//    private lazy var dateFormatter = RelativeDateTimeFormatter()
    
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    
    enum Filter: Int {
        case today
        case future
        case all
        
        // The data source should provide cells only for reminders with due dates that match the selected filter.
        // Determine if a given date should be included in a filter.
        func shouldInclude(date: Date) -> Bool {
            let isInToday = Locale.current.calendar.isDateInToday(date)
            switch self {
            case .today:
                return isInToday
            case .future:
                return (date > Date()) && !isInToday
            case .all:
                return true
            }
        }
    }
    
    var filter: Filter = .today
    
    var filteredReminders: [Reminder] {
        return Reminder.testData.filter { filter.shouldInclude(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
    }
    
    // If the current filter doesn’t contain any reminders, the progress view indicates a 100-percent completion rate.
    var percentComplete: Double {
        guard filteredReminders.count > 0 else {
            return 1
        }
        let numComplete: Double = filteredReminders.reduce(0) { (result, reminder) -> Double in
            result + (reminder.isComplete ? 1 : 0)
        }
        return numComplete / Double(filteredReminders.count)
    }
    
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction) {
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        super.init()
    }
    
    // These methods serve as a stable interface you’ll maintain later when your underlying data is no longer a simple array.
    // Update a reminder at row index.
    func update(_ reminder: Reminder, at row: Int) {
        let index = self.index(for: row)
        Reminder.testData[index] = reminder
    }
    
    // Delete reminders from the backing array.
    func delete(at row: Int) {
        let index = self.index(for: row)
        Reminder.testData.remove(at: index)
    }
    
    // Retrieve a reminder for row.
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    // Insert a new reminder at the beginning of the testData array.
    // And return the index of the newly inserted reminder.
    func add(_ reminder: Reminder) -> Int? {
        Reminder.testData.insert(reminder, at: 0)
        return filteredReminders.firstIndex {
            $0.id == reminder.id
        }
    }
    
    // Map indices between the filtered and unfiltered arrays.
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
        guard let index = Reminder.testData.firstIndex(where: { (reminder: Reminder) -> Bool in
            reminder.id == filteredReminder.id
        }) else {
            fatalError("Coudn't retrieve index in source array")
        }
        return index
    }
}

// MARK: - Data Source Methods

// The data source object focuses on fetching, updating, and storing data.
// So use this object to separate the data source logic from the view controller logic.
// Because the superclass of ReminderListDataSource doesn’t conform to UITableViewDataSource, you’re no longer overriding the data source methods.
extension ReminderListDataSource: UITableViewDataSource {
    static let reminderListCellIdentifier = "ReminderListCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReminderListDataSource.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
            fatalError("Unable to dequeue ReminderCell")
        }
        let currentReminder = reminder(at: indexPath.row)
        let dateText = currentReminder.dueDateTimeText(for: filter)
/**
Encapsulate the imformation with access control and the configure method with configure method.
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
        cell.configure(title: currentReminder.title, dateText: dateText, isDone: currentReminder.isComplete) {
            var modifiedReminder = currentReminder
            modifiedReminder.isComplete.toggle()
            self.update(modifiedReminder, at: indexPath.row)
            self.reminderCompletedAction?(indexPath.row)
        }
        return cell
    }
    
    // Enable swipe-to-delete functionality for the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Verify that the user is deleting a row and call the data source’s delete method.
        guard editingStyle == .delete else {
            return
        }
        delete(at: indexPath.row)
        // FIXME: - Why do you need performBatchUpdates here?
        tableView.performBatchUpdates {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } completion: { (_) in
            tableView.reloadData()
        }
        reminderDeletedAction?()
    }
}

extension Reminder {
    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()
    
    static let futureFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    static let todayDateFormatter: DateFormatter = {
        let format = NSLocalizedString("'Today at ' %@", comment: "format string for dates occurring today")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String(format: format, "hh:mm a")
        return dateFormatter
    }()
    
    func dueDateTimeText(for filter: ReminderListDataSource.Filter) -> String {
        let isInToday = Locale.current.calendar.isDateInToday(dueDate)
        switch filter {
        case .today:
            return Self.timeFormatter.string(from: dueDate)
        case .future:
            return Self.futureFormatter.string(from: dueDate)
        case .all:
            if isInToday {
                return Self.todayDateFormatter.string(from: dueDate)
            } else {
                return Self.futureFormatter.string(from: dueDate)
            }
        }
    }
}
