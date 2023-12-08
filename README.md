# ImagesToVideo

This repository contains a test project for the DTS Case-ID: 5194461. 

The test app has a simple UI and produces a video from a sequence of CIImages (always the same, plain red CIImage for every frame). The video writing is triggered using a simple UIButton.
Every frame is added to the video in a foor loop. 90 frames are added, with 30 fps to produce a video of 3 seconds. 

The app saves the video in the documents directory but fails to save it in the photo library, throwing an error. The error.localizedDescription is displayed in an alert view.
The video is present in the documents directory and plays without problems. 
Also, when saving the video from the File's App, it saves in the photo library without problems.

The code is minimal (as requested) but it mimics exactly what the real app tries to do (assembling CIImages into video). Maybe there are inefficiencies in this code and every feedback is appreciated. However, please focus on the main problem: 
the PHPhotoLibrary.shared().performChanges fails throwing an error (the operation couldn’t be completed. (PHPhotosErrorDomain error 3300.)). This error is not due to access permissions to the photo library. The app askes for permission and has the necessary string in the Info.plists.  
