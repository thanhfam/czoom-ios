//
//  PageViewController.swift
//  Traffic Zoom
//
//  Created by Thanh Phạm on 12/27/17.
//  Copyright © 2017 3T Asia. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class HowToController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
	var subViewControllers:[UIViewController] = []
	var defaultViewController = UIViewController()

	var activityIndicator = UIActivityIndicatorView()
	var pageControl = UIPageControl()
	var btnSkip = UIButton()

	var configuration: URLSessionConfiguration! = nil
	var sessionManager: SessionManager! = nil

	override func viewDidLoad() {
		super.viewDidLoad()

		self.delegate = self
		self.dataSource = self

		if (self.sessionManager == nil) {
			self.configuration = URLSessionConfiguration.default
			self.sessionManager = Alamofire.SessionManager(configuration: configuration)
		}

		setupActivityIndicator()

		loadContent()

		print("Function : \(#function), Class: \(type(of: self))")
	}

	func setupActivityIndicator() -> Void {
		activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
		activityIndicator.center = defaultViewController.view.center
		activityIndicator.hidesWhenStopped = true
		activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray

		defaultViewController.view.backgroundColor = UIColor.white
		defaultViewController.view.addSubview(activityIndicator)

		setViewControllers(
			[defaultViewController],
			direction: .forward,
			animated: true,
			completion: nil
		)
	}

	func showActivityIndicator() -> Void {
		activityIndicator.startAnimating()
	}

	func hideActivityIndicator() -> Void {
		self.activityIndicator.stopAnimating()
	}

	func loadContent() -> Void {
		self.showActivityIndicator()

		self.sessionManager
			.request(URL_HOW_TO, method: .get)
			.responseJSON {
				response in
				switch response.result {
				case .success:
					self.hideActivityIndicator()

					if let jsonData = response.result.value {
						let json = jsonData as! NSDictionary

						if let postList = json.value(forKey: "list_post") as? NSArray {

							for postData in postList {
								let post = postData as! NSDictionary
								let imageURL = post.value(forKey: "avatar_url") as! String
								let content = post.value(forKey: "lead") as! String

								self.createSubViewController(imageURL: imageURL, content: content)
							}

							if self.subViewControllers.count > 0 {
								self.setViewControllers(
									[self.subViewControllers[0]],
									direction: .forward,
									animated: true,
									completion: nil
								)

								self.configurePageControl()
							}
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

	func createSubViewController(imageURL url: String, content html: String) -> Void {
		let viewController = UIViewController()
		viewController.view.backgroundColor = UIColor.white

		let imageView: UIImageView = UIImageView(frame: CGRect(x: 10, y: UIScreen.main.bounds.maxY / 2 - 300, width: UIScreen.main.bounds.width - 20, height: 300))
		imageView.setImage(url: URL(string: url)!)
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true

		viewController.view.addSubview(imageView)

		let label: UILabel = UILabel()
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.textAlignment = .center
		label.text = html
		label.frame.origin.x = 20
		label.frame.origin.y = UIScreen.main.bounds.maxY / 2
		label.frame.size.width = UIScreen.main.bounds.width - 40
		label.sizeToFit()
		viewController.view.addSubview(label)

		subViewControllers.append(viewController)
	}

	func configurePageControl() -> Void {
		pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 50, width: UIScreen.main.bounds.width, height: 50))
		pageControl.numberOfPages = subViewControllers.count
		pageControl.currentPage = 0
		pageControl.pageIndicatorTintColor = UIColor.lightGray
		pageControl.currentPageIndicatorTintColor = UIColor.darkGray
		self.view.addSubview(pageControl)

		btnSkip = UIButton.init(type: .system) as UIButton
		btnSkip.frame = CGRect(x: 0, y: UIScreen.main.bounds.maxY - 70, width: UIScreen.main.bounds.width, height: 30)

		btnSkip.setTitle(LocalizedString("Skip"), for: .normal)
		//btnSkip.setTitleColor(UIColor.lightGray, for: .normal)
		//btnSkip.setTitleColor(UIColor.darkGray, for: .highlighted)

		btnSkip.addTarget(self, action: #selector(skipMe(_:)), for: .touchUpInside)

		self.view.addSubview(btnSkip)
	}

	@objc func skipMe(_ sender: UIButton!) -> Void {
		self.dismiss(animated: true, completion: nil)
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		guard let currentIndex: Int = subViewControllers.index(of: viewController) else {
			return nil
		}

		let prevIndex = currentIndex - 1

		guard prevIndex >= 0 else {
			//return subViewControllers.last
			return nil
		}

		guard subViewControllers.count > prevIndex else {
			return nil
		}

		return subViewControllers[prevIndex]
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let currentIndex: Int = subViewControllers.index(of: viewController) else {
			return nil
		}

		let nextIndex = currentIndex + 1

		guard subViewControllers.count != nextIndex else {
			//return subViewControllers.first
			return nil
		}

		guard subViewControllers.count > nextIndex else {
			return nil
		}

		return subViewControllers[nextIndex]
	}

	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		let currentViewController = pageViewController.viewControllers![0]
		self.pageControl.currentPage = subViewControllers.index(of: currentViewController)!
	}

	func showMessage(message: String, OKAction: UIAlertAction? = nil) {
		let alertController = UIAlertController(title: LocalizedString("Alert"), message: message, preferredStyle: .alert)

		if let OKAction = OKAction {
			alertController.addAction(OKAction)
		}
		else {
			alertController.addAction(UIAlertAction(title: LocalizedString("OK"), style: .default, handler: nil))
		}

		self.present(alertController, animated: true, completion:nil)
	}
}
