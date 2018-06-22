//
//  BaseSaveService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class BaseSaveService : BaseService {
    
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
            let siFileManager = SIFileFileManager()
            let fullFilePath = siFileManager.getFullFilePath(referenceId: referenceId, filename: filename)

            try data.write( to: URL(fileURLWithPath:fullFilePath) )
        } catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "BaseSaveService : writeImageToFile() : An error occurred writing to file " + filename )
        }
    
        
    }
    
    
 
  
}
