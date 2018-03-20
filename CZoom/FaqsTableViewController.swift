//
//  FaqsTableViewController.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/28/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FaqsTableViewController: MyViewController, UITableViewDelegate, UITableViewDataSource {
	var dataArray = [AnyObject]()

	@IBOutlet weak var tableView: UITableView!

	@IBAction func btnClose(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.delegate = self
		self.tableView.dataSource = self

		setupActivityIndicator()
		loadContent()

		print("Function : \(#function), Class: \(type(of: self))")
	}

	func loadContent() -> Void {
		showActivityIndicator()
		
		self.sessionManager
			.request(URL_FAQS, method: .get)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					self.hideActivityIndicator()

					if let jsonData = response.result.value {
						let json = jsonData as! Dictionary<String,AnyObject>

						if let postList = json["list_post"] {
							self.dataArray = postList as! [AnyObject]
							self.tableView.reloadData()
						}
					}
					break
				case .failure(let error):
					self.hideActivityIndicator()
					self.showMessage(message: error.localizedDescription, OKAction: UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
						self.dismiss(animated: true, completion: nil)
					})
					break
				}
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var numberOfRowsInSection: Int = 0

		if dataArray.isEmpty {
			let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
			noDataLabel.text = LocalizedString("No data available")
			noDataLabel.textColor = UIColor.black
			noDataLabel.textAlignment = .center
			tableView.backgroundView = noDataLabel
			tableView.separatorStyle = .none
		}
		else {
			tableView.separatorStyle = .singleLine
			numberOfRowsInSection = dataArray.count
			tableView.backgroundView = nil
		}

		return numberOfRowsInSection
	}


	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FaqsTableViewCell
		cell.labelTitle.text = dataArray[indexPath.row]["title"] as! String
		return cell
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vcDetail = segue.destination as? FaqsDetailViewController {
			if let indexPath: IndexPath = tableView.indexPathForSelectedRow {
				vcDetail.myTitle = dataArray[indexPath.row]["title"] as! String
				vcDetail.updated = dataArray[indexPath.row]["updated"] as! String
				vcDetail.content = dataArray[indexPath.row]["content"] as! String
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		tableView.estimatedRowHeight = 100
		tableView.rowHeight = UITableViewAutomaticDimension
	}
}
