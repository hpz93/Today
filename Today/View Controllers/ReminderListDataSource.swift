//
//  ReminderListDataSource.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/8.
//

import UIKit
import EventKit

class ReminderListDataSource: NSObject {
    // Because the property is lazy, the initializer executes the first time the property is accessed.
    // DateFormatter is a powerful class for creating strings from Date values in a variety of formats.
//    private lazy var dateFormatter = RelativeDateTimeFormatter()
    
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    typealias RemindersChangedAction = () -> Void
    
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
//        return Reminder.testData.filter { filter.shouldInclude(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
        
        return reminders.filter { filter.shouldInclude(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
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
    
    // Apps access a user’s calendar and reminder data through an EKEventStore object.
    private let eventStore = EKEventStore()
    
    private var reminders: [Reminder] = []
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    private var remindersChangedAction: RemindersChangedAction?
    
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction, remindersChangedAction: @escaping RemindersChangedAction) {
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        self.remindersChangedAction = remindersChangedAction
        super.init()
        
        requestAccess { (authorized) in
            if authorized {
                self.readAllReminders()
                // Register for EKEventStoreChanged notifications.
                NotificationCenter.default.addObserver(self, selector: #selector(self.storeChanged(_:)),
                                                       name: .EKEventStoreChanged, object: self.eventStore)
            }
        }
    }
    
    // It’s your responsibility to remove observers when they’re no longer used.
    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: self.eventStore)
    }
    
    // Register the data source for notifications to keep the app up to date. Whenever the data source receives a change notification, it’ll reload reminder data from the store.
    @objc
    func storeChanged(_ notification: NSNotification) {
        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
            }
        }
    }
    
    // These methods serve as a stable interface you’ll maintain later when your underlying data is no longer a simple array.
    // Update a reminder at row index.
    func update(_ reminder: Reminder, at row: Int, completion: (Bool) -> Void) {
//        let index = self.index(for: row)
////        Reminder.testData[index] = reminder
//
//        reminders[index] = reminder
        
        // Update the reminder in the reminders array after saving it from the store.
        saveReminder(reminder) { (id) in
            let success = id != nil
            let index = self.index(for: row)
            reminders[index] = reminder
            completion(success)
        }
    }
    
    // Delete reminders from the backing array.
    func delete(at row: Int, completion: (Bool) -> Void) {
//        let index = self.index(for: row)
////        Reminder.testData.remove(at: index)
//
//        reminders.remove(at: index)
        
        let reminder = self.reminder(at: row)
        // Remove the reminder from the reminders array after removing it from the store.
        removeReminder(with: reminder.id) { (success) in
            if success {
                let index = self.index(for: row)
                reminders.remove(at: index)
            }
            completion(success)
        }
    }
    
    // Retrieve a reminder for row.
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    func add(_ reminder: Reminder, completion: (Int?) -> Void) {
//        Reminder.testData.insert(reminder, at: 0)
        
        saveReminder(reminder) { (id) in
            if let id = id {
                let reminder = Reminder(id: id,
                                        title: reminder.title,
                                        dueDate: reminder.dueDate,
                                        notes: reminder.notes,
                                        isComplete: reminder.isComplete)
                reminders.insert(reminder, at: 0)
                let index = filteredReminders.firstIndex { $0.id == id }
                completion(index)
            } else {
                completion(nil)
            }
        }
        
//        reminders.insert(reminder, at: 0)
//        return filteredReminders.firstIndex { $0.id == reminder.id }
    }
    
    // Map indices between the filtered and unfiltered arrays.
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
//        guard let index = Reminder.testData.firstIndex(where: { (reminder: Reminder) -> Bool in
        guard let index = reminders.firstIndex(where: { (reminder: Reminder) -> Bool in
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
            self.update(modifiedReminder, at: indexPath.row) { success in
                if success {
                    self.reminderCompletedAction?(indexPath.row)
                }
            }
        }
        return cell
    }
    
    // Enable swipe-to-delete functionality for the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Verify that the user is deleting a row and call the data source’s delete method.
        guard editingStyle == .delete else {
            return
        }
