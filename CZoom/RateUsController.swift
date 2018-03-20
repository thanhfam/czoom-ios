//
//  RateUsController.swift
//  ZoomGiaoThong
//
//  Created by Thanh Phạm on 1/29/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class RateUsController: MyViewController {

	@IBAction func btnClose(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("Rate us")

		let rate = RateMyApp.sharedInstance
		rate.debug = true
		rate.appID = "857846130"
		rate.setController(self)

		DispatchQueue.main.async(execute: { () -> Void in
			rate.trackAppUsage()
		})

		print("Function : \(#function), Class: \(type(of: self))")
	}

}

