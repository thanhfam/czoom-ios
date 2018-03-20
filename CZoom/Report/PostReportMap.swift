//
//  PostReportMap.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/24/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import QuartzCore

class PostReportMap: MyViewController, CLLocationManagerDelegate {
	@IBOutlet weak var tfLocation: UITextField!
	@IBOutlet weak var buttonCurrentLocation: UIButton!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var viewLocation: UIView!
	
	var locationManager = CLLocationManager()

	var userLocation: MyLocation?
	var userPin: MKAnnotation?

	override func viewDidLoad() {
		super.viewDidLoad()

		setupActivityIndicator()
		setupMap()
		setupLocationManager()
		setupButton()

		tfLocation.delegate = self

		self.navigationItem.title = LocalizedString("Pick a location")

		if let _ = userLocation {
			tfLocation.text = userLocation!.placemark as? String

			if let _ = userLocation!.location {
				centerMapOnLocation(location: userLocation!.location)
			}
		}
		else {
			userLocation = MyLocation()
			startUpdatingLocation()
		}

		print("Function : \(#function), Class: \(type(of: self))")
	}

	override func textFieldDidBeginEditing(_ textField: UITextField) {
	}

	override func textFieldDidEndEditing(_ textField: UITextField) {
	}

	func setupMap() {
		mapView.mapType = MKMapType.standard
		mapView.isZoomEnabled = true
		mapView.isScrollEnabled = true

		// add gesture recognizer
		let tap = UITapGestureRecognizer(
			target: self,
			action: #selector(setLocation(_:))
		)

		// add gesture recognition
		mapView.addGestureRecognizer(tap)
	}

	func setupButton() {
		let buttonDefault = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(getCurrentLocation))
		let buttonDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(getLocation))

		navigationItem.rightBarButtonItems = [buttonDone, buttonDefault]
	}

	@objc func getCurrentLocation() {
		startUpdatingLocation()
	}

	@objc func setLocation(_ recognizer: UIGestureRecognizer) {
		let touchedAt = recognizer.location(in: self.mapView) // adds the location on the view it was pressed
		let touchedAtCoordinate : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView) // will get coordinates

		self.userLocation!.location = CLLocation(latitude: touchedAtCoordinate.latitude, longitude: touchedAtCoordinate.longitude)

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

		self.centerMapOnLocation(location: self.userLocation!.location)
	}

	@objc func getLocation() {
		self.performSegue(withIdentifier: "unwindToPostReportUpload", sender: self)
	}

	func centerMapOnLocation(location: CLLocation) {
		if let _ = self.userPin {
			mapView.removeAnnotation(self.userPin!)
		}

		let regionRadius: CLLocationDistance = 1000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)

		// Drop a pin at user's Current Location
		let userPin = MKPointAnnotation()
		userPin.coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)

		self.userPin = userPin

		mapView.addAnnotation(userPin)
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
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		self.userLocation!.location = locations.last as! CLLocation
		centerMapOnLocation(location: userLocation!.location)

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

}
