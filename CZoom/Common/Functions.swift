//
//  Functions.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/19/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import MapKit
import MobileCoreServices
import Lightbox
import AVFoundation
import AlamofireImage

let BASE_URL:String = "http://42.112.206.93/beta2/"
//let BASE_URL:String = "http://192.168.31.150/tvn/"

let URL_NO_IMAGE = BASE_URL + "pub/cp/img/noimage.jpg"

let URL_USER_SIGN_UP = BASE_URL + "user/sign-up"
let URL_USER_SIGN_UP_GOOGLE = BASE_URL + "user/sign_up_google"
let URL_USER_SIGN_UP_FACEBOOK = BASE_URL + "user/sign_up_facebook"
let URL_USER_SIGN_IN = BASE_URL + "user/sign_in"
let URL_USER_SIGN_OUT = BASE_URL + "user/sign_out"
let URL_USER_GET_SESSION = BASE_URL + "user/get_session"
let URL_USER_CHANGE_PASSWORD = BASE_URL + "user/change_password"
let URL_USER_EDIT_PROFILE = BASE_URL + "user/edit_profile"

let URL_REPORT_ALL = BASE_URL + "tfreport/all"
let URL_REPORT_MINE = BASE_URL + "tfreport/mine"
let URL_REPORT_POST = BASE_URL + "tfreport/edit"
let URL_REPORT_REMOVE = BASE_URL + "tfreport/remove"
let URL_REPORT_GET_CATEGORY = BASE_URL + "tfreport/get_category"
let URL_REPORT_UPLOAD_FILE = BASE_URL + "tfreport/upload_file"
let URL_REPORT_UPLOAD = BASE_URL + "tfreport/upload"

let URL_LIKE_ADD = BASE_URL + "like/add"
let URL_LIKE_REMOVE = BASE_URL + "like/remove"
let URL_LIKE_CHECK = BASE_URL + "like/check"

let URL_COMMENT_ADD = BASE_URL + "comment/add"
let URL_COMMENT_LIST = BASE_URL + "comment/list"

let URL_PRIZE = BASE_URL + "giai-thuong?fm=json"
let URL_HOW_TO = BASE_URL + "huong-dan?fm=json"
let URL_FAQS = BASE_URL + "faqs?fm=json"

let IMAGE_PLACEHOLDER = UIImage(named: "no_image")

let imageDownloader = ImageDownloader(
	configuration: ImageDownloader.defaultURLSessionConfiguration(),
	downloadPrioritization: .fifo,
	maximumActiveDownloads: 4,
	imageCache: AutoPurgingImageCache()
)

func getThumbnailFrom(path: URL) -> UIImage? {
	do {
		let asset = AVURLAsset(url: path , options: nil)
		let imgGenerator = AVAssetImageGenerator(asset: asset)
		imgGenerator.appliesPreferredTrackTransform = true
		let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
		let thumbnail = UIImage(cgImage: cgImage)

		return thumbnail
	}
	catch let error {
		print("*** Error generating thumbnail: \(error.localizedDescription)")
		return UIImage(named: "no_image")
	}
}

func configLightbox() {
	LightboxConfig.CloseButton.text = LocalizedString("Close")
	LightboxConfig.DeleteButton.text = LocalizedString("Delete")
	LightboxConfig.InfoLabel.ellipsisText = LocalizedString("View more")
}

func isValidEmail(email: String) -> Bool {
	var returnValue = true
	let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"

	do {
		let regex = try NSRegularExpression(pattern: emailRegEx)
		let nsString = email as NSString
		let results = regex.matches(in: email, range: NSRange(location: 0, length: nsString.length))
		
		if results.count == 0 {
			returnValue = false
		}

	}
	catch let error as NSError {
		print("invalid regex: \(error.localizedDescription)")
		returnValue = false
	}

	return  returnValue
}

func LocalizedString(_ key: String) -> String {
	return NSLocalizedString(key, comment: "")
}

extension UIImageView {
	func downloadedFrom(videoURL url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
		contentMode = mode
		URLSession.shared.dataTask(with: url) {
			data, response, error in
			guard
				let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
				let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
				let data = data, error == nil,
				let image = UIImage(data: data)
				else {
					return
			}
			DispatchQueue.main.async() {
				self.image = image
			}
			}.resume()
	}
	
	func downloadedFrom(imageURL stringUrl: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
		guard let url = URL(string: stringUrl) else {
			print("Wrong format URL!")
			return
		}
		self.contentMode = mode

		imageDownloader.download(URLRequest(url: url)) {
			response in

			if let image = response.result.value as? UIImage {
				self.image = image
			}
			else {
				self.image = UIImage(named: "no_image")!
			}
		}
	}

	func downloadedFrom(link url: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
		downloadedFrom(imageURL: url, contentMode: mode)
	}
}

extension String {
	var htmlToAttributedString: NSAttributedString? {
		guard let data = data(using: String.Encoding.unicode, allowLossyConversion: true) else {
			return NSAttributedString()
		}
		do {
			return try NSAttributedString(
				data: data,
				options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
				documentAttributes: nil
			)
		}
		catch {
			return NSAttributedString()
		}
	}
	var htmlToString: String {
		return htmlToAttributedString?.string ?? ""
	}
}

extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")

		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}

	convenience init(hex: Int) {
		self.init(
			red: (hex >> 16) & 0xFF,
			green: (hex >> 8) & 0xFF,
			blue: hex & 0xFF
		)
	}
}

extension NSMutableData {
	func appendString(_ string: String) {
		let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
		append(data!)
	}
}

func addressFromPlacemark(_ placemark: CLPlacemark) -> String {
	let addressDictionary = placemark.addressDictionary
	let addressLines = addressDictionary!["FormattedAddressLines"] as? [String]

	return addressLines!.joined(separator: ", ")
}

func getPlacemark(forLocation location: CLLocation, completionHandler: @escaping (CLPlacemark?, String?) -> ()) {
	let geocoder = CLGeocoder()

	geocoder.reverseGeocodeLocation(location, completionHandler: {
		placemarks, error in

		if let err = error {
			completionHandler(nil, err.localizedDescription)
		}
		else if let placemarkArray = placemarks {
			if let placemark = placemarkArray.first {
				completionHandler(placemark, nil)
			}
			else {
				completionHandler(nil, "Location Manager: getPlacemark() - Placemark was nil")
			}
		}
		else {
			completionHandler(nil, "Location Manager: getPlacemark() - Unknown error")
		}
	})
}

func getCoordinate( addressString : String, completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
	let geocoder = CLGeocoder()

	geocoder.geocodeAddressString(addressString) { (placemarks, error) in
		if error == nil {
			if let placemark = placemarks?[0] {
				let location = placemark.location!

				completionHandler(location.coordinate, nil)
				return
			}
		}

		completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
	}
}

func getFileName(path: NSURL) -> String {
	return (path.path as! NSString).lastPathComponent
}

func getMimeType(path: NSURL) -> String {
	let pathExtension = path.pathExtension

	if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
		if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
			return mimetype as String
		}
	}
	return "application/octet-stream"
}
