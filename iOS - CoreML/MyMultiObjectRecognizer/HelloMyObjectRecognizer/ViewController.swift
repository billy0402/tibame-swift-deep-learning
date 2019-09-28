//
//  ViewController.swift
//  HelloMyObjectRecognizer
//
//  Created by Kent Liu on 2018/7/27.
//  Copyright © 2018年 SoftArts Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  @IBOutlet weak var result1Label: UILabel!
  @IBOutlet weak var result2Label: UILabel!
  
  let captureSession = AVCaptureSession()
  let captureQueue = DispatchQueue(label: "BackgroundCaptureQueue")
  var previewLayer: AVCaptureVideoPreviewLayer!
  var visionRequests = [VNRequest]()  // Note! It must be a array.
  let minimumConfidence: VNConfidence = 0.3

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Prepare Input & Capture.
    
    guard let captureDevice = AVCaptureDevice.default(for: .video) else {
      assertionFailure("Fail to create capture device.")
      return
    }
    guard let inputDevice = try? AVCaptureDeviceInput(device: captureDevice) else {
      assertionFailure("Fail to create capture device input.")
      return
    }
    captureSession.addInput(inputDevice)
    
    // Prepare Output & CoreML.
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    videoOutput.connection(with: .video)?.videoOrientation = .portrait
    
    captureSession.addOutput(videoOutput)
    
    // Prepare CoreML Support.
//    let model = Inceptionv3().model
    let ageModel = AgeNet().model
    guard let ageVisionModel = try? VNCoreMLModel(for: ageModel) else {
      assertionFailure("Fail to load model.")
      return
    }
    let ageClassificationRequest = VNCoreMLRequest(model: ageVisionModel, completionHandler: handleAgeClassifications)
    ageClassificationRequest.imageCropAndScaleOption = .centerCrop
    
    let genderModel = GenderNet().model
    guard let genderVisionModel = try? VNCoreMLModel(for: genderModel) else {
      assertionFailure("Fail to load model.")
      return
    }
    let genderClassificationRequest = VNCoreMLRequest(model: genderVisionModel, completionHandler: handleGenderClassifications)
    genderClassificationRequest.imageCropAndScaleOption = .centerCrop
    
    visionRequests = [ageClassificationRequest, genderClassificationRequest]
    
    // Prepare Preview.
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = self.view.bounds
    self.view.layer.addSublayer(previewLayer)
    
    // Run the session.
    captureSession.startRunning()
    
    self.view.bringSubview(toFront: result1Label)
    self.view.bringSubview(toFront: result2Label)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Method.
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    
    connection.videoOrientation = .portrait
    
    var options = [VNImageOption:Any]()
    
    if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
      options = [.cameraIntrinsics: cameraIntrinsicData]
    }
    
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: options)
    do {
      try imageRequestHandler.perform(visionRequests)
    } catch {
      print("imageRequestHandler error: \(error)")
    }
    
  }
  
  
  func handleAgeClassifications(request: VNRequest, error: Error?) {
    
    if let error = error {
      print("handleClassifications error: \(error)")
      return
    }
    
    guard let observations = request.results else {
      print("No result.")
      return
    }
/*
    let result = observations[0...4].compactMap { (observation) -> VNClassificationObservation? in
      return observation as? VNClassificationObservation
      }.compactMap { (observation) -> VNClassificationObservation? in
        return (observation.confidence > minimumConfidence ? observation : nil)
      }.compactMap { (observation) -> String? in
        let confidence = String(format: "%.2f",observation.confidence)
        return "\(observation.identifier) \(confidence)\n"
    }.joined()
*/
    let max = (observations.count > 4 ? 4 : observations.count-1)
    
    let result = observations[0...max].compactMap { $0 as? VNClassificationObservation }
      .compactMap { $0.confidence > minimumConfidence ? $0 : nil }
      .compactMap {
        let confidence = String(format: "%.2f",$0.confidence)
        return "\($0.identifier) \(confidence)\n"
      }.joined()
    
    // Display at resultLabel.
    if !result.isEmpty {
      DispatchQueue.main.async {
        self.result2Label.text = result
        print(result)
      }
    }
  }

  func handleGenderClassifications(request: VNRequest, error: Error?) {
    
    if let error = error {
      print("handleClassifications error: \(error)")
      return
    }
    
    guard let observations = request.results else {
      print("No result.")
      return
    }
    /*
     let result = observations[0...4].compactMap { (observation) -> VNClassificationObservation? in
     return observation as? VNClassificationObservation
     }.compactMap { (observation) -> VNClassificationObservation? in
     return (observation.confidence > minimumConfidence ? observation : nil)
     }.compactMap { (observation) -> String? in
     let confidence = String(format: "%.2f",observation.confidence)
     return "\(observation.identifier) \(confidence)\n"
     }.joined()
     */
    let max = (observations.count > 4 ? 4 : observations.count-1)
    
    let result = observations[0...max].compactMap { $0 as? VNClassificationObservation }
      .compactMap { $0.confidence > minimumConfidence ? $0 : nil }
      .compactMap {
        let confidence = String(format: "%.2f",$0.confidence)
        return "\($0.identifier) \(confidence)\n"
      }.joined()
    
    // Display at resultLabel.
    if !result.isEmpty {
      DispatchQueue.main.async {
        self.result1Label.text = result
        print(result)
      }
    }
    
    
  }
  

}

