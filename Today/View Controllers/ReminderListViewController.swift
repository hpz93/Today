//
//  ReminderListViewController.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/5.
//

import UIKit

class ReminderListViewController: UITableViewController {
    @IBOutlet var filterSegmentedControl: UISegmentedControl!
    @IBOutlet var percentCompleteHeightConstraint: NSLayoutConstraint!
    @IBOutlet var progressContainerView: UIView!
    @IBOutlet var percentCompleteView: UIView!
    @IBOutlet var percentIncompleteView: UIView!
    
    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    static let mainStoryboardName = "Main"
    static let detailViewControllerIdentifier = "ReminderDetailViewController"

    private var reminderListDataSource: ReminderListDataSource?
    private var filter: ReminderListDataSource.Filter {
        // Enumeration initializer is failable.
        return ReminderListDataSource.Filter(rawValue: filterSegmentedControl.selectedSegmentIndex) ?? .today
    }
    
    // This method notifies the view controller before a segue is performed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showDetailSegueIdentifier,
           let destination = segue.destination as? ReminderDetailViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let rowIndex = indexPath.row
            // Using the API from data source is better than retrieve from model directly.
            guard let reminder = reminderListDataSource?.reminder(at: rowIndex) else {
                fatalError("Couldn't find data source for reminder list.")
            }
//            let reminder = Reminder.testData[indexPath.row]
            
            // Inject the reminder data into the incoming view controller.
            destination.configure(with: reminder, editAction: { reminder in
                self.reminderListDataSource?.update(reminder, at: rowIndex)
                self.tableView.reloadData()
                // The percentage changes, your refresh method animates the change.
                self.refreshProgressView()
            })
        }
    }
    
    // The viewDidLoad() method of UIViewController executes after the view controller loads the view into memory. This method is useful for initialization steps that require the view to be present.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By default, the dataSource property of a UITableViewController refers to itself.
        // Completion handler to update the user interface.
        reminderListDataSource = ReminderListDataSource(reminderCompletedAction: { reminderIndex in
            self.tableView.reloadRows(at: [IndexPath(row: reminderIndex, section: 0)], with: .automatic)
            self.refreshProgressView()
        }, reminderDeletedAction: {
            self.refreshProgressView()
        }, remindersChangedAction: {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshProgressView()
            }
        })
        tableView.dataSource = reminderListDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 0.7 to the width of super view.
        let radius  = view.bounds.size.width * 0.5 * 0.7
        progressContainerView.layer.cornerRadius = radius
        progressContainerView.layer.masksToBounds = true
        refreshProgressView()
        refreshBackground()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navigationController = navigationController,
           navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: animated)
        }
    }
    
    @IBAction func addButtonTriggered(_ sender: UIBarButtonItem) {
        addReminder()
    }
    
    @IBAction func segmentControlChanged(_ sender: UISegmentedControl) {
        reminderListDataSource?.filter = filter
        tableView.reloadData()
        refreshProgressView()
        refreshBackground()
    }
    
    
    private func addReminder() {
        let storyboard = UIStoryboard(name: Self.mainStoryboardName, bundle: nil)
        let detailViewController: ReminderDetailViewController = storyboard.instantiateViewController(identifier: Self.detailViewControllerIdentifier)
        let reminder = Reminder(id: UUID().uuidString, title: "New Reminder", dueDate: Date())
        
        // Because addAction is no longer the last argument in the configure method, you can’t use trailing closure syntax, and you must provide a parameter name.
        detailViewController.configure(with: reminder, isNew: true, addAction: { reminder in
            // Save the new reminder and insert it into the table view.
            // Use the closure capturing values attribute to save data to model.
            if let index = self.reminderListDataSource?.add(reminder) {
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.refreshProgressView()
            }
        })
        
        let navigationController = UINavigationController(rootViewController: detailViewController)
        // Present the navigation controller modally.
        present(navigationController, animated: true, completion: nil)
    }
    
    private func refreshProgressView() {
        guard let percentComplete = reminderListDataSource?.percentComplete else {
            return
        }
        let totalHeight = progressContainerView.bounds.size.height
        percentCompleteHeightConstraint.constant = totalHeight * CGFloat(percentComplete)
        UIView.animate(withDuration: 0.2) {
            self.progressContainerView.layoutSubviews()
        }
    }
    
    // Recreate the background view with a gradient based on the selected filter.
    private func refreshBackground() {
        tableView.backgroundView = nil
        let backgroundView = UIView()
        if let backgroundColors = filter.backgroundColors {
            // Using CAGradientLayer to set the colors for the gradient with an array of CGColor instances.
            let gradientBackgroundLayer = CAGradientLayer()
            gradientBackgroundLayer.colors = backgroundColors
            gradientBackgroundLayer.frame = tableView.frame
            backgroundView.layer.addSublayer(gradientBackgroundLayer)
        } else {
            backgroundView.backgroundColor = filter.substituteBackgroundColor
        }
        tableView.backgroundView = backgroundView
    }
}

fileprivate extension ReminderListDataSource.Filter {
    // The beginning gradient color.
    private var gradientBeginColor: UIColor? {
        switch self {
        case .today: return UIColor(named: "LIST_GradientTodayBegin")
        case .future: return UIColor(named: "LIST_GradientFutureBegin")
        case .all: return UIColor(named: "LIST_GradientAllBegin")
        }
    }
    
    // The ending gradient color.
    private var gradientEndColor: UIColor? {
        switch self {
        case .today: return UIColor(named: "LIST_GradientTodayEnd")
        case .future: return UIColor(named: "LIST_GradientFutureEnd")
        case .all: return UIColor(named: "LIST_GradientAllEnd")
        }
    }
    
    var backgroundColors: [CGColor]? {
        guard let beginColor = gradientBeginColor, let endColor = gradientEndColor else {
            return nil
        }
        // The convenience property cgColor provides a CGColor representation of a UIColor instance.
        return [beginColor.cgColor, endColor.cgColor]
    }
    
    var substituteBackgroundColor: UIColor {
        return gradientBeginColor ?? .tertiarySystemBackground
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
