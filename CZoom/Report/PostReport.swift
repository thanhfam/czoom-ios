//
//  PostReport.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/9/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Lightbox
import MobileCoreServices

class PostReport: MyViewController, UITableViewDelegate, UITableViewDataSource, LightboxControllerPageDelegate, LightboxControllerDismissalDelegate {
	var mediaArray = [MyMedia]()
	var lightbox: LightboxController!

	let rowHeight = Int(234)

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var tableViewHeader: UIView!
	
	@IBOutlet weak var buttonMenu: UIBarButtonItem!
	@IBOutlet weak var buttonSave: UIBarButtonItem!
	@IBOutlet weak var buttonClear: UIBarButtonItem!

	@IBOutlet weak var buttonAdd: UIButton!


	var image: UIImage? = nil
	var text: String? = nil

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = LocalizedString("Post a report")

		self.tableView.delegate = self
		self.tableView.dataSource = self

		self.tableView.allowsSelection = false

//		self.tableView.allowsMultipleSelectionDuringEditing = false
		self.tableView.estimatedRowHeight = 234
		self.tableView.rowHeight = UITableViewAutomaticDimension

		self.setupActivityIndicator()
		self.setupButton()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setupMenu()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		guard let headerView = tableView.tableHeaderView else {
			return
		}

		// The table view header is created with the frame size set in
		// the Storyboard. Calculate the new size and reset the header
		// view to trigger the layout.
		// Calculate the minimum height of the header view that allows
		// the text label to fit its preferred width.
		let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)

		if headerView.frame.size.height != size.height {
			headerView.frame.size.height = size.height

			// Need to set the header view property of the table view
			// to trigger the new layout. Be careful to only do this
			// once when the height changes or we get stuck in a layout loop.
			tableView.tableHeaderView = headerView

			// Now that the table view header is sized correctly have
			// the table view redo its layout so that the cells are
			// correcly positioned for the new header size.
			// This only seems to be necessary on iOS 9.
			tableView.layoutIfNeeded()
		}
	}
	
	func setupLightBox() {
		configLightbox()

		lightbox.pageDelegate = self
		lightbox.dismissalDelegate = self

		lightbox.dynamicBackground = true
	}

	@objc func showLightbox(_ tagGesture: UITapGestureRecognizer) {
		if let imageView = tagGesture.view {
			let index = imageView.tag

			if mediaArray.indices.contains(index) {

				var images = [LightboxImage]()

				for i in 0..<mediaArray.count {
					let media = mediaArray[i]

					if media.type == kUTTypeImage as NSString as String {
						images.append(LightboxImage(image: media.image!, text: ""))
					}
					else if media.type == kUTTypeMovie as NSString as String {
						images.append(LightboxImage(image: media.image!, text: "", videoURL: media.videoURL))
					}
				}

				self.lightbox = LightboxController(images: images)

				self.present(lightbox, animated: true, completion: nil)

				self.lightbox.goTo(index, animated: false)
			}
		}
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return CGFloat(rowHeight)
	}

//	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//		return 10
//	}

//	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//		let headerView = UIView()
//		headerView.backgroundColor = UIColor.clear
//
//		return headerView
//	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == UITableViewCellEditingStyle.delete) {
			mediaArray.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
			toggleButtonSave()
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mediaArray.count
	}

//	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//		let delete = UITableViewRowAction(style: .default, title: "\u{267A}\n Delete") { action, index in
//			self.tableView(tableView, commit: UITableViewCellEditingStyle.delete, forRowAt: indexPath)
//		}
//
//		return [delete]
//	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostReportImageCell

		if let media = mediaArray[indexPath.row] as? MyMedia {
			cell.imageMain.contentMode = .scaleAspectFit
			cell.imageMain.image = media.image
			cell.imageMain.tag = indexPath.row

			let tapRec = UITapGestureRecognizer()
			tapRec.addTarget(self, action: #selector(showLightbox(_:)))

			cell.imageMain.isUserInteractionEnabled = true;
			cell.imageMain.addGestureRecognizer(tapRec)
		}

		return cell
	}

	func toggleButtonSave() {
		if (mediaArray.count == 0) {
			buttonSave.isEnabled = false
			buttonClear.isEnabled = false
		}
		else {
			buttonSave.isEnabled = true
			buttonClear.isEnabled = true
		}
	}

	func addMedia(media: MyMedia) {
		mediaArray.append(media)
		self.tableView.reloadData()
		toggleButtonSave()
	}

	public func clearMedia() {
		self.mediaArray.removeAll()
		self.tableView.reloadData()
		toggleButtonSave()
	}

	@objc func clearAllMedia(_ sender: Any?) {
		self.clearMedia()
	}

	@IBAction func unwindToPostReport(segue: UIStoryboardSegue) {
		if let source = segue.source as? MediaPicker {
			if let media: MyMedia? = source.media {
				addMedia(media: media!)
			}
		}
		else if let source = segue.source as? PostReportUpload {
			clearMedia()
		}
	}

	func setupButton() {
		buttonSave.target = self
		buttonSave.action = #selector(saveReport(_:))

		buttonClear.target = self
		buttonClear.action = #selector(clearAllMedia(_:))

		toggleButtonSave()

		self.buttonAdd.layer.cornerRadius = 3
		self.buttonAdd.setTitle(LocalizedString("Image or Video"), for: .normal)
//		self.buttonAdd.addTarget(self, action: #selector(showMediaPicker(_:)), for: .touchUpInside)

		self.buttonMenu.target = self.revealViewController()
		self.buttonMenu.action = #selector(SWRevealViewController.revealToggle(_:))

		let tapRec = UITapGestureRecognizer()
		tapRec.addTarget(self, action: #selector(showLightbox(_:)))
		tableView.addGestureRecognizer(tapRec)
	}

	@objc func saveReport(_ sender: UIBarButtonItem) {
		self.performSegue(withIdentifier: "choose_category", sender: nil)
	}

	@objc func showMediaPicker(_ sender: UIButton) {
		self.performSegue(withIdentifier: "show_media_picker", sender: nil)
	}

	func lightboxController(_ controller: LightboxController, didMoveToPage page: Int) {
	}

	func lightboxControllerWillDismiss(_ controller: LightboxController) {
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "choose_category" {
			if let vcDestination = segue.destination as? PostReportCategoryList {
				vcDestination.mediaArray = mediaArray
			}
		}
		if segue.identifier == "show_media_picker" {
			if let vcDestination = segue.destination as? MediaPicker {
				vcDestination.viewParent = self
			}
		}
	}
}

