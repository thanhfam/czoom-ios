//
//  MyViewController.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/20/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MyViewController: UIViewController, UITextFieldDelegate {
	let defaultValues = UserDefaults.standard

	var configuration: URLSessionConfiguration! = nil
	var sessionManager: SessionManager! = nil

	let activityIndicator = UIActivityIndicatorView()
	let activityIndicatorContainer = UIView(), activityIndicatorBackground = UIView()

	override func viewDidLoad() {
		super.viewDidLoad()
		//print("Function : \(#function), Class: \(type(of: self)), File: \(#file)")
		print("Function : \(#function), Class: \(type(of: self))")

		if (self.sessionManager == nil) {
			self.configuration = URLSessionConfiguration.default
			self.sessionManager = Alamofire.SessionManager(configuration: configuration)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func setupActivityIndicator() -> Void {
		activityIndicatorContainer.frame = self.view.frame
		activityIndicatorContainer.center = self.view.center
		activityIndicatorContainer.backgroundColor = UIColor(hex: 0xffffff).withAlphaComponent(0.3)
		activityIndicatorContainer.alpha = 0

		activityIndicatorBackground.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		activityIndicatorBackground.center = activityIndicatorContainer.center
		activityIndicatorBackground.backgroundColor = UIColor(hex: 0x444444).withAlphaComponent(0.7)
		activityIndicatorBackground.clipsToBounds = true
		activityIndicatorBackground.layer.cornerRadius = 10

		activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
		activityIndicator.activityIndicatorViewStyle = .whiteLarge
		activityIndicator.center = CGPoint(x: activityIndicatorBackground.frame.width / 2, y: activityIndicatorBackground.frame.height / 2)
		activityIndicatorBackground.addSubview(activityIndicator)
		activityIndicatorContainer.addSubview(activityIndicatorBackground)
		self.view.addSubview(activityIndicatorContainer)
	}

	func showActivityIndicator() -> Void {
		activityIndicator.startAnimating()
		activityIndicatorContainer.alpha = 1
		UIApplication.shared.beginIgnoringInteractionEvents()
	}

	func hideActivityIndicator() -> Void {
		activityIndicator.stopAnimating()
		activityIndicatorContainer.alpha = 0
		UIApplication.shared.endIgnoringInteractionEvents()
	}

	func setupMenu() -> Void {
		if self.revealViewController() != nil {
//			let button = UIButton(type: .custom)
//			button.setImage(UIImage(named: "menu"), for: .normal)
//			button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
//			button.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
//
//			self.btMenu = UIBarButtonItem(customView: button)

//			self.revealViewController().setFront(self, animated: true)

			self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
//			self.tabBarController?.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
//			self.navigationController?.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())

			self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
//			self.tabBarController?.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
//			self.navigationController?.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
		}
	}

	func showMessage(message: String, OKAction: UIAlertAction? = nil) {
		let alertController = UIAlertController(title: LocalizedString("Alert"), message: message, preferredStyle: .alert)
		
		if let OKAction = OKAction {
			alertController.addAction(OKAction)
		}
		else {
			alertController.addAction(UIAlertAction(title: LocalizedString("OK"), style: .default, handler: nil))
		}
		
		self.present(alertController, animated: true, completion:nil)
	}

	func askForSettingMessage(type: String) {
		let alertController = UIAlertController(title: LocalizedString("Alert"), message: String(format: LocalizedString("You should enable setting for %@ to use this function!"), LocalizedString(type)), preferredStyle: .alert)

		let settingsAction = UIAlertAction(title: String(format: LocalizedString("%@ settings"), LocalizedString(type)), style: .default) { (_) -> Void in
			var settingURL = "App-Prefs:root="
			switch type {
			case "Location":
				settingURL += "LOCATION_SERVICES"
				break
			default:
				settingURL += "General"
				break
			}

			if UIApplication.shared.canOpenURL(URL(string: settingURL)!) {
				UIApplication.shared.open(URL(string: settingURL)!, completionHandler: { (success) in
					print("Settings opened: \(success)") // Prints true
				})
			}
		}
		alertController.addAction(settingsAction)

		let cancelAction = UIAlertAction(title: LocalizedString("Cancel"), style: .default, handler: nil)
		alertController.addAction(cancelAction)

		self.present(alertController, animated: true, completion: nil)
	}

	func animateTextField(textField: UITextField, up: Bool) {
		let movementDistance: CGFloat = -130
		let movementDuration: Double = 0.3

		var movement: CGFloat = 0
		if up {
			movement = movementDistance
		}
		else {
			movement = -movementDistance
		}
		UIView.beginAnimations("animateTextField", context: nil)
		UIView.setAnimationBeginsFromCurrentState(true)
		UIView.setAnimationDuration(movementDuration)
		self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
		UIView.commitAnimations()
	}

	func textFieldDidBeginEditing(_ textField: UITextField) {
		self.animateTextField(textField: textField, up: true)
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		self.animateTextField(textField: textField, up: false)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	func goToSignUp() -> Void {
		self.performSegue(withIdentifier: "show_sign_up", sender: nil)
	}
	
	func goToSignIn() -> Void {
		self.performSegue(withIdentifier: "show_sign_in", sender: nil)
	}
	
	func goToMainHome() -> Void {
		self.performSegue(withIdentifier: "show_main_home", sender: nil)
	}
	
	func goToUserHome() -> Void {
		self.performSegue(withIdentifier: "show_user_home", sender: nil)
	}
	
	func go(to: UIViewController) -> Void {
		present(to, animated: true, completion: nil)
	}
	
	func navigate(to: UIViewController) -> Void {
	}

	func initSession(_ userData: NSDictionary) {
		//getting user values
		if let userId = (userData.value(forKey: "id") as? NSString)?.intValue {
			self.defaultValues.set(userId, forKey: "userId")
		}
		else {
			self.defaultValues.set("", forKey: "userId")
		}

		if let userName = userData.value(forKey: "name") as? String {
			self.defaultValues.set(userName, forKey: "userName")
		}
		else {
			self.defaultValues.set("", forKey: "userName")
		}

		if let userEmail = userData.value(forKey: "email") as? String {
			self.defaultValues.set(userEmail, forKey: "userEmail")
		}
		else {
			self.defaultValues.set("", forKey: "userEmail")
		}

		if let userPhone = userData.value(forKey: "phone") as? String {
			self.defaultValues.set(userPhone, forKey: "userPhone")
		}
		else {
			self.defaultValues.set("", forKey: "userPhone")
		}

		if let userAvatar = userData.value(forKey: "avatar_url") as? String {
			self.defaultValues.set(userAvatar, forKey: "userAvatar")
		}
		else {
			self.defaultValues.set("", forKey: "userAvatar")
		}
	}

	func getSession() {
		print("getSession")
		//Sending http post request
		Alamofire
			.request(URL_USER_GET_SESSION, method: .post, parameters: nil)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary
						let state = json.value(forKey: "state") as! Int

						switch (state) {
						case 0:
							if let userData = json.value(forKey: "user") as? NSDictionary {
								self.initSession(userData)
								self.goToMainHome()
							}
							break

						default:
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

	func isSignedIn() -> Bool {
		self.showActivityIndicator()
		if let _ = defaultValues.string(forKey: "userId") {
			self.hideActivityIndicator()
			return true
		}
		else {
			self.hideActivityIndicator()
			return false
		}
	}
	
	func signOut() -> Void {
		UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
		UserDefaults.standard.synchronize()

		Alamofire
			.request(URL_USER_SIGN_OUT, method: .post, parameters: nil)
			.responseString {
				response in
				self.goToUserHome()
		}
	}
}