//        delete(at: indexPath.row)
//        tableView.performBatchUpdates {
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//        } completion: { (_) in
//            tableView.reloadData()
//        }
//        reminderDeletedAction?()
        
        delete(at: indexPath.row) { success in
            if success {
                DispatchQueue.main.async {
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }) { (_) in
                        tableView.reloadData()
                    }
                    self.reminderDeletedAction?()
                }
            }
        }
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

// MARK: - EventKit Framework

extension ReminderListDataSource {
    private var isAvailable: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard currentStatus == .notDetermined else {
            completion(currentStatus == .authorized)
            return
        }
        // Calling this method asynchronously asks users for permission to access their reminders. After users choose their permission level, the event store calls the completion handler, in which you call another completion handler.
        eventStore.requestAccess(to: .reminder) { (success, error) in
            completion(success)
        }
    }
    
    // Fetch reminders from the event store.
    private func readAllReminders() {
        guard isAvailable else { return }
        let predicate = eventStore.predicateForReminders(in: nil)
        // You can pass an empty predicate to retrieve all reminders.
        // The event store returns an optional array of EKReminder objects.
        eventStore.fetchReminders(matching: predicate) { (ekReminders) in
            guard let ekReminders = ekReminders else {
                // Set the data source’s reminders property to an empty array if the store doesn’t return any reminders.
                self.reminders = []
                return
            }
            // Use compactMap(_:) to transform ekReminders into an array of Reminder objects. Set the value of reminders to the converted array.
            self.reminders = ekReminders.compactMap {
                // An EKCalendarItem can have an array of alarms associated with it. You’ll use the absolute date of the first alarm to create a Reminder.
                guard let dueDate = $0.alarms?.first?.absoluteDate else {
                    return nil
                }
                let reminder = Reminder(id: $0.calendarItemIdentifier,
                                        title: $0.title,
                                        dueDate: dueDate,
                                        notes: $0.notes,
                                        isComplete: $0.isCompleted)
                return reminder
            }
            self.remindersChangedAction?()
        }
    }
    
    
    // Retrieve the corresponding reminder from the data store and update its properties to match those of the reminder you’re saving.
    // If the save operation is successful, you’ll pass its calendarItemIdentifier string to the completion closure.
    private func saveReminder(_ reminder: Reminder, completion: (String?) -> Void) {
        guard isAvailable else {
            completion(nil)
            return
        }
        
        // Access the EKReminder in the event store that correspond to the Reminder you're adding.
        readReminder(with: reminder.id) { (ekReminder) in
            // Unwrap the returned EKReminder or create a new one.
            let ekReminder = ekReminder ?? EKReminder(eventStore: self.eventStore)
            ekReminder.title = reminder.title
            ekReminder.notes = reminder.notes
            ekReminder.isCompleted = reminder.isComplete
            ekReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            ekReminder.alarms?.forEach { alarm in
                if let absoluteDate = alarm.absoluteDate {
                    let comparison = Locale.current.calendar.compare(reminder.dueDate, to: absoluteDate, toGranularity: .minute)
                    if comparison != .orderedSame {
                        ekReminder.removeAlarm(alarm)
                    }
                }
            }
            if !ekReminder.hasAlarms {
                ekReminder.addAlarm(EKAlarm(absoluteDate: reminder.dueDate))
            }
            
            do {
                // Use the save(_:commit:) method to save changes to a reminder.
                try self.eventStore.save(ekReminder, commit: true)
                completion(ekReminder.calendarItemIdentifier)
            } catch {
                completion(nil)
            }
        }
    }
    
    private func readReminder(with id: String, completion: (EKReminder?) -> Void) {
        guard isAvailable else {
            completion(nil)
            return
        }
        
        guard let calendarItem = eventStore.calendarItem(withIdentifier: id),
              let ekReminder = calendarItem as? EKReminder else {
            completion(nil)
            return
        }
        
        completion(ekReminder)
    }
    
    private func removeReminder(with id: String, completion: (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }
        
        // Access the EKReminder in the event store that corresponds to the Reminder you’re deleting.
        readReminder(with: id) { (ekReminder) in
            if let ekReminder = ekReminder {
                do {
                    try self.eventStore.remove(ekReminder, commit: true)
                    completion(true)
                } catch {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
