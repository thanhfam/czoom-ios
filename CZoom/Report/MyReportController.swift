//
//  MyReport.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/9/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AVKit
import AVFoundation

class MyReportController: MyViewController, UITableViewDataSource, UITableViewDelegate {
	var dataArray = [AnyObject]()
	var reportArray = [Report]()

	var firstLoad = true

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var buttonMenu: UIBarButtonItem!

	lazy var refreshControl = UIRefreshControl()

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("My reports")

		self.setupActivityIndicator()
		self.setupButton()

		self.setupReportList()
		self.loadReportList()
	}

	override func viewWillAppear(_ animated: Bool) {
		self.setupMenu()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func setupButton() {
		self.buttonMenu.target = self.revealViewController()
		self.buttonMenu.action = #selector(SWRevealViewController.revealToggle(_:))
	}

	func setupReportList() {
		self.tableView.delegate = self
		self.tableView.dataSource = self

		self.tableView.estimatedRowHeight = 100
		self.tableView.rowHeight = UITableViewAutomaticDimension

		self.tableView.separatorColor = UIColor.clear
		self.tableView.allowsSelection = false

		refreshControl.attributedTitle = NSAttributedString(string: LocalizedString("Pull to refresh"))
		refreshControl.addTarget(self, action: #selector(refreshReportList(_:)), for: .valueChanged)
		self.tableView.addSubview(refreshControl) // not required when using UITableViewController
	}

	@objc func refreshReportList(_ sender:AnyObject) {
		self.loadReportList()
		self.refreshControl.endRefreshing()
	}

	func loadReportList() -> Void {
		self.showActivityIndicator()

		self.sessionManager
			.request(URL_REPORT_MINE, method: .get)
			.responseJSON {
				response in
				self.hideActivityIndicator()

				switch response.result {
				case .success:

					if (self.firstLoad) {
						self.firstLoad = false
					}
					
					if let jsonData = response.result.value {
						let json = jsonData as! Dictionary<String,AnyObject>

						if let reportList = json["list"] {
							self.dataArray.removeAll()
							self.reportArray.removeAll()
							self.dataArray = reportList as! [AnyObject]

							for reportData in self.dataArray {
								let report: Report = Report(reportData)
								self.reportArray.append(report)
							}

							self.tableView.reloadData()
						}
					}
					break
				case .failure(let error):
					self.showMessage(message: error.localizedDescription, OKAction: UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
						self.dismiss(animated: true, completion: nil)
					})
					break
				}
		}
	}

	//	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
	//		return 425
	//	}

	func removeReport(_ indexPath: IndexPath) {
		self.showActivityIndicator()

		let removeIndex = indexPath.row

		if reportArray.indices.contains(removeIndex) == false {
			return
		}

		let removeReport = reportArray[removeIndex]

		let params:Parameters = [
			"id": removeReport.id
		]

		self.sessionManager
			.request(URL_REPORT_REMOVE, method: .post, parameters: params)
			.responseJSON {
				response in
				print(response)
				self.hideActivityIndicator()

				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						let state = json.value(forKey: "state") as! Int
						let message = json.value(forKey: "message") as? String

						switch (state) {
						case 0:
							self.reportArray.remove(at: removeIndex)
							self.tableView.deleteRows(at: [indexPath], with: .automatic)
							break

						case 1:
							var errorMessage:String = message!;

							if let error = json.value(forKey: "input_error") as? NSDictionary {
								if let errorContentId = error.value(forKey: "id") as? String {
									errorMessage = errorContentId
								}
							}
							self.showMessage(message: errorMessage)
							break

						case 2, 3:
							self.signOut()
							break

						default:
							self.showMessage(message: message!)
							break
						}
					}
					break
				case .failure(let error):
					self.showMessage(message: error.localizedDescription)
					break
				}
		}
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == UITableViewCellEditingStyle.delete) {
			self.removeReport(indexPath)
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if firstLoad {
			return reportArray.count
		}

		var numberOfRowsInSection: Int = 0

		if reportArray.isEmpty {
			let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
			noDataLabel.text = LocalizedString("No data available")
			noDataLabel.textColor = UIColor.black
			noDataLabel.textAlignment = .center
			tableView.backgroundView = noDataLabel
			tableView.separatorStyle = .none

		}
		else {
			tableView.separatorStyle = .singleLine
			numberOfRowsInSection = reportArray.count
			tableView.backgroundView = nil
		}

		return numberOfRowsInSection
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ReportCell
		cell.tag = indexPath.row

		let report = reportArray[cell.tag];
		cell.setIndex(cell.tag)
		cell.setReport(report)
		cell.render()

		let tapRec = UITapGestureRecognizer()
		tapRec.addTarget(self, action: #selector(viewDetail(_:)))
		cell.setTapRec(tapRec)
		
		return cell

	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
	}

	func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
	}

	public func updateReport(report: Report) {
		for i in 1..<reportArray.count  {
			if reportArray[i].id == report.id {
				reportArray[i].totalLike = report.totalLike
				reportArray[i].totalComment = report.totalComment

				self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .fade)

				break
			}
		}
	}

	@objc func viewDetail(_ tapGesture: UITapGestureRecognizer) {
		let imageView = tapGesture.view as! UIImageView

		self.performSegue(withIdentifier: "view_report", sender: imageView)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vcDetail = segue.destination as? ViewReport {
			var index = Int()

			if let senderObject = sender as? UIButton {
				index = senderObject.tag
			}
			else if let senderObject = sender as? UIImageView {
				index = senderObject.tag
			}
			else {
				return
			}

			vcDetail.report = reportArray[index]
			vcDetail.viewParent = self
		}
	}

	@IBAction func unwindToAllReportController(segue: UIStoryboardSegue) {
		if let source = segue.source as? ViewReport {
			if let report: Report? = source.report {
				updateReport(report: report!)
			}
		}
	}
}
