//
//  UserSignUp.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/7/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class UserSignUp: MyViewController {
	@IBOutlet weak var tfName: UITextField!
	@IBOutlet weak var tfEmail: UITextField!
	@IBOutlet weak var tfPhone: UITextField!
	@IBOutlet weak var tfPassword: UITextField!

	@IBOutlet weak var btSignUp: UIButton!

	@objc func signUp(_ sender: UIButton) {
		if (tfName.text == "") {
			self.showMessage(message: LocalizedString("Name is required"))
			return;
		}

		let email = tfEmail.text! as String

		if (email == "") {
			self.showMessage(message: LocalizedString("Email address is required"))
			return;
		}

		if (!isValidEmail(email: email)) {
			self.showMessage(message: LocalizedString("Email address is not valid"))
			return;
		}

		if (tfPhone.text == "") {
			self.showMessage(message: LocalizedString("Phone is required"))
			return;
		}

		if (tfPassword.text == "") {
			self.showMessage(message: LocalizedString("Password is required"))
			return;
		}

		let params:Parameters = [
			"email": email,
			"phone": tfPhone.text!,
			"name": tfName.text!,
			"password": tfPassword.text!
		]

		//Sending http post request
		Alamofire
			.request(URL_USER_SIGN_UP, method: .post, parameters: params)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = JSON(jsonData)
						let state = json["state"].numberValue
						let message = json["message"].stringValue

						//print(json.description)

						switch (state) {
						case 0:
							self.showMessage(message: message, OKAction: UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
								self.goToSignIn()
							})
							break;

						case 1:
							var errorMessage:String = message;

							if let errorName = json["input_error"]["name"].string {
								errorMessage = errorName
							}
							else if let errorEmail = json["input_error"]["email"].string {
								errorMessage = errorEmail
							}
							else if let errorPhone = json["input_error"]["phone"].string {
								errorMessage = errorPhone
							}
							else if let errorPassword = json["input_error"]["password"].string {
								errorMessage = errorPassword
							}

							self.showMessage(message: errorMessage)
							break;

						default:
							self.showMessage(message: message)
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

		btSignUp.layer.cornerRadius = 3
		btSignUp.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)

		tfName.delegate = self
		tfEmail.delegate = self
		tfPassword.delegate = self
		tfPhone.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
