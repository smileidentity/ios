//
//  SIFileManager.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/4/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import ZIPFoundation

class SIFileManager{
    
    static let SI_FOLDER_NAME : String = "sid.jobs.SI";
    
    func getSmileIDDir() -> URL {
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let sidDir = documentDirURL.appendingPathComponent(SIFileManager.SI_FOLDER_NAME)
        return sidDir
    
    }
   

    func getNoMediaFile() -> String {
        let pathComponent = getSmileIDDir().appendingPathComponent(".nomedia")
        let filePath = pathComponent.path
        
        return filePath
    }
    
    func getRefIdDir(referenceId : String ) -> String {
        return getSmileIDDir().appendingPathComponent(referenceId).path
    }
    
    /* Returns Reference ID subdirectory */
    func createAndGetFolderPath( referenceId : String ) -> String {
        var refIdDir : String?
        do {
            let fileManager = FileManager.default
            
            let noMediaFilePath = getNoMediaFile()
            if !fileManager.fileExists(atPath: noMediaFilePath) {
                fileManager.createFile(atPath: noMediaFilePath, contents: nil, attributes: nil)
            }
            
            refIdDir = getRefIdDir(referenceId: referenceId)
            if !fileManager.fileExists(atPath: refIdDir!) {
                try fileManager.createDirectory(atPath: refIdDir!,
                                    withIntermediateDirectories: true, attributes: nil)
            }
        }
        catch {
            print("SIFileManager : createAndGetFolderPath() : An error occurred : \(error).")
        }

        return refIdDir!
    }
    
    func createJson( referenceId : String ) -> Bool {
        var created : Bool = false
    
        let fileManager = FileManager.default
        
        let refIdDirURL = URL(fileURLWithPath: createAndGetFolderPath( referenceId: referenceId ) )
        let infoPath = refIdDirURL.appendingPathComponent("info.json").path
        created = fileManager.createFile(atPath: infoPath, contents: nil, attributes: nil)
        
        return created
        
    }
    
    func fileExists( fullFilePath : String ) -> Bool {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath:fullFilePath)
        
