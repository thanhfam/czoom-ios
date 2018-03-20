//
//  MenuController.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/20/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import Foundation

class MenuController: MyViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var imageAvatar: UIImageView!
	@IBOutlet weak var tfName: UITextField!
	@IBOutlet weak var labelName: UILabel!
	@IBOutlet weak var labelEmail: UILabel!
	@IBOutlet weak var buttonSignout: UIButton!

	var menuArray = [[String:String]]()

	override func viewDidLoad() {
		self.tableView.delegate = self
		self.tableView.dataSource = self

		setupMenuItem()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUserInformation()
	}

	func setupMenuItem() {
		menuArray = [
			["title": LocalizedString("Gift"), "id": "gift", "segue": "show_gift"],
			["title": LocalizedString("About us"), "id": "about_us", "segue": "show_about_us"],
			["title": LocalizedString("How to"), "id": "how_to", "segue": "show_how_to"],
			["title": LocalizedString("FAQs"), "id": "faqs", "segue": "show_faqs"],
			["title": LocalizedString("Rate us"), "id": "rate_us", "segue": "show_rate_us"],
			["title": LocalizedString("Change password"), "id": "change_password", "segue": "show_change_password"]
		]
	}

	func setupUserInformation() {
		if let userName = self.defaultValues.string(forKey: "userName") {
			self.labelName.text = userName
		}

		if let userEmail = self.defaultValues.string(forKey: "userEmail") {
			self.labelEmail.text = userEmail
		}

		if let userAvatar = self.defaultValues.string(forKey: "userAvatar"), !userAvatar.isEmpty {
			self.imageAvatar.setImage(url: URL(string: userAvatar)!)
			self.imageAvatar.contentMode = .scaleAspectFill
			self.imageAvatar.clipsToBounds = true
			self.imageAvatar.layer.cornerRadius = 3
		}

		buttonSignout.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
	}

	@objc func signOut(_ sender: UIButton) {
		super.signOut()
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return menuArray.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
		cell.textLabel?.text = menuArray[indexPath.row]["title"]
		return cell
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if let ncNext = segue.destination as? UINavigationController {
//			if let vcNext: MainHome = ncNext.topViewController as? MainHome {
//				vcNext.selectedMenu = sender as? [String:String]
//			}
//		}
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		if let selectedRow: IndexPath = tableView.indexPathForSelectedRow {
			let selectedMenu = menuArray[selectedRow.row]

			switch selectedMenu["id"] as String! {
				case "sign_out":
					self.signOut()
					break;

			case "rate_us", "about_us", "how_to", "faqs", "change_password", "gift":
					self.performSegue(withIdentifier: selectedMenu["segue"] as String!, sender: nil)
					break;

				case .none:
					break;

				case .some(_):
					break;

				default:
					break;
			}
		}
	}
}
