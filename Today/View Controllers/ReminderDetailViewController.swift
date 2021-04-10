//
//  ReminderDetailViewController.swift
//  Today
//
//  Created by 莊皓平 on 2021/4/7.
//

import UIKit

class ReminderDetailViewController: UITableViewController {
//    // The CaseIterable protocol provides a property named allCases that you can use to iterate through the cases of the conforming enumeration.
//    // Use this enumeration as you configure your table view cells.
//    // Because the enumeration stores raw values, each case has a sequentially increasing integer raw value starting at 0.
//    enum ReminderRow: Int, CaseIterable {
//        case title
//        case date
//        case time
//        case notes
//        
//        // This method returns the appropriate text to display based on the current enumeration case.
//        func displayText(for reminder: Reminder?) -> String? {
//            switch self {
//            case .title:
//                return reminder?.title
//            case .date:
//                return reminder?.dueDate.description
//            case .time:
//                return reminder?.dueDate.description
//            case .notes:
//                return reminder?.notes
//            }
//        }
//        
//        // This property returns the appropriate image to display based on the current enumeration case.
//        var cellImage: UIImage? {
//            switch self {
//            case .title:
//                return nil
//            case .date:
//                return UIImage(systemName: "calender.circle")
//            case .time:
//                return UIImage(systemName: "clock")
//            case .notes:
//                return UIImage(systemName: "square.and.pencil")
//            }
//        }
//    }
    typealias ReminderChangeAction = (Reminder) -> Void
    
    private var reminder: Reminder?
    private var tempReminder: Reminder?
//    private var detailViewDataSource: ReminderDetailViewDataSource?
    private var dataSource: UITableViewDataSource?
    private var reminderEditAction: ReminderChangeAction?
    private var reminderAddAction: ReminderChangeAction?
    private var isNew = false
    
    //  When initializing a view controller from a storyboard, iOS calls the init(coder:) initializer. This configure method approach is useful for configuring after initializing, such as injecting dependencies.
    func configure(with reminder: Reminder, isNew: Bool = false, addAction: ReminderChangeAction? = nil, editAction: ReminderChangeAction? = nil) {
        self.reminder = reminder
        self.isNew = isNew
        self.reminderAddAction = addAction
        self.reminderEditAction = editAction
        
        // If the view hasn't been loaded ever, isViewLoaded will be false.
        // Every view is only loaded into memory one time.
        // isViewLoaded is a property that returns true only after the view hierarchy loads.
        if isViewLoaded {
            setEditing(isNew, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // If you were responding to a user action, you would animate the call to setEditing(_:animated:) by passing true. Because UIKit calls viewDidLoad() as part of the initial setup, and not in response to a user action, you turn off the animation.
        setEditing(isNew, animated: false)
        navigationItem.setRightBarButton(editButtonItem, animated: false)
        // The table view requires a reuse identifier to retrieve a cell with dequeueReusableCell(withIdentifier:for:). Passing an unregistered identifier to that method raises an exception and terminates the app.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReminderDetailEditDataSource.dateLabelCellIdentifier)
        
//        detailViewDataSource = ReminderDetailViewDataSource(reminder: reminder)
//        tableView.dataSource = detailViewDataSource
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navigationController = navigationController, !navigationController.isToolbarHidden {
//            navigationController.isToolbarHidden = true
            navigationController.setToolbarHidden(true, animated: animated)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard let reminder = reminder else {
            fatalError("No reminder found for detail view")
        }
        // If editing is true, set the dataSource property to a new edit data source.
        if editing {
            dataSource = ReminderDetailEditDataSource(reminder: reminder) { reminder in
                self.tempReminder = reminder
                self.editButtonItem.isEnabled = true
            }
            // Change the navigation title to Edit Reminder if the table is in edit mode and to View Reminder if it is not.
            navigationItem.title = isNew ? NSLocalizedString("Add Reminder", comment: "add reminder nav title") : NSLocalizedString("Edit Reminder", comment: "edit reminder nav title")
            // Add a Cancel button to the navigation bar.
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTrigger))
        } else {
            // Sets the reminder data and the data source.
            if let tempReminder = tempReminder {
                self.reminder = tempReminder
                self.tempReminder = nil
                // Call the change action to update other views.
                reminderEditAction?(tempReminder)
                dataSource = ReminderDetailViewDataSource(reminder: tempReminder)
            } else {
                dataSource = ReminderDetailViewDataSource(reminder: reminder)
            }
            navigationItem.title = NSLocalizedString("View Reminder", comment: "view reminder nav title")
            // Remove the Cancel button from view mode.
            navigationItem.leftBarButtonItem = nil
            // Enable the Edit button when the table view is in view mode.
            editButtonItem.isEnabled = true
        }
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    // The attribute @objc makes the function callable from a selector that you define using #selector.
    @objc
    func cancelButtonTrigger() {
        setEditing(false, animated: true)
    }
}

// MARK: - Data Source Methods

//extension ReminderDetailViewController {
//    static var reminderDetailViewController = "ReminderDetailCell"
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return ReminderRow.allCases.count
//    }
//
//    // Because the enumeration encapsulates the displayText(for:) method and image property, the data source method can focus on cell configuration.
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderDetailViewController, for: indexPath)
//        let row = ReminderRow(rawValue: indexPath.row)
//        cell.textLabel?.text = row?.displayText(for: reminder)
//        cell.imageView?.image = row?.cellImage
//        return cell
//    }
//}
