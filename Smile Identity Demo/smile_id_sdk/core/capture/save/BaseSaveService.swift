//
//  BaseSaveService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class BaseSaveService : BaseService {
    
    let logger                              = SILog()
    
    func saveFrameData( frame : FrameData,
                        filename : String,
                        orientation : Int,
                        referenceId : String ) -> CapturedImage {
      
        writeImageToFile(data: frame.frameBytes!,
                         referenceId: referenceId,
                         filename: filename )
        let fullFrameInfo = FullFrameInfo( smileValue:
            frame.smileValue,
            fileName: filename,
            dateTime: frame.dateTime! )
        fullFrameInfo.setExifData( orientation: orientation,
            imageWidth: frame.width!,
            imageLength: frame.height! )
        
        return CapturedImage( filename: filename,
                            fullFrameInfo: fullFrameInfo )
     
        
    }

    
    func writeImageToFile( data         : Data,
                           referenceId  : String,
                           filename     : String ) {
        do {
            let siFileManager = SIFileManager()
            let fullFilePath = siFileManager.getFullFilePath(referenceId: referenceId, filename: filename)

            let url = URL(fileURLWithPath:fullFilePath)
            try data.write( to: URL(fileURLWithPath:fullFilePath) )
            
            // TEST
            let fileManager = FileManager.default
            // let url = URL(string: fullFilePath)
            
            // This returns true
            var fileExists = fileManager.fileExists(atPath: (url.path) )
            self.logger.SIPrint( logOutput: "fileExists = " + String( fileExists ) )
   
            // this returns true
            fileExists = siFileManager.fileExists( fullFilePath: fullFilePath )
            self.logger.SIPrint( logOutput: "fileExists = " + String( fileExists ) +
            ", fullFilePath = " + fullFilePath)
            
            
            var fileSize = siFileManager.getFileSize( filePath: fullFilePath )
            self.logger.SIPrint( logOutput:  "fileSize = " + String( fileSize ) )
            
     
        } catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "BaseSaveService : writeImageToFile() : An error occurred writing to file " + filename )
        }
    
        
    }
    
    
 
  
}
