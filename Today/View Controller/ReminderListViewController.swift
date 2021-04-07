//
//  ReminderListViewController.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/5.
//

import UIKit

class ReminderListViewController: UITableViewController {
}

// MARK: - DataSource Methods

extension ReminderListViewController {
    // The identifier determines which cell to display in the table row.
    static let reminderListCellIdentifier = "ReminderListCell"
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Reminder.testData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeuing a cell optimizes performance because it returns a reusable cell, rather than displaying and removing each cell instance.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
            // Error if it hasn't been implemented yet.
            fatalError("Unable to deque ReminderCell.")
        }
        let reminder = Reminder.testData[indexPath.row]
        let image = reminder.isComplete ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
        cell.titleLabel.text = reminder.title
        cell.dateLabel.text = reminder.dueDate.description
        // Update the Done button to display the appropriate completion status.
        cell.doneButton.setBackgroundImage(image, for: .normal)
        // 
        cell.doneButtonAction = {
            Reminder.testData[indexPath.row].isComplete.toggle()
            // Reload the table rows for completed reminders.
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        return cell
    }
}
