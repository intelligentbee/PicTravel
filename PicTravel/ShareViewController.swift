//
//  ShareViewController.swift
//  PicTravel
//
//  Created by Dragos Andrei Holban on 28/07/2017.
//  Copyright © 2017 IntelligentBee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ShareViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    var image: UIImage!
    var name: String!
    var message: String!
    var locationManager:CLLocationManager!
    var locationString = ""
    var mapImage: UIImage!
    
    // some constants used to generate the final image
    let finalImageMaxDimension: CGFloat = 2048
    let finalImageBorderWidth: CGFloat = 4
    let userImageMaxDimension: CGFloat = 1200
    let userImageBorderWidth: CGFloat = 20
    let userImageX: CGFloat = 100
    let userImageY: CGFloat = 160
    let mapRegionDistance: CLLocationDistance = 600
    let rotateContentByDegrees: CGFloat = -4
    let userMessageMaxLength = 100
    let textMargin: CGFloat = 280
    let userMessageTopMargin: CGFloat = 60
    let userNameTopMargin: CGFloat = 80
    let userNameHeight: CGFloat = 120

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.authorizationStatus() == .denied) {
            showError(title: "Location Access Denied", message: "The location permission was not authorized. Please enable it in Privacy Settings to allow the app to get your location and generate a map image based on that.")
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func showError(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        manager.stopUpdatingLocation()
        
        // get city & country name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if error != nil {
                self.showError(title: "Whoops...", message: error!.localizedDescription)
            } else {
                let placemark = placemarks?[0]
                self.locationString = (placemark?.administrativeArea ?? "") + ", " + (placemark?.country ?? "")
                self.generateMapImage(location: location)
            }
        })
    }
    
    func generateMapImage(location userLocation: CLLocation) {
        let mapSnapshotOptions = MKMapSnapshotOptions()
        
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        let region = MKCoordinateRegionMakeWithDistance(location, mapRegionDistance, mapRegionDistance)
        mapSnapshotOptions.region = region
        
        // Set the size of the image output.
        mapSnapshotOptions.size = calculateMapImageSize()
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        snapShotter.start(completionHandler: { snapShot, error in
            if error != nil {
                self.showError(title: "Whoops1...", message: error!.localizedDescription)
            } else {
                self.mapImage = snapShot?.image
                self.activityIndicator.stopAnimating()
                self.generateFinalImage()
            }
        })
    }
    
    func calculateMapImageSize() -> CGSize  {
        let maxSize = finalImageMaxDimension - 2 * finalImageBorderWidth
        if image.size.width > image.size.height {
            return CGSize(width: maxSize, height: round(maxSize * image.size.height / image.size.width))
        } else {
            return CGSize(width: round(maxSize * image.size.width / image.size.height), height: maxSize)
        }
    }
    
    func generateFinalImage() {
        let size = CGSize(width: mapImage.size.width + 2 * finalImageBorderWidth, height: mapImage.size.height + 2 * finalImageBorderWidth)
        let userImageSize = calculateUserImageFinalSize()
        
        // start drawing context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the white background
        let bgRectangle = CGRect(x: 0, y: 0, width: mapImage.size.width + 2 * finalImageBorderWidth, height: mapImage.size.height + 2 * finalImageBorderWidth)
        context!.saveGState()
        context!.setFillColor(UIColor.white.cgColor)
        context!.addRect(bgRectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // draw the map
        mapImage.draw(in: CGRect(x: finalImageBorderWidth, y: finalImageBorderWidth, width: mapImage.size.width, height: mapImage.size.height))
        
        // draw a semitransparent white rectage over the  map to dim it
        let transparentRectangle = CGRect(x: finalImageBorderWidth, y: finalImageBorderWidth, width: mapImage.size.width, height: mapImage.size.height)
        context!.saveGState()
        context!.setFillColor(UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha: 0.3).cgColor)
        context!.addRect(transparentRectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // rotate the context
        context!.rotate(by: (rotateContentByDegrees * CGFloat.pi / 180))
        
        // draw white rectangle
        let rectangle = CGRect(x: userImageX, y: userImageY, width: userImageSize.width + 2 * userImageBorderWidth, height: userImageSize.height + 2 * userImageBorderWidth)
        context!.saveGState()
        context!.setFillColor(UIColor.white.cgColor)
        context!.setShadow(offset: CGSize(width: userImageBorderWidth, height: userImageBorderWidth), blur: 8.0)
        context!.addRect(rectangle)
        context!.drawPath(using: .fill)
        context!.restoreGState()
        
        // draw user image
        image.draw(in: CGRect(x: userImageX + userImageBorderWidth, y: userImageY + userImageBorderWidth, width: userImageSize.width, height: userImageSize.height))
        
        // draw message
        var truncatedMessage = message
        if (message.distance(from: message.startIndex, to: message.endIndex) > userMessageMaxLength) {
            truncatedMessage = message.substring(to: message.index(message.startIndex, offsetBy: userMessageMaxLength))
        }
        let messageFont = UIFont(name: "Noteworthy-Bold", size: 80)!
        let messageFontAttributes = [
            NSFontAttributeName: messageFont,
            NSForegroundColorAttributeName: UIColor.black,
            ] as [String : Any]
        let messageSize = sizeOfString(string: truncatedMessage!, constrainedToWidth: Double(size.width - textMargin), attributes: messageFontAttributes)
        truncatedMessage!.draw(in: CGRect(x: userImageX + userImageBorderWidth, y: userImageY + userImageBorderWidth + userImageSize.height + userMessageTopMargin, width: size.width - textMargin, height: messageSize.height), withAttributes: messageFontAttributes)
        
        // draw name, location & date
        let nameFont = UIFont(name: "Noteworthy", size: 58)!
        let nameFontAttributes = [
            NSFontAttributeName: nameFont,
            NSForegroundColorAttributeName: UIColor.black,
            ] as [String : Any]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        var nameString = ""
        if(name != "") {
            nameString = name + " - " + dateFormatter.string(from: Date()) + ", " + locationString
        } else {
            nameString = dateFormatter.string(from: Date()) + ", " + locationString
        }
        nameString.draw(in: CGRect(x: userImageX + userImageBorderWidth, y: userImageY + userImageBorderWidth + userImageSize.height + messageSize.height + userNameTopMargin, width: size.width - textMargin, height: userNameHeight), withAttributes: nameFontAttributes)
        
        // get final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end drawing context
        UIGraphicsEndImageContext()
        
        // show the final image to the user & update tha status label
        imageView.image = finalImage
        titleLabel.text = "You can now share your image."
    }
    
    func calculateUserImageFinalSize() -> CGSize  {
        if image.size.width > image.size.height {
            return CGSize(width: userImageMaxDimension, height: round(userImageMaxDimension * image.size.height / image.size.width))
        } else {
            return CGSize(width: round(userImageMaxDimension * image.size.width / image.size.height), height: userImageMaxDimension)
        }
    }
    
    func sizeOfString (string: String, constrainedToWidth width: Double, attributes: [String: Any]) -> CGSize {
        let attString = NSAttributedString(string: string,attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        getCurrentLocation()
    }
    
    @IBAction func shareImage(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true, completion: nil)
    }
}
