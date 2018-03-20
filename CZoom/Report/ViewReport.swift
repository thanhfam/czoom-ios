//
//  ViewReport.swift
//  ZoomGiaoThong
//
//  Created by Thanh Phạm on 1/30/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Lightbox
import AVKit
import AVFoundation

class Comment: NSObject {
	var id: Int!
	var avatarURL: String!
	var avatarType: String!
	var comment: String!
	var userId: Int!
	var userName: String!
	var created: String!
	var updated: String!
	var contentType: String!
	var contentId: Int!
	var stateWeight: Int!
}

class ViewReport: MyViewController, UITableViewDelegate, UITableViewDataSource, LightboxControllerPageDelegate, LightboxControllerDismissalDelegate {
	@IBOutlet weak var viewParent: MyViewController!

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var tableViewHeader: UIView!
	@IBOutlet weak var tableViewFooter: UIView!

	@IBOutlet weak var scrollViewAttachment: UIScrollView!
	@IBOutlet weak var labelComment: UILabel!
	@IBOutlet weak var labelUpdated: UILabel!
	@IBOutlet weak var labelUserName: UILabel!
	@IBOutlet weak var labelLocation: UILabel!
	@IBOutlet weak var labelCateName: UILabel!
	@IBOutlet weak var labelTotalLike: UILabel!
	@IBOutlet weak var labelTotalComment: UILabel!

	@IBOutlet weak var imageMyAvatar: UIImageView!
	@IBOutlet weak var tfMyComment: UITextField!

	@IBOutlet weak var buttonLike: UIButton!
	var buttonComment: UIButton!

	var lightbox: LightboxController!
	var imageAttachment: [LightboxImage]!

	var report: Report?
	var commentArray: [Comment]!
	var dataArray: [AnyObject] = [AnyObject]()

	override func viewDidLoad() {
		print("Function : \(#function), Class: \(type(of: self))")
		super.viewDidLoad()

		setupView()

		if let _ = report {
			imageAttachment = [LightboxImage]()
			commentArray = [Comment]()
			dataArray = [AnyObject]()

			setupReport()
			setupCommentList()
			doLikeReport()
		}

		setupCommentPanel()
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

		lightbox = LightboxController(images: self.imageAttachment)
		lightbox.pageDelegate = self
		lightbox.dismissalDelegate = self

		lightbox.dynamicBackground = true
	}

	func setupCommentPanel() {
		if let userAvatar = self.defaultValues.string(forKey: "userAvatar"), !userAvatar.isEmpty {
			self.imageMyAvatar.setImage(url: URL(string: userAvatar)!)
		}
		else {
			self.imageMyAvatar.image = IMAGE_PLACEHOLDER
		}

		self.imageMyAvatar.contentMode = .scaleAspectFill
		self.imageMyAvatar.clipsToBounds = true
		self.imageMyAvatar.layer.cornerRadius = 3

		buttonComment = UIButton(type: .custom)
		buttonComment.setTitle(LocalizedString("Send"), for: .normal)
		buttonComment.setImage(UIImage(named: "send.png"), for: .normal)
		buttonComment.frame = CGRect(x: CGFloat(tfMyComment.frame.size.width - 20), y: CGFloat(0), width: CGFloat(20), height: CGFloat(20))
		buttonComment.addTarget(self, action: #selector(self.sendComment), for: .touchUpInside)

		tfMyComment.rightView = buttonComment
		tfMyComment.rightViewMode = .always

		tfMyComment.placeholder = LocalizedString("Leave your comment")
	}

	func setupView() {
		tfMyComment.delegate = self

		tableView.delegate = self
		tableView.dataSource = self

		tableView.tableHeaderView = tableViewHeader
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 100

		tableView.tableFooterView = tableViewFooter
		tableView.sectionFooterHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionFooterHeight = 100

		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 100
	}

	@objc func sendComment() {
		if (tfMyComment.text == "") {
			return;
		}

		self.showActivityIndicator()

		let params:Parameters = [
			"content_id": report!.id,
			"comment": tfMyComment.text!,
			"content_type": "tf_report"
		]

		self.buttonComment.isEnabled = false

		self.sessionManager
			.request(URL_COMMENT_ADD, method: .post, parameters: params)
			.responseJSON {
				response in

				switch response.result {
				case .success:
					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						let state = json.value(forKey: "state") as! Int
						let message = json.value(forKey: "message") as? String

						switch (state) {
						case 0:
							self.tfMyComment.text = ""
							self.tfMyComment.resignFirstResponder()
							self.showMessage(message: LocalizedString("Sent successfully. Your comment will be show after verifying!"))
							break

						case -1:
							self.showMessage(message: message!)
							break

						case 1:
							var errorMessage:String = message!;

							if let error = json.value(forKey: "input_error") as? NSDictionary {
								if let errorContentId = error.value(forKey: "content_id") as? String {
									errorMessage = errorContentId
								}
								else if let errorContentType = error.value(forKey: "content_type") as? String {
									errorMessage = errorContentType
								}
								else if let errorComment = error.value(forKey: "comment") as? String {
									errorMessage = errorComment
								}
							}
							self.showMessage(message: errorMessage)
							break

						case 2, 3:
							//self.signOut()
							break

						default:
							self.showMessage(message: message!)
							break
						}
					}

					self.buttonComment.isEnabled = true
					break
				case .failure(let error):
					self.showMessage(message: error.localizedDescription)
					self.buttonComment.isEnabled = true
					break
				}
		}
	}

