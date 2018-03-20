//
//  AboutUsController.swift
//  ZoomGiaoThong
//
//  Created by Thanh Phạm on 1/29/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class AboutUsController: MyViewController {

	@IBAction func btnClose(_ sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("About us")

		print("Function : \(#function), Class: \(type(of: self))")
	}

}
