//
//  ViewController.swift
//  ImagesToVideo
//
//  Created by Salvatore De Angelis on 08/12/2023.
//

import UIKit
import AVFoundation
import Photos
import CoreImage

class ViewController: UIViewController {
    
    let button = UIButton(type: .system)
    let label = UILabel()
    let label2 = UILabel()
    // Set of variables for the AVAsset Writer
    var writer : AVAssetWriter!
    var width : Int = 0
    var height : Int = 0
    var adaptor : AVAssetWriterInputPixelBufferAdaptor!
    var input : AVAssetWriterInput!
    var outputMovieURL : URL!
    // Variables for CIImage
    var ciContext = CIContext()
    var metalDevice : MTLDevice!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        layoutButton()
        setupCenteredLabel()
        setupTopLabel()
        metalDevice = MTLCreateSystemDefaultDevice()
        
        // Setup the context with RGBA8
        ciContext = CIContext(mtlDevice: metalDevice, options: [.workingFormat : CIFormat.RGBA8,
                                                                          .workingColorSpace: NSNull(),
                                                                          .cacheIntermediates : false,
                                                                          .highQualityDownsample: true])
        
        // We get the writer ready to write
        setUpWriter()
        
    }
    
    func layoutButton() {
        
        button.setTitle("Produce video", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.gray, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.backgroundColor = .cyan
        
        // Add the button to the view
        self.view.addSubview(button)
        
        // Disable the autoresizing mask
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // Align the button's center X to the view's center X
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            // Set the button's bottom anchor 20 points from the bottom of the view
            button.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -200
                                          ),
            // Set the button's width to 300 points
            button.widthAnchor.constraint(equalToConstant: 300),
            // Set the button's height to 50 points
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

    }
    
    
    func setupTopLabel() {
        
        // Set the label's text and font size
        label2.text = "Press the button, wait for 3 seconds"
        label2.font = UIFont.systemFont(ofSize: 18)
        label2.textColor = .white
        
        // Add the label to the view
        view.addSubview(label2)
        
        // Disable the autoresizing mask
        label2.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // Center the label horizontally in the view
            label2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Center the label vertically in the view
            label2.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
        ])
    }
    
    func setupCenteredLabel() {
        
        // Set the label's text and font size
        label.text = "Ready to write video"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        
        // Add the label to the view
        view.addSubview(label)
        
        // Disable the autoresizing mask
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // Center the label horizontally in the view
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Center the label vertically in the view
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func didTapButton() {
        
        // We start writing
        writer.startWriting()
        // The session start from 0
        writer.startSession(atSourceTime: CMTime.zero)
        
        // The goal for this test here is to produce a 3 seconds video from a costant CIImage
        // This mimic what the real application is trying to do
        let fps = 30
        let totalSeconds = 3
        let numFrames = fps * totalSeconds
        
        // The constant CIImage
        // This frame mimics a 4k video frame, the width and height match what specified (hard coded) in the CVPixelBufferCreate
        let frame = CGRect(x: 0, y: 0, width: 2160, height: 3840)
        let ciImage = CIImage(color: CIColor.red).cropped(to: frame)
        
        var frameCount = 0
        var shouldWrite = true
        
        
        while shouldWrite == true {
            
            if input.isReadyForMoreMediaData {
                
                
                print(frameCount)
                
                
                guard let buffer = createBufferFromCiImage(ciImage: ciImage, context: ciContext) else { return }
                let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(fps))
                adaptor.append(buffer, withPresentationTime: frameTime)
                
                frameCount += 1
                if frameCount > numFrames {
                    shouldWrite = false
                }
            }
            
        }
        
        label.text = "Saving..."
        
        // Finished writing
        input.markAsFinished()
        writer.finishWriting {
            print("Saving...")
            self.saveInPhotoLibrary()
            self.setUpWriter()
        }
        
    }

    
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    func produceRXFileName() -> String {
        let date = Date.now
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy_HH_mm_ss"
        let string = "RX_" + formatter.string(from: date)
        return string
    }
    
    func makeVideoURL() -> URL {
        
        let tmpDir = getDocumentsDirectory()
        let fileName = produceRXFileName()
        return tmpDir.appending(path: fileName).appendingPathExtension("MOV")
    }
    
    // This is the function that fails
    func saveInPhotoLibrary() {
        
        PHPhotoLibrary.requestAuthorization { status in
            
            switch status {
            case .denied:
                print("User did not allow access to the camera")
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    // Add the captured photo's file data as the main resource for the Photos asset.
                    let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: self.outputMovieURL)
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = false
                    print(self.outputMovieURL!)
                    creationRequest?.addResource(with: .video, fileURL: self.outputMovieURL, options: options)
                }, completionHandler: { success, error in
                    // Here is where it fails
                    if success {
                        print("Saved in photo library")
                    } else {
                        if let error = error {
                            print(error)
                            
                            // error: The operation couldn’t be completed. (PHPhotosErrorDomain error 3300.)
                            // The video is correctly saved in the documents directory, accessible via the File App.
                            // When saving the video from the File App, it correctly saves in the camera roll
                            DispatchQueue.main.async {
                                
                                self.label.text = "Ready to write video"
                                let customText = "Please, open the Files App, navigate to the folder corresponding to this app. You will find the video is correctly saved and can be playeed without problems."
                                let errorMessage = error.localizedDescription + "\n" + customText
                                self.displayErrorAlert(text: errorMessage)
                            }
                            
                        }
                        
                    }
                })
            default:
                ()
            }
        }
    }
    
    // This helper function displays an alert with the error message
    func displayErrorAlert(text: String) {
        
        // Create the alert controller
        let alert = UIAlertController(title: "Error in saving in photo library", message: text, preferredStyle: .alert)
        // Add an action for the button
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        // Present the alert
        self.present(alert, animated: true, completion: nil)
        
    }

}

//MARK: -- This extension contains some help functions for the video writing process
extension ViewController {
    
    // 1: Create the buffer from a CIImage
    func createBufferFromCiImage(ciImage: CIImage, context: CIContext) -> CVPixelBuffer? {
        
        // Atttributes
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        width = Int(ciImage.extent.size.width)
        height = Int(ciImage.extent.size.height)
        
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)
        
        if let buffer = pixelBuffer {
            
            context.render(ciImage, to: buffer)
            return pixelBuffer
            
        } else {
            return nil
        }
    }
    
    // 2: General setup of the writer
    
    func setUpWriter() {
        
        outputMovieURL = makeVideoURL()
        writer = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mov)
        let assetWriterSettings = [AVVideoCodecKey: AVVideoCodecType.hevc,
                                  AVVideoWidthKey : 2160,
                                  AVVideoHeightKey: 3840] as [String : Any]
        
        // let settingsAssistant = AVOutputSettingsAssistant(preset: .preset3840x2160)?.videoSettings
        
        input = AVAssetWriterInput(mediaType: .video, outputSettings: assetWriterSettings)
        // let pixelAttr = [kCVPixelBufferPixelFormatTypeKey :  kCVPixelFormatType_32BGRA] as [String : Any]
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer?.add(input)
        
    }
    
}

