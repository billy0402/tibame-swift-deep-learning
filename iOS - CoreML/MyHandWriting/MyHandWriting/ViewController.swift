//
//  ViewController.swift
//  MyHandWriting
//
//  Created by User on 2018/11/10.
//  Copyright © 2018 User. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var drawBaseView: UIView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var resultTextView: UITextView!
    
    var drawableView: DrawableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        createDrawableView()
    }
    
    // override func viewDidAppear(_ animated: Bool) {
    //     createDrawableView()
    // }
    
    @IBAction func predictButtonTap(_ sender: Any) {
        let originalImage = drawableView.toImage()
        let size = CGSize(width: 28, height: 28)
        
        guard let resizedImage = originalImage.resize(to: size) else {
            assertionFailure("Failed to resize image.")
            return
        }
        
        resultImageView.image = resizedImage
        
        let model = MyHandWriteV1()
        
        guard let result = try? model.prediction(input_image__0: resizedImage.pixelBuffer()!) else {
            assertionFailure("Failed to predict image.")
            return
        }

        // var info = "\(result.classLabel) ==> \n"
        // info += result.prediction__0.map {
        //     "\($0.key): \($0.value)"
        //     }.joined(separator: "\n")
        
        let info = result.prediction__0
            .reduce("\(result.classLabel) ==> \n")
            {
                "\($0)\($1.key): \($1.value)\n"
            }
    
        resultTextView.text! = info + resultTextView.text
        
        createDrawableView()
    }
    
    @IBAction func clearButtonTap(_ sender: Any) {
        createDrawableView()
    }
    
    func createDrawableView() {
        // Remove old one
        if drawableView != nil {
            drawableView.removeFromSuperview()
        }
        
        // Create new one
        drawableView = DrawableView(frame: drawBaseView.bounds)
        drawableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        drawableView.backgroundColor = .black
        drawableView.isUserInteractionEnabled = true
        
        drawBaseView.addSubview(drawableView)
    }
    
}

extension UIView {
    
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { (context) in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        
        return image
    }
    
}

