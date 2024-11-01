//
//  ViewController.swift
//  WhatFlower-iOS
//
//  Created by Harting, R.P.G. (Rob) on 28/10/2024.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import ColorThiefSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var pickedImage: UIImage?
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage  = info[.editedImage] as? UIImage {
            
            guard let convertedCiImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage.")
            }
            
            pickedImage = userPickedImage
            
            detect(flowerImage: convertedCiImage)
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classificationResult = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            
            self.navigationItem.title = classificationResult.identifier.capitalized
            self.requestInfo(flowerName: classificationResult.identifier)
            
            
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "piprop" : "thumbnail",
            "pithumbsize": "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info.")
                //                print(response)
                //print("response.result.value: \(response.result.value!)")
                
                let flowerJSON: JSON = JSON(response.result.value!)
                //print("flowerJSON: \(flowerJSON)")
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                //                print("pageid: \(pageid)")
                //                print("flower Description: \(flowerDescription)")
                //                print("flowerImageURL: \(flowerImageURL)")
                //                print(flowerJSON)
                
                self.infoLabel.text = flowerDescription
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: { (image, error,  cache, url) in
                    
                    if let currentImage = self.imageView.image {
                        
                        guard let dominantColor = ColorThief.getColor(from: currentImage) else {
                            fatalError("Can't get dominant color")
                        }
                        
                        
                        DispatchQueue.main.async {
                            self.navigationController?.navigationBar.isTranslucent = true
                            self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                            
                            
                        }
                    } else {
                        self.imageView.image = self.pickedImage
                        self.infoLabel.text = "Could not get information on flower from Wikipedia."
                    }
                    
                })
                
            }
            else {
                print("Error \(String(describing: response.result.error))")
                self.infoLabel.text = "Connection Issues"
                
                
                
            }
        }
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

