//
//  ViewController.swift
//  MyVision
//
//  Created by User on 2018/11/11.
//  Copyright © 2018 User. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    
    let session = AVCaptureSession() // Video -> Session -> Preview & Predict
    var previewLayer: AVCaptureVideoPreviewLayer!
    let captureQueue = DispatchQueue(label: "BackgroundCapture")
    var requests = Array<VNRequest>() // must be array!
    let minConfidence: VNConfidence = 0.3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.layoutIfNeeded()
        
        // Prepare to capture video from camera.
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let inputDevice = try? AVCaptureDeviceInput(device: captureDevice) else {
            assertionFailure("Failed to have video capture device.")
            return
        }
        
        session.addInput(inputDevice)
        
        // Prepare to preview.
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.frame
        previewView.layer.addSublayer(previewLayer)
        
        // Prepare for video data output.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        session.addOutput(videoOutput)
        
        // Prepare model.
//        let model = Inceptionv3().model
        let model = PetsClassifier().model
        guard let visionModel = try? VNCoreMLModel(for: model) else {
            assertionFailure("Failed to create VNCoreMLModel.")
            return
        }
        
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: classificationRequestHandler)
        classificationRequest.imageCropAndScaleOption = .centerCrop
        requests = [classificationRequest]
        
        // Start session.
        session.startRunning()
    }
    
    private func classificationRequestHandler(request: VNRequest, error: Error?) {
        if let error = error {
            print("Error: \(error)")
            return
        }
        
        guard let observations = request.results as? [VNClassificationObservation] else {
            print("No results.")
            return
        }
        
        let results = observations
            .compactMap { (observation) in
                return observation.confidence > minConfidence ? observation : nil
            }.compactMap { (observation) in
                return "\(observation.identifier)" + String(format: "%.2f", observation.confidence)
        }.joined(separator: "\n")
        
        // Show result.
        DispatchQueue.main.async {
            self.resultLabel.text = results
        }
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            assertionFailure("Failed to transform CMSampleBuffer to CVImageBuffer.")
            return
        }
        connection.videoOrientation = .portrait
        
        var options = [VNImageOption: Any]()
        if let intrinsicData = CMGetAttachment(sampleBuffer,
                                               key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                                               attachmentModeOut: nil) {
            options = [.cameraIntrinsics: intrinsicData]
        }
        
        // .upMirrored >> reverse camera image
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: options)
        try? handler.perform(requests)
    }

}

