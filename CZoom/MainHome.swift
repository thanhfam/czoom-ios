//
//  MainHome.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/7/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit

class MainHome: UITabBarController {
	override func viewWillAppear(_ animated: Bool) {
		print("Function : \(#function), Class: \(type(of: self))")
		super.viewWillAppear(true)
	}

	override func viewDidAppear(_ animated: Bool) {
		print("Function : \(#function), Class: \(type(of: self))")
		super.viewDidAppear(animated)
	}

	override func viewDidLoad() {
		print("Function : \(#function), Class: \(type(of: self))")
		super.viewDidLoad()
	}

	override func didReceiveMemoryWarning() {
		print("Function : \(#function), Class: \(type(of: self))")
		super.didReceiveMemoryWarning()
	}
}

