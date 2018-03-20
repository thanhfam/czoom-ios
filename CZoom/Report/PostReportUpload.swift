//
//  PostReportUpload.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/17/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MapKit
import CoreLocation

class MyLocation: NSObject {
	var location: CLLocation!
	var placemark: String!
}

class PostReportUpload: MyViewController, CLLocationManagerDelegate {
	@IBOutlet weak var tfComment: UITextField!
	@IBOutlet weak var tfLocation: UITextField!
	@IBOutlet weak var buttonUpload: UIButton!

	var userLocation: MyLocation! = MyLocation()

	var categoryId: Int? = nil
	var attachmentId = [Int]()

	var mediaArray: [MyMedia]? = nil

	var locationManager = CLLocationManager()

	override func viewDidLoad() {
		super.viewDidLoad()

		setupActivityIndicator()
		setupButton()
		setupLocationManager()

		self.tfComment.delegate = self
		self.tfLocation.delegate = self

		self.navigationItem.title = LocalizedString("Upload")

		print("Function : \(#function), Class: \(type(of: self))")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func setupButton() {
		buttonUpload.addTarget(self, action: #selector(uploadReport(sender:)), for: .touchUpInside)
		buttonUpload.layer.cornerRadius = 3

		let button = UIButton(type: .custom)
		button.setImage(UIImage(named: "location_marker.png"), for: .normal)
		button.frame = CGRect(x: CGFloat(tfLocation.frame.size.width - 20), y: CGFloat(0), width: CGFloat(20), height: CGFloat(20))
		button.addTarget(self, action: #selector(self.showLocationView), for: .touchUpInside)

		tfLocation.rightView = button
		tfLocation.rightViewMode = .always
	}

	func setupLocationManager() {
		self.locationManager.delegate = self

		switch CLLocationManager.authorizationStatus() {
			case .notDetermined:
				// Request when-in-use authorization initially
				self.locationManager.requestWhenInUseAuthorization()
				break

			case .authorizedWhenInUse, .authorizedAlways:
				// Enable basic location features
				self.startUpdatingLocation()
				break

			case .restricted, .denied:
				self.askForSettingMessage(type: "Location")
		}
	}

	func startUpdatingLocation() {
		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.distanceFilter = kCLDistanceFilterNone
			self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
			self.locationManager.startUpdatingLocation()
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		self.userLocation!.location = locations.last as! CLLocation

		getPlacemark(forLocation: self.userLocation!.location, completionHandler: {
			(originPlacemark, error) in
			if let err = error {
				print(err)
			}
			else if let placemark = originPlacemark {
				self.userLocation!.placemark = addressFromPlacemark(placemark)
				self.tfLocation.text = self.userLocation!.placemark
			}
		})

		locationManager.stopUpdatingLocation()
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .restricted, .denied:
			// Disable your app's location features
			break

		case .authorizedWhenInUse, .authorizedAlways:
			// Enable only your app's when-in-use features.
			self.startUpdatingLocation()
			break

		case .notDetermined:
			break
			}
	}

	func uploadFile() {
		if (mediaArray?.isEmpty == false) {
			let url = try! URLRequest(url: URL(string: URL_REPORT_UPLOAD)!, method: .post, headers: nil)

			self.showActivityIndicator()

			sessionManager.upload(
				multipartFormData: {
					multipartFormData in
					for media in self.mediaArray! {
//						print(media.videoURL, media.data)
						multipartFormData.append(media.data!, withName: "files[]", fileName: media.name, mimeType: media.mimeType)
					}
				},
				with: url,
				encodingCompletion: {
					encodingResult in

					switch encodingResult {
					case .success(let upload, let streamingFromDisk, let streamFileURL):
//						self.hideActivityIndicator()
						upload.responseJSON {
							response in

//							let responseString = response.result.value as! String
//
//							do {
//								if let jsonArray = try JSONSerialization.jsonObject(with: responseString.data(using: .utf8)!, options : .allowFragments) as? Dictionary<String,Any> {
//									print("==========", jsonArray)
//								}
//								else {
//									print("++++++++++", response.result.value)
//								}
//							}
//							catch let error as NSError {
//								print(error.localizedDescription)
//								print(response.result.value)
//							}

							if let jsonData = response.result.value {
								print(jsonData)
								let json = jsonData as! Dictionary<String,AnyObject>

								if let state = json["state"] as? Int {
									switch state {
									case -1:
										if let list = json["list_error"] as? [AnyObject] {
											for item in list {
												let itemData = JSON(item)
												let errorMessage = itemData["error"].stringValue

												self.showMessage(message: errorMessage)
												break
											}
										}

										break

									case 0:
										if let list = json["list"] as? [AnyObject] {
											for item in list {
												let itemData = JSON(item)
												let id = itemData["id"].int
												self.attachmentId.append(id!)
											}
										}

										if (self.attachmentId.isEmpty) {
											self.showMessage(message: LocalizedString("You have to select at least one media"))
										}
										else {
											self.saveReport()
										}
										break

									case 2, 3:
										self.goToSignIn()
										break

									default:
										if let message = json["message"] as? String {
											self.showMessage(message: message)
										}
										break
									}
								}
							}
						}
						break

					case .failure(let error):
						self.hideActivityIndicator()
						self.showMessage(message: error.localizedDescription)
						break
					}
				}
			)
		}
		else {
			self.showMessage(message: LocalizedString("You have to select at least one media"))
		}
	}

	func saveReport() {
		if (categoryId == nil) {
			self.showMessage(message: LocalizedString("Category is required"))
			return;
		}

		if (tfComment.text == "") {
			self.showMessage(message: LocalizedString("Comment is required"))
			return;
		}

		if (tfLocation.text == "") {
			self.showMessage(message: LocalizedString("Location is required"))
			return;
		}

		let params:Parameters = [
			"id": "",
			"title": tfComment.text!,
			"cate_id": categoryId!,
			"lead": tfLocation.text!,
			"attachment_id": attachmentId.map(String.init).joined(separator: ","),
			"avatar_id": attachmentId[0]
		]

//		showActivityIndicator()

		//Sending http post request
		self.sessionManager
			.request(URL_REPORT_POST, method: .post, parameters: params)
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
							self.showMessage(message: LocalizedString("Upload successfully. Your report will appear after verifying!"), OKAction: UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in

								//self.navigationController?.popToRootViewController(animated: true)
								self.performSegue(withIdentifier: "unwindToPostReport", sender: self)
							})
							break;

						case 1:
							var errorMessage:String = message;

							if let errorComment = json["input_error"]["title"].string {
								errorMessage = errorComment
							}
							else if let errorLocation = json["input_error"]["lead"].string {
								errorMessage = errorLocation
							}
							else if let errorCategory = json["input_error"]["cate_id"].string {
								errorMessage = errorCategory
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

	@IBAction func unwindToPostReportUpload(segue: UIStoryboardSegue) {
		if let source = segue.source as? PostReportMap {
			if let _ = source.userLocation {
				//self.userLocation = source.userLocation
				//self.tfLocation.text = self.userLocation.placemark
				self.tfLocation.text = source.tfLocation.text
			}
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "show_map_view" {
			if let vcMap = segue.destination as? PostReportMap {
				vcMap.userLocation = self.userLocation

				tfLocation.text = self.userLocation.placemark
			}
		}
	}

	@objc func uploadReport(sender: UIButton) {
		self.uploadFile()
	}

	@objc func showLocationView() {
		performSegue(withIdentifier: "show_map_view", sender: nil)
	}
}
