//
//  PostReportCategoryList.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/17/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import Foundation

import UIKit
import Alamofire
import SwiftyJSON

class PostReportCategoryList: MyViewController, UITableViewDelegate, UITableViewDataSource {
	var mediaArray: [MyMedia]? = nil

	var dataArray: [AnyObject] = [AnyObject]()

	@IBOutlet weak var tableView: UITableView!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("Choose a category")

		self.tableView.delegate = self
		self.tableView.dataSource = self

		setupActivityIndicator()
		loadContent()

		print("Function : \(#function), Class: \(type(of: self))")
	}

	func loadContent() -> Void {
		showActivityIndicator()

		self.sessionManager
			.request(URL_REPORT_GET_CATEGORY, method: .get)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					self.hideActivityIndicator()

					if let jsonData = response.result.value {
						let json = jsonData as! Dictionary<String,AnyObject>

						if let list = json["list"] {
							self.dataArray = list as! [AnyObject]
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
		return dataArray.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostReportCategoryCell
		let cellData = dataArray[indexPath.row]

		cell.labelTitle.text = cellData["title"] as! String

		if let avatarURL = cellData["avatar_url"] as? String, !avatarURL.isEmpty {
			cell.imageAvatar.setImage(url: URL(string: avatarURL)!)
		}
		else {
			cell.imageAvatar.image = UIImage(named: "no_image")
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		if let selectedRow: IndexPath = tableView.indexPathForSelectedRow {
			let categoryId = (dataArray[selectedRow.row]["id"] as! NSString).intValue

			self.performSegue(withIdentifier: "upload_report", sender: categoryId)
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "upload_report" {
			if let vcUploadReport = segue.destination as? PostReportUpload {
				vcUploadReport.categoryId = sender as! Int
				vcUploadReport.mediaArray = mediaArray
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		tableView.estimatedRowHeight = 100
		tableView.rowHeight = UITableViewAutomaticDimension
	}
}
