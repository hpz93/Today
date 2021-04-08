//
//  ReminderListViewController.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/5.
//

import UIKit

class ReminderListViewController: UITableViewController {
    private var reminderListDataSource: ReminderListDataSource?
    
    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    
    // This method notifies the view controller before a segue is performed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showDetailSegueIdentifier,
           let destination = segue.destination as? ReminderDetailViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let reminder = Reminder.testData[indexPath.row]
            // Inject the reminder data into the incoming view controller.
            destination.configure(with: reminder)
        }
    }
    
    // The viewDidLoad() method of UIViewController executes after the view controller loads the view into memory. This method is useful for initialization steps that require the view to be present.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By default, the dataSource property of a UITableViewController refers to itself.
        reminderListDataSource = ReminderListDataSource()
        tableView.dataSource = reminderListDataSource
    }
}

// MARK: - Data Source Methods

// Pull the code related to fetching and updating data out of the view controller.
// Extracting the data source logic into its own class separates the concerns of these classes and focuses the view controller on view management.
//extension ReminderListViewController {
//    // The identifier determines which cell to display in the table row.
//    static let reminderListCellIdentifier = "ReminderListCell"
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return Reminder.testData.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        // Dequeuing a cell optimizes performance because it returns a reusable cell, rather than displaying and removing each cell instance.
//        // Use guard let and casting because the cell is a custom cell.
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
//            // Error if it hasn't been implemented yet.
//            fatalError("Unable to deque ReminderCell.")
//        }
//        let reminder = Reminder.testData[indexPath.row]
////        let image = reminder.isComplete ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
////        cell.titleLabel.text = reminder.title
////        cell.dateLabel.text = reminder.dueDate.description
////        // Update the Done button to display the appropriate completion status.
////        cell.doneButton.setBackgroundImage(image, for: .normal)
////        cell.doneButtonAction = {
////            Reminder.testData[indexPath.row].isComplete.toggle()
////            // Reload the table rows for completed reminders.
////            tableView.reloadRows(at: [indexPath], with: .none)
////        }
//        cell.configure(title: reminder.title, dateText: reminder.dueDate.description, isDone: reminder.isComplete) {
//            Reminder.testData[indexPath.row].isComplete.toggle()
//            tableView.reloadRows(at: [indexPath], with: .none)
//        }
//        return cell
//    }
//}
