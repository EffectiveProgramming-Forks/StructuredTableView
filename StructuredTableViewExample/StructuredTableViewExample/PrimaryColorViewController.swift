//
//  PrimaryColorViewController.swift
//
//  Copyright © 2018 Purgatory Design. Licensed under the MIT License.
//

import UIKit

class PrimaryColorViewController: UIViewController {
	@IBOutlet var tableView: UITableView!
	private let tableDataSource = PrimaryColorDataSource()

	deinit {
		print("PrimaryColorViewController.deinit")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.dataSource = self.tableDataSource
	}
}