	func setupCommentList() {
		self.showActivityIndicator()

		let params:Parameters = [
			"content_id": report!.id,
			"content_type": "tf_report"
		]

		self.sessionManager
			.request(URL_COMMENT_LIST, method: .post, parameters: params)
			.responseJSON {
				response in

				switch response.result {
				case .success:
					self.hideActivityIndicator()

					if let jsonData = response.result.value {
						//print(jsonData)
						let json = jsonData as! Dictionary<String,AnyObject>

						if let commentList = json["list"] {
							self.dataArray = commentList as! [AnyObject]
							self.tableView.reloadData()
						}
					}
					break
				case .failure(let error):
					self.hideActivityIndicator()

					self.showMessage(message: error.localizedDescription, OKAction: UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
						self.dismiss(animated: true, completion: nil)
					})
					break
				}
		}
	}

	func setupButtonLike() {
		self.labelTotalLike.text = "\(report!.totalLike as! Int) \(LocalizedString("like(s)"))"
		buttonLike.setTitle(LocalizedString("Like"), for: .normal)
		buttonLike.removeTarget(nil, action: nil, for: .allEvents)
		buttonLike.addTarget(self, action: #selector(self.likeReport(_:)), for: .touchUpInside)
	}

	func setupButtonUnlike() {
		self.labelTotalLike.text = "\(report!.totalLike as! Int) \(LocalizedString("like(s)"))"
		buttonLike.setTitle(LocalizedString("Unlike"), for: .normal)
		buttonLike.removeTarget(nil, action: nil, for: .allEvents)
		buttonLike.addTarget(self, action: #selector(self.unlikeReport(_:)), for: .touchUpInside)
	}
 

	func doLikeReport(_ type: String = "check") {
		var URL: String = String()

		switch type {
		case "add":
			URL = URL_LIKE_ADD
			break
		case "remove":
			URL = URL_LIKE_REMOVE
			break
		case "check":
			URL = URL_LIKE_CHECK
			buttonLike.setTitle("", for: .normal)
			break
		default:
			return
		}

		self.showActivityIndicator()

		let params:Parameters = [
			"content_id": report!.id,
			"content_type": "tf_report"
		]

		self.buttonLike.isEnabled = false

		self.sessionManager
			.request(URL, method: .post, parameters: params)
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
							switch type {
							case "add":
								self.increaseTotalLike()
								self.setupButtonUnlike()
								break
							case "remove":
								self.decreaseTotalLike()
								self.setupButtonLike()
								break
							case "check":
								self.setupButtonUnlike()
								break
							default:
								break
							}
							break

						case -1:
							switch type {
							case "add":
								self.setupButtonUnlike()
								break
							case "remove":
								self.setupButtonLike()
								break
							case "check":
								self.setupButtonLike()
								break
							default:
								break
							}
							break

						case 1:
							self.setupButtonUnlike()
							var errorMessage:String = message!;

							if let error = json.value(forKey: "input_error") as? NSDictionary {

								if let errorContentId = error.value(forKey: "content_id") as? String {
									errorMessage = errorContentId
								}
								else if let errorContentType = error.value(forKey: "content_type") as? String {
									errorMessage = errorContentType
								}
							}
							self.showMessage(message: errorMessage)
							break

						case 2, 3:
							self.signOut()
							break

						default:
							self.showMessage(message: message!)
							break
						}
					}

					self.buttonLike.isEnabled = true
					break
				case .failure(let error):
					self.showMessage(message: error.localizedDescription)
					self.buttonLike.isEnabled = true
					break
				}
		}
	}

	func increaseTotalLike() {
		self.report!.totalLike = self.report!.totalLike + 1
		self.updateTotalLike()
	}

	func decreaseTotalLike() {
		var totalLike = self.report!.totalLike - 1

		if totalLike < 0 {
			totalLike = 0
		}

		self.report!.totalLike = totalLike
		self.updateTotalLike()
	}

	func updateTotalLike() {
		if let parent = self.viewParent as? AllReportController {
			parent.updateReport(report: self.report!)
		}

		if let parent = self.viewParent as? MyReportController {
			parent.updateReport(report: self.report!)
		}
	}

	@objc func unlikeReport(_ sender: UIButton) {
		doLikeReport("remove")
	}

	@objc func likeReport(_ sender: UIButton) {
		doLikeReport("add")
	}

	@objc func showLightbox(_ sender: UITapGestureRecognizer) {
		let pointTapped: CGPoint = sender.location(in: self.scrollViewAttachment)
		let widthOfPhoto: CGFloat = self.scrollViewAttachment.frame.size.width
		let index = Int(pointTapped.x / CGFloat(widthOfPhoto))

		self.lightbox.goTo(index)
		self.present(lightbox, animated: true, completion: nil)
	}

	func setupReport() {
		if report!.attachment.isEmpty == false {
			for i in 0..<report!.attachment.count {
				let item = report!.attachment[i]
				let xPosition = self.view.frame.width * CGFloat(i)

				let imageView = UIImageView()
				imageView.contentMode = .scaleAspectFit
				imageView.frame = CGRect(x: xPosition, y: 0, width: self.view.frame.width, height: self.scrollViewAttachment.frame.height)

				var lightboxImage: LightboxImage?

				if item.type == "video" {
//					let videoURL = URL(string: item.oriPath)
//					let player = AVPlayer(url: videoURL!)
//					let playerViewController = AVPlayerViewController()
//					playerViewController.player = player
//					playerViewController.showsPlaybackControls = true
//					playerViewController.view.frame = CGRect(x: xPosition, y: 0, width: self.view.frame.width, height: self.scrollViewAttachment.frame.height)
//
//					self.addChildViewController(playerViewController)
//					scrollViewAttachment.addSubview(playerViewController.view)
//					playerViewController.didMove(toParentViewController: self)

//					let playerLayer = AVPlayerLayer(player: player)
//					playerLayer.frame = CGRect(x: xPosition, y: 0, width: self.scrollViewAttachment.frame.width, height: self.scrollViewAttachment.frame.height)
//					scrollViewAttachment.layer.addSublayer(playerLayer)

					if let imageURL = item.path, !imageURL.isEmpty {
						imageView.setImage(url: URL(string: imageURL)!)

						lightboxImage = LightboxImage(
							imageURL: URL(string: imageURL)!,
							text: "",
							videoURL: URL(string: item.oriPath)!
						)
					}
					else {
						imageView.image = IMAGE_PLACEHOLDER

						lightboxImage = LightboxImage(
							image: IMAGE_PLACEHOLDER!,
							text: "",
							videoURL: URL(string: item.oriPath)!
						)
					}
				}
				else if item.type == "image" {
					if let imageURL = item.oriPath, !imageURL.isEmpty {
						imageView.setImage(url: URL(string: imageURL)!)

						lightboxImage = LightboxImage(
							imageURL: URL(string: imageURL)!
						)
					}
					else {
						imageView.image = IMAGE_PLACEHOLDER

						lightboxImage = LightboxImage(
							image: IMAGE_PLACEHOLDER!
						)
					}

//					let tapRec = UITapGestureRecognizer()
//					tapRec.addTarget(self, action: #selector(showLightbox(_:)))
//					tapRec.name = String(i)
//					tapRec.setValue(String(i), forUndefinedKey: "index")

//					imageView.isUserInteractionEnabled = true;
//					imageView.addGestureRecognizer(tapRec)
				}

				scrollViewAttachment.addSubview(imageView)
				self.imageAttachment.append(lightboxImage!)

				scrollViewAttachment.contentSize.width = self.view.frame.width * CGFloat(i + 1)
				let tapRec = UITapGestureRecognizer()
				tapRec.addTarget(self, action: #selector(showLightbox(_:)))
				scrollViewAttachment.addGestureRecognizer(tapRec)
			}

			setupLightBox()
		}

		labelComment.text = report!.comment
		labelCateName.text = "\(report!.cateName as! String)"
		labelUpdated.text = "\(report!.updated as! String)"

		labelUserName.textColor = buttonLike.tintColor
		labelUserName.text = report!.userName

		if report!.location.isEmpty {
			labelLocation.text = "\(LocalizedString("Unknown location"))"
		}
		else {
			labelLocation.text = "\(report!.location as! String)"
		}

		labelTotalLike.text = "\(report!.totalLike as! Int) \(LocalizedString("like(s)"))"
		labelTotalComment.text = "\(report!.totalComment as! Int) \(LocalizedString("comment(s)"))"

		buttonLike.setTitle(LocalizedString("Like"), for: .normal)

		scrollViewAttachment.backgroundColor = .black
	}

	override func viewWillAppear(_ animated: Bool) {

	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		var numOfSections: Int = 0
//
//		if dataArray.isEmpty {
//			let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
//			noDataLabel.text = LocalizedString("No data available")
//			noDataLabel.textColor = UIColor.black
//			noDataLabel.textAlignment = .center
//			tableView.backgroundView = noDataLabel
//			tableView.separatorStyle = .none
//		}
//		else {
//			tableView.separatorStyle = .singleLine
//			numOfSections = dataArray.count
//			tableView.backgroundView = nil
//		}
		
		return dataArray.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentCell

		let commentData = dataArray[indexPath.row];
		let comment: Comment = Comment()

		comment.id = (commentData["id"] as! NSString).integerValue
		comment.comment = commentData["comment"] as! String
		comment.avatarURL = commentData["avatar_url"] as? String
		comment.avatarType = commentData["avatar_type"] as? String
		comment.userId = (commentData["user_id"] as! NSString).integerValue
		comment.userName = commentData["name"] as! String
		comment.updated = commentData["updated"] as! String
		comment.created = commentData["created"] as! String
		comment.contentType = commentData["content_type"] as! String
		comment.contentId = (commentData["content_id"] as! NSString).integerValue
		comment.stateWeight = (commentData["state_weight"] as! NSString).integerValue

		commentArray.append(comment)

		if (comment.avatarURL ?? "").isEmpty == false  {
			cell.imageAvatar.setImage(url: URL(string: comment.avatarURL!)!)
		}
		else {
			cell.imageAvatar.image = UIImage(named: "no_image")
		}

		cell.imageAvatar.contentMode = .scaleAspectFill
		cell.imageAvatar.clipsToBounds = true
		cell.imageAvatar.layer.cornerRadius = 3

		cell.labelComment.text = comment.comment
		cell.labelUserName.text = comment.userName
		cell.labelUpdated.text = comment.created

		return cell
	}

	func lightboxController(_ controller: LightboxController, didMoveToPage page: Int) {
	}

	func lightboxControllerWillDismiss(_ controller: LightboxController) {
	}
}
