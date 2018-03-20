//
//  UserSignIn.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/7/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class UserSignIn: MyViewController {
	@IBOutlet weak var tfUsername: UITextField!
	@IBOutlet weak var tfPassword: UITextField!
	@IBOutlet weak var btSignIn: UIButton!

	@objc func signIn(_ sender: UIButton) {
		let username = tfUsername.text! as String, password = tfPassword.text! as String

		if (username == "") {
			self.showMessage(message: LocalizedString("Username is required"))
			return;
		}

		if (password == "") {
			self.showMessage(message: LocalizedString("Password is required"))
			return;
		}

		let params:Parameters = [
			"username": username,
			"password": password
		]

		self.sessionManager
			.request(URL_USER_SIGN_IN, method: .post, parameters: params)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						let state = json.value(forKey: "state") as! Int
						let message = json.value(forKey: "message") as? String

//						print(json.description)

						switch (state) {
						case 0:
							if let userData = json.value(forKey: "user") as? NSDictionary {
								self.initSession(userData)
								self.goToMainHome()
							}
							break;

						case 1:
							var errorMessage:String = message!;

							if let error = json.value(forKey: "input_error") as? NSDictionary {

								if let errorUsername = error.value(forKey: "username") as? String {
									errorMessage = errorUsername
								}
								else if let errorPassword = error.value(forKey: "password") as? String {
									errorMessage = errorPassword
								}

							}
							self.showMessage(message: errorMessage)
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
		// Do any additional setup after loading the view, typically from a nib.

		btSignIn.layer.cornerRadius = 3
		btSignIn.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)

		tfUsername.delegate = self
		tfPassword.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
