//
//  ViewController.swift
//  PicTravel
//
//  Created by Dragos Andrei Holban on 27/07/2017.
//  Copyright © 2017 IntelligentBee. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var selectPhotoButton: UIButton!
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func selectPhotoClicked(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {action in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { action in
            picker.sourceType = .photoLibrary
            // on iPad we are required to present this as a popover
            if UIDevice.current.userInterfaceIdiom == .pad {
                picker.modalPresentationStyle = .popover
                picker.popoverPresentationController?.sourceView = self.view
                picker.popoverPresentationController?.sourceRect = self.selectPhotoButton.frame
            }
            self.present(picker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // on iPad this is a popover
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = selectPhotoButton.frame
        self.present(alert, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        image = info[UIImagePickerControllerOriginalImage] as! UIImage
        performSegue(withIdentifier: "showImageSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageSegue" {
            if let shareViewController = segue.destination as? ShareViewController {
                shareViewController.image = self.image
                shareViewController.name = name.text ?? ""
                shareViewController.message = message.text ?? ""
            }
        }
    }
    
    @IBAction func exit(unwindSegue: UIStoryboardSegue) {
        image = nil
    }
}

