//
//  ReportCell.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/9/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import AlamofireImage

class Report: NSObject {
	var id: Int!
	var comment: String!
	var location: String!
	var created: String!
	var updated: String!
	var userId: Int!
	var userName: String!
	var cateId: Int!
	var cateName: String!
	var totalComment: Int!
	var totalLike: Int!
	var stateWeight: Int!
	var stateName: String!
	var avatarType: String!
	var avatarURL: String!
	var avatarOptURL: String!
	var avatarOriURL: String!
	var avatarId: Int!
	var avatarFileExt: String!
	var attachment: [Attachment]!

	init(_ reportData: AnyObject!) {
		id = (reportData["id"] as! NSString).integerValue
		comment = reportData["title"] as! String
		location = reportData["lead"] as? String
		cateId = (reportData["cate_id"] as! NSString).integerValue
		cateName = reportData["cate_title"] as! String
		updated = reportData["updated"] as! String

		userId = (reportData["creator_id"] as! NSString).integerValue
		userName = reportData["creator_name"] as! String

		avatarURL = reportData["avatar_url"] as? String
		avatarOptURL = reportData["avatar_url_opt"] as? String
		avatarOriURL = reportData["avatar_url_ori"] as? String

		if avatarURL.isEmpty {
			avatarURL = URL_NO_IMAGE
			avatarOptURL = URL_NO_IMAGE
			avatarOriURL = URL_NO_IMAGE
			avatarType = "image"
			avatarId = -1
			avatarFileExt = "png"
		}
		else {
			avatarType = reportData["avatar_type"] as? String
			avatarId = (reportData["avatar_id"] as? NSString)?.integerValue
			avatarFileExt = reportData["avatar_file_ext"] as? String
		}

		totalLike = (reportData["total_like"] as! NSString).integerValue
		totalComment = (reportData["total_comment"] as! NSString).integerValue
		stateWeight = (reportData["state_weight"] as! NSString).integerValue
		stateName = reportData["state_name"] as? String

		attachment = [Attachment]()

		if let attachmentData = reportData["attachment"] as? [AnyObject] {
			for itemData in attachmentData {
				let item = Attachment(
					id: (itemData["id"] as! NSString).integerValue,
					path: itemData["url"] as! String,
					optPath: itemData["url_opt"] as! String,
					oriPath: itemData["url_ori"] as! String,
					type: itemData["type"] as? String!,
					fileExt: itemData["file_ext"] as? String
				)
				attachment.append(item)
			}
		}

		if attachment.isEmpty {
			let item = Attachment(
				id: avatarId,
				path: avatarURL,
				optPath: avatarOptURL,
				oriPath: avatarOriURL,
				type: avatarType,
				fileExt: avatarFileExt
			)
			attachment.append(item)
		}
	}
}

struct Attachment {
	var id: Int!
	var path: String!
	var optPath: String!
	var oriPath: String!
	var type: String!
	var fileExt: String!
}

class ReportCell: UITableViewCell {
	@IBOutlet weak var viewAvatar: UIView!

	@IBOutlet weak var imageAvatar: UIImageView!
	@IBOutlet weak var labelComment: UILabel!
	@IBOutlet weak var labelUpdated: UILabel!
	@IBOutlet weak var labelState: UILabel!
	@IBOutlet weak var labelLocation: UILabel!
	@IBOutlet weak var labelCateName: UILabel!
	@IBOutlet weak var labelTotalLike: UILabel!
	@IBOutlet weak var labelTotalComment: UILabel!
	@IBOutlet weak var labelUserName: UILabel!

	@IBOutlet weak var buttonView: UIButton!

	var index: Int!
	var report: Report!

	public func setIndex(_ index: Int) {
		self.index = index
	}
	
	public func setReport(_ report: Report) {
		self.report = report
	}

	public func setTapRec(_ tapRec: UITapGestureRecognizer) {
		imageAvatar.addGestureRecognizer(tapRec)
	}

	public func render() {
		imageAvatar.image = nil
//		if report.avatarType == "image" {
//			imageAvatar.contentMode = .scaleAspectFit
//			imageAvatar.setImage(url: URL(string: report.avatarURL)!)
//		}
//		else if report.avatarType == "video" {
//			imageAvatar.image = getThumbnailFrom(path: URL(string: report.avatarURL)!)
//		}

		if let _ = report.avatarURL, !report.avatarURL.isEmpty {
			imageAvatar.setImage(url: URL(string: report.avatarURL)!)
		}
		else {
			imageAvatar.image = IMAGE_PLACEHOLDER
		}

		imageAvatar.contentMode = .scaleAspectFit
		imageAvatar.isUserInteractionEnabled = true
		imageAvatar.tag = index

		labelComment.text = report.comment
		labelCateName.text = "\(report.cateName as! String)"
		labelUpdated.text = "\(report.updated as! String)"

		labelUserName.textColor = buttonView.tintColor
		labelUserName.text = report.userName

		if report.location.isEmpty {
			labelLocation.text = "\(LocalizedString("Unknown location"))"
		}
		else {
			labelLocation.text = "\(report.location as! String)"
		}

		if let _ = labelState {
			switch report.stateWeight {
			case 0:
				labelState.text = LocalizedString("Verifying")
				labelState.textColor = .black
				break;
			case 9:
				labelState.text = LocalizedString("Verified")
				labelState.textColor = UIColor(red: 0, green: 0.3922, blue: 0, alpha: 1.0)
				break;
			default:
				labelState.text = report.stateName
				labelState.textColor = .black
				break
			}
		}

		labelTotalLike.text = "\(report.totalLike as! Int) \(LocalizedString("like(s)"))"
		labelTotalComment.text = "\(report.totalComment as! Int) \(LocalizedString("comment(s)"))"

		layer.shouldRasterize = true
		layer.rasterizationScale = UIScreen.main.scale

		buttonView.setTitle(LocalizedString("View detail"), for: .normal)
		buttonView.tag = index
	}
}

