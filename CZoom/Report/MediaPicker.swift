//
//  MediaButtons.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 1/16/18.
//  Copyright © 2018 3T Asia. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import Photos

class MyMedia: NSObject {
	var image: UIImage!
	var object: AnyObject!
	var data: Data!
	var name: String!
	var mimeType: String!
	var type: String!
	var videoURL: URL!
}

class MediaPicker: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	var media: MyMedia? = nil

	var imagePicker = UIImagePickerController()

	@IBOutlet weak var viewContent: UIView!
	@IBOutlet weak var viewParent: PostReport!
	@IBOutlet weak var buttonPhoto: UIButton!
	@IBOutlet weak var buttonVideo: UIButton!
	@IBOutlet weak var buttonLibrary: UIButton!
	@IBOutlet weak var buttonCancel: UIButton!

	@objc func cancel(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@objc func photo(_ sender: UIButton) {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			imagePicker.sourceType = .camera
			//imagePicker.cameraCaptureMode = .photo
			imagePicker.mediaTypes = [kUTTypeImage as NSString as String]
			self.present(imagePicker, animated: true, completion: nil)
		}
		else {
			print("ERROR: Camera is not availalbe")
		}
	}

	@objc func video(_ sender: UIButton) {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			imagePicker.sourceType = .camera
			//imagePicker.cameraCaptureMode = .video
			imagePicker.mediaTypes = [kUTTypeMovie as NSString as String]
			imagePicker.videoMaximumDuration = 30.0
			self.present(imagePicker, animated: true, completion: nil)
		}
		else {
			print("ERROR: Camera is not availalbe")
		}
	}
	
	@objc func library(_ sender: UIButton) {
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
			imagePicker.sourceType = .photoLibrary
			imagePicker.mediaTypes = [kUTTypeMovie as NSString as String, kUTTypeImage as NSString as String]
			self.present(imagePicker, animated: true, completion: nil)
		}
		else {
			print("ERROR: Library is not availalbe")
		}
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let mediaType = info["UIImagePickerControllerMediaType"] as! String

		let media: MyMedia = MyMedia()
		media.type = mediaType

		if mediaType == kUTTypeMovie as NSString as String {
			let mediaURL = info["UIImagePickerControllerMediaURL"] as! NSURL

			media.videoURL = mediaURL as! URL
			media.data = FileManager.default.contents(atPath: mediaURL.path!)
			media.name = getFileName(path: mediaURL)
			media.mimeType = getMimeType(path: mediaURL)
			media.image = getThumbnailFrom(path: mediaURL as URL)
		}
		else if mediaType == kUTTypeImage as NSString as String {
			var pickedImage: UIImage?

			if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
				pickedImage = editedImage
			}
			else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
				pickedImage = originalImage
			}

			if let _ = pickedImage {
				media.image = pickedImage!
				media.data = UIImageJPEGRepresentation(pickedImage!, 1)!

				if let imageURL = info["UIImagePickerControllerImageURL"] as? NSURL {
					media.name = getFileName(path: imageURL)
					media.mimeType = getMimeType(path: imageURL)
				}
				else {
					media.name = "new_image.jpg"
					media.mimeType = "image/jpeg"
				}
			}
		}

		self.media = media

		self.performSegue(withIdentifier: "unwindToPostReport", sender: self)

		self.dismiss(animated: false, completion: nil)
		picker.dismiss(animated: true, completion: nil)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: true, completion: nil)
		picker.dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		imagePicker = UIImagePickerController()
		imagePicker.delegate = self
//		imagePicker.allowsEditing = true

		let tapRec = UITapGestureRecognizer()
		tapRec.addTarget(self, action: #selector(cancel(_:)))
		self.view.addGestureRecognizer(tapRec)

		viewContent.layer.cornerRadius = 5

		buttonPhoto.layer.cornerRadius = 3
		buttonPhoto.setTitle(LocalizedString("Take an image"), for: .normal)
		buttonPhoto.addTarget(self, action: #selector(photo(_:)), for: .touchUpInside)

		buttonVideo.layer.cornerRadius = 3
		buttonVideo.setTitle(LocalizedString("Take a video"), for: .normal)
		buttonVideo.addTarget(self, action: #selector(video(_:)), for: .touchUpInside)

		buttonLibrary.layer.cornerRadius = 3
		buttonLibrary.setTitle(LocalizedString("Import from library"), for: .normal)
		buttonLibrary.addTarget(self, action: #selector(library(_:)), for: .touchUpInside)

		buttonCancel.layer.cornerRadius = 3
		buttonCancel.setTitle(LocalizedString("Cancel"), for: .normal)
		buttonCancel.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
	}
}
