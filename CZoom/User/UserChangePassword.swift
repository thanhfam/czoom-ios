//
//  UserChangePassword.swift
//  ZoomGiaoThong
//
//  Created by Thanh Phạm on 1/30/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class UserChangePassword: MyViewController {
	@IBOutlet weak var tfPassword: UITextField!
	@IBOutlet weak var tfPasswordNew: UITextField!
	@IBOutlet weak var tfPasswordConfirm: UITextField!

	@IBOutlet weak var btSave: UIButton!

	@IBAction func btnClose(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	@objc func save(_ sender: UIButton) {
		if (tfPassword.text == "") {
			self.showMessage(message: LocalizedString("Password is required!"))
			return;
		}

		if (tfPasswordNew.text == tfPassword.text) {
			self.showMessage(message: LocalizedString("New password is the same with password!"))
			return;
		}

		if (tfPasswordNew.text == "") {
			self.showMessage(message: LocalizedString("New password is required!"))
			return;
		}

		if (tfPasswordConfirm.text == "") {
			self.showMessage(message: LocalizedString("Confirm new password is required!"))
			return;
		}

		if (tfPasswordConfirm.text != tfPasswordNew.text) {
			self.showMessage(message: LocalizedString("Confirm new password is not the same with new password!"))
			return;
		}

		let params:Parameters = [
			"password": tfPassword.text!,
			"password_new": tfPasswordNew.text!,
			"password_new_confirm": tfPasswordConfirm.text!
		]

		self.sessionManager
			.request(URL_USER_CHANGE_PASSWORD, method: .post, parameters: params)
			.responseJSON {
				response in

				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						let state = json.value(forKey: "state") as! Int
						let message = json.value(forKey: "message") as? String

						switch (state) {
						case 0:
							self.showMessage(message: LocalizedString("Your password has been changed successfully!"))

							self.tfPassword.text = ""
							self.tfPasswordNew.text = ""
							self.tfPasswordConfirm.text = ""
							break;

						case -1:
							self.showMessage(message: message!)
							break;

						case 1:
							var errorMessage:String = message!;

							if let error = json.value(forKey: "input_error") as? NSDictionary {

								if let errorPassword = error.value(forKey: "password") as? String {
									errorMessage = errorPassword
								}
								else if let errorPasswordNew = error.value(forKey: "password_new") as? String {
									errorMessage = errorPasswordNew
								}
								else if let errorPasswordConfirm = error.value(forKey: "password_new_confirm") as? String {
									errorMessage = errorPasswordConfirm
								}
							}
							self.showMessage(message: errorMessage)
							break;

						case 2, 3:
							self.signOut()
							break;

						default:
							self.showMessage(message: message!)
							break;
						}
					}
					break
				case .failure(let error):
					self.showMessage(message: error.localizedDescription)
					break
				}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("Change password")

		print("Function : \(#function), Class: \(type(of: self))")

		btSave.layer.cornerRadius = 3
		btSave.setTitle(LocalizedString("Save"), for: .normal)
		btSave.addTarget(self, action: #selector(save(_:)), for: .touchUpInside)

		tfPassword.delegate = self
		tfPasswordNew.delegate = self
		tfPasswordConfirm.delegate = self
	}
}


