//
//  UserHome.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/25/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import FacebookLogin
import FacebookCore
import GoogleSignIn

class UserHome: MyViewController, GIDSignInUIDelegate, GIDSignInDelegate {
	@IBOutlet weak var buttonGoogleSignIn: GIDSignInButton!
	@IBOutlet weak var buttonFacebookSignIn: UIButton!
	@IBOutlet weak var buttonEmailSignup: UIButton!

	var firstTrySignIn = false

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		GIDSignIn.sharedInstance().uiDelegate = self
		GIDSignIn.sharedInstance().delegate = self
		GIDSignIn.sharedInstance().clientID = "26793198362-3t7digrnurcvi13ju8cb9bt8ttdej61i.apps.googleusercontent.com"

		self.setupActivityIndicator()
		self.setupButton()

//		if self.isSignedIn() {
//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
//				self.goToMainHome()
//			})
//		}

		self.getSession()
	}

	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
		if (error == nil) {
			// Perform any operations on signed in user here.
			let userId = user.userID                  // For client-side use only!
			let idToken = user.authentication.idToken // Safe to send to the server
			let fullName = user.profile.name
			let givenName = user.profile.givenName
			let familyName = user.profile.familyName
			let email = user.profile.email
			// ...

			let params: Parameters = [
				"username": userId!,
				"password": idToken!,
				"name": fullName!,
				"email": email!,
				"type": "google"
			]

			self.firstTrySignIn = true
			self.signIn(params)
		}
		else {
			self.showMessage(message: error.localizedDescription)
		}
	}

	func signIn(_ params: Parameters) {
		self.showActivityIndicator()

		self.sessionManager
			.request(URL_USER_SIGN_IN, method: .post, parameters: params)
			.responseJSON {
				response in
				self.hideActivityIndicator()

				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						let state = json.value(forKey: "state") as! Int
						let message = json.value(forKey: "message") as? String

						switch (state) {
						case 0:
							if let userData = json.value(forKey: "user") as? NSDictionary {
								self.initSession(userData)
								self.goToMainHome()
							}
							break

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

						case -1:
							if self.firstTrySignIn == true {
								self.firstTrySignIn = false
								self.signUp(params)
							}
							else {
								self.showMessage(message: message!)
							}
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

	func signUp(_ params: Parameters) {
		self.showActivityIndicator()

		var URL = String();

		if let type = params["type"] as? String {
			if type == "facebook" {
				URL = URL_USER_SIGN_UP_FACEBOOK
			}
			else {
				URL = URL_USER_SIGN_UP_GOOGLE
			}
		}

		Alamofire
			.request(URL, method: .post, parameters: params)
			.responseJSON {
				response in
				self.hideActivityIndicator()

				switch response.result {
				case .success:

					if let jsonData = response.result.value {
						let json = JSON(jsonData)
						let state = json["state"].numberValue
						let message = json["message"].stringValue

						switch (state) {
						case 0:
								self.signIn(params)
							break;

						case 1:
							var errorMessage:String = message;

							if let errorUsername = json["input_error"]["username"].string {
								errorMessage = errorUsername
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

	func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!, withError error: Error!) {
		// Perform any operations when the user disconnects from app here.
		// ...
	}

	func setupButton() {
		buttonGoogleSignIn.style = .wide

		buttonFacebookSignIn.layer.cornerRadius = 3
		buttonEmailSignup.layer.cornerRadius = 3

		buttonFacebookSignIn.addTarget(self, action: #selector(facebookSignIn), for: .touchUpInside)
	}

	@objc func facebookSignIn() {
		let loginManager = LoginManager()

		loginManager.logIn(readPermissions: [.publicProfile, .email ], viewController: self) {
			loginResult in
			switch loginResult {
			case .failed(let error):
				self.showMessage(message: error.localizedDescription)
				break

			case .cancelled:
				break

			case .success(let grantedPermissions, let declinedPermissions, let accessToken):
				if (FBSDKAccessToken.current() != nil) {
					self.fetchUserProfile()
				}
				break
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		super.viewWillAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(false, animated: animated)
		super.viewWillDisappear(animated)
	}

	func fetchUserProfile() {
		let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"id, email, name"])

		graphRequest.start(completionHandler: {
			(connection, result, error) -> Void in

			if ((error) != nil) {
				self.showMessage(message: error!.localizedDescription)
			}
			else {
				if let _ = result {
					let json = JSON(result)
					let userId = json["id"].numberValue
					let userName = json["name"].stringValue
					let userEmail = json["email"].stringValue

					let params: Parameters = [
						"username": userId,
						"password": userId,
						"name": userName,
						"email": userEmail,
						"type": "facebook"
					]

					self.firstTrySignIn = true
					self.signIn(params)
				}
			}
		})
	}
}
