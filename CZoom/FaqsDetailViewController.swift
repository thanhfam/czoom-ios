//
//  FaqsDetailViewController.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/28/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit

class FaqsDetailViewController: UIViewController {
	@IBOutlet weak var labelTitle: UILabel!
	@IBOutlet weak var labelUpdated: UILabel!
	@IBOutlet weak var labelContent: UILabel!

	var myTitle: String?
	var updated: String?
	var content: String?

	override func viewDidLoad() {
		super.viewDidLoad()

		labelTitle.numberOfLines = 0
		labelUpdated.numberOfLines = 0
		labelContent.numberOfLines = 0

		if let _ = myTitle {
			let options = [
				NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html
			]
			let myTitleAttributes = [
				NSAttributedStringKey.font: UIFont(name: "Arial", size: 18.0),
				NSAttributedStringKey.foregroundColor: UIColor.black
			]
			labelTitle.attributedText = NSAttributedString(string: myTitle!.htmlToString, attributes: myTitleAttributes)

			let updatedAttributes = [
				NSAttributedStringKey.font: UIFont(name: "Arial", size: 12.0),
				NSAttributedStringKey.foregroundColor: UIColor.lightGray
			]
			labelUpdated.attributedText = NSAttributedString(string: updated!, attributes: updatedAttributes)


			let contentAttributes = [
				NSAttributedStringKey.font: UIFont(name: "Arial", size: 15.0),
				NSAttributedStringKey.foregroundColor: UIColor.black
			]
			labelContent.attributedText = NSAttributedString(string: content!.htmlToString, attributes: contentAttributes)
		}
	}
}
