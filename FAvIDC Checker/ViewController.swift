//
//  ViewController.swift
//  FAvIDC Checker
//
//  Created by user244707 on 8/9/23.
//

import Photos
import PhotosUI
import UIKit
import TensorFlowLiteTaskVision


class ViewController: UIViewController, PHPickerViewControllerDelegate {
    private var imageClassificationHelper: ImageClassificationHelper? =
    ImageClassificationHelper(modelFileInfo: (name:"model-2",extension:"tflite"))
    var inferenceResult: ImageClassificationResult?=nil
    var myCollectionViewController: MyCollectionViewController!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let myCollectionViewController = segue.destination as? MyCollectionViewController {
            self.myCollectionViewController = myCollectionViewController
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FAvIDC Checker"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        // Do any additional setup after loading the view.
    }

    @objc private func didTapAdd() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images	
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        present(vc, animated: true)
        
    }
    
    func picker(_ picker:PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        let group = DispatchGroup()
        results.forEach{ result in
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) {[weak self] reading, error in
                defer {
                    group.leave()
                }
                guard let image = reading as? UIImage, error==nil else{
                    return
                }
                self?.images.append(image)
            }
        }
        group.notify(queue: .main) {
            print(self.images.count)
            if(!self.images.isEmpty){
                let frame = self.buffer(from:self.images.last!)!
                var result = self.imageClassificationHelper?.classify(frame: frame)
                self.inferenceResult = result
                let strings = self.displayStringsForResults(atRow: 0, result:result!)
                self.labels.append(strings)
                // Create a new alert
//                var dialogMessage = UIAlertController(title: "Results", message: ((self.labels.last?.0 ?? "No Result")+": "+(self.labels.last?.1 ?? "")), preferredStyle: .alert)
//
//                // Present alert to user
//                self.present(dialogMessage, animated: true, completion: nil)
                self.myCollectionViewController.dataSource.insert(self.textToImage(drawText: strings.0, inImage: self.images.last!, atPoint: CGPointMake(100,200)), at: 0)
                                
            }

        }
    }
    private var images = [UIImage]()
    private var labels = [(String,String)]()
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(224), height: Int(224), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    func displayStringsForResults(atRow row: Int, result inferenceResult: ImageClassificationResult) -> (String, String) {
        var fieldName: String = ""
        var info: String = ""
        let tempResult = inferenceResult
        guard tempResult.classifications.categories.count > 0 else {
            
            if row == 0 {
                fieldName = "No Results"
                info = ""
            } else {
                fieldName = ""
                info = ""
            }
            
            return (fieldName, info)
        }
        
        if row < tempResult.classifications.categories.count {
            let category = tempResult.classifications.categories[row]
            if(category.index==0){
                fieldName = "FA"
            }else if(category.index == 1){
                fieldName = "IDC"
            }else {
                fieldName = String(category.index)
            }
            info = String(format: "%.2f", category.score * 100.0) + "%"
        } else {
            fieldName = ""
            info = ""
        }
        
        return (fieldName, info)
    }
    
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: 12)!

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224.0, height: 224.0), false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: 224.0, height: 224.0)))

        let rect = CGRect(origin: point, size: CGSize(width: 224.0, height: 224.0))
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

}