        let fileExists = fileManager.fileExists(atPath: (url.path) )
        
      
        print( "fileExists = " + String( fileExists ) + ", fullFilePath = ", fullFilePath )
        return fileExists
    }
    
    func getFullFilePath( referenceId : String, filename : String ) -> String {
        let refIDDirURL = URL(fileURLWithPath: createAndGetFolderPath( referenceId : referenceId) )
        let fullFilename = refIDDirURL.appendingPathComponent(filename).path
        return fullFilename
    }
    
    func getMetaFullFilePath( referenceId : String ) -> String {
        let refIDDirURL = URL(fileURLWithPath: createAndGetFolderPath( referenceId : referenceId ) )
        let infoPath = refIDDirURL.appendingPathComponent("info.json").path
        return infoPath
    }
    
    func getMetaFilePathAsURL( referenceId : String ) -> URL{
         return URL( fileURLWithPath: getMetaFullFilePath(
            referenceId: referenceId ) )
    }
    
    func getZipSourceDirURL( referenceId : String ) -> URL {
        return URL(fileURLWithPath: createAndGetFolderPath( referenceId : referenceId ) )
    }
    
    func getZipDestFileURL( referenceId : String ) -> URL {
        let refIDDirURL =
            URL( fileURLWithPath: createAndGetFolderPath( referenceId : referenceId ) )
        return refIDDirURL.appendingPathComponent(referenceId + ".zip")

    }
    
    
    func deleteMetaFolder( referenceId : String ) {
        let fileManager = FileManager.default
        do{
            let refIdPath = createAndGetFolderPath( referenceId : referenceId)
            
            if !fileManager.fileExists(atPath: refIdPath ) {
                return
            }
            
            let refIdDirURL = URL(fileURLWithPath: refIdPath )
            let idCardImagePath = refIdDirURL.appendingPathComponent(SmileIDSingleton.ID_CARD_FRAME_NAME).path
            if fileManager.fileExists(atPath: idCardImagePath ) {
                try fileManager.removeItem(atPath: idCardImagePath)
            }
            
            // list all contents in the directory.  Can be files or subdirectories.
            let contentlist = try fileManager.contentsOfDirectory(atPath: refIdPath)
            let logger = SILog()
            logger.SIPrint(logOutput:"Zip content and  Number of ready frames:" + String(contentlist.count) )
            
            var fullPath : String?
            
            for item in contentlist {
                fullPath = refIdDirURL.appendingPathComponent(item).path
                try fileManager.removeItem(atPath: fullPath!)
            }
        }
        catch {
            print("SIFileManager : deleteSelfieImages() : An error occurred : \(error).")
        }
            
    }
    
    
    
    func deleteSelfieImages( referenceId : String ) {
        let fileManager = FileManager.default
        do{
            let refIdPath = createAndGetFolderPath( referenceId : referenceId )
            
            if !fileManager.fileExists(atPath: refIdPath ) {
                return
            }
            
            let refIDDirURL = URL(fileURLWithPath: refIdPath )
           
            // list all contents in the directory.  Can be files or subdirectories.
            let contentlist = try fileManager.contentsOfDirectory(atPath: refIdPath)
            let logger = SILog()
            logger.SIPrint(logOutput:"Zip content and  Number of ready frames:" + String(contentlist.count) )
            
            var fullPath : String?
            
            for item in contentlist {
                fullPath = refIDDirURL.appendingPathComponent(item).path
                try fileManager.removeItem(atPath: fullPath!)
            }
        }
        catch {
            print("SIFileManager : deleteSelfieImages() : An error occurred : \(error).")
        }
        
    }
    
    
    
    func deleteSIFolder() {
        do {
            let fileManager = FileManager.default
            let smileIDDirPathURL = getSmileIDDir()
            let smileIDDirPath = smileIDDirPathURL.path
            
            if !fileManager.fileExists(atPath: smileIDDirPath ) {
                return
            }
            
            let contentlist = try fileManager.contentsOfDirectory(atPath: smileIDDirPath)
            var fullPath : String?
            
            for item in contentlist {
                fullPath = smileIDDirPathURL.appendingPathComponent(item).path
                try fileManager.removeItem(atPath: fullPath!)
            }
        }
        catch {
            print("SIFileManager : deleteSIFolder() : An error occurred : \(error).")
        }
    }
    
    func deleteZIP( referenceId : String ) {
        do{
            let fileManager = FileManager.default
        
            // get folder name
            let zipPath = getZipDestFileURL( referenceId: referenceId ).path
            if fileManager.fileExists(atPath: zipPath ) {
                try fileManager.removeItem(atPath: zipPath )
            }
        
        }
        catch {
            print("SIFileManager : deleteZIP() : An error occurred : \(error).")
        }
        
    }
    
    
    func deleteIDCardImage( referenceId : String ) {
        do{
            let fileManager = FileManager.default
            let refIdPath = createAndGetFolderPath( referenceId : referenceId)
            
            let refIdDirURL = URL(fileURLWithPath: refIdPath )
            let idCardImagePath = refIdDirURL.appendingPathComponent(SmileIDSingleton.ID_CARD_FRAME_NAME).path
            if fileManager.fileExists(atPath: idCardImagePath ) {
                try fileManager.removeItem(atPath: idCardImagePath)
            }
        }
        catch {
            print("SIFileManager : deleteIDCardImage() : An error occurred : \(error).")
        }
    }
    
    
    
    func deletePreviewFrames( referenceId : String ) {
        
        do{
            let fileManager = FileManager.default
            let refIDPath = createAndGetFolderPath( referenceId : referenceId )
            let refIDDirURL = URL(fileURLWithPath: refIDPath )
            let previewImagePath = refIDDirURL.appendingPathComponent(SmileIDSingleton.PREVIEW_FRAME_NAME).path
            if fileManager.fileExists(atPath: previewImagePath ) {
                try fileManager.removeItem(atPath: previewImagePath)
            }
            var fullPath : String?
            let contentlist = try fileManager.contentsOfDirectory(atPath: refIDPath)
            for itemName in contentlist {
                if itemName.hasPrefix("SID_") && itemName.hasSuffix(".yuv") {
                    fullPath = refIDDirURL.appendingPathComponent(itemName).path
                    try fileManager.removeItem(atPath: fullPath!)
                }
                
            }
    
        }
        catch {
            print("SIFileManager : deletePreviewFrames() : An error occurred : \(error).")
        }
    }
    
    /* appendTagFolderName() has not been ported from Android code, because it is not used */
   

    func zipIt( referenceId : String ) -> URL? {
        var destinationZipFileURL : URL?
        do{
            
            let sourceDirURL = getZipSourceDirURL(referenceId: referenceId)
            destinationZipFileURL = getZipDestFileURL(referenceId: referenceId )
            
            let fileManager = FileManager()
            try fileManager.zipItem(at: sourceDirURL, to: destinationZipFileURL!)

        }
        catch {
            print("SIFileManager : zipIt() : An error occurred : \(error).")
        }
        
        return destinationZipFileURL
    }
    
    
    func getFreeDiskspace() -> Int64? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let freeSize = dictionary[FileAttributeKey.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        }else{
            print("SIFileManager : getFreeDiskspace() : Error Obtaining System Memory Info:")
        }
        return nil
    }
    
    
    
}
