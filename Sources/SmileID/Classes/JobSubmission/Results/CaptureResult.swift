//
//  CaptureResult.swift
//  Pods
//
//  Created by Japhet Ndhlovu on 12/5/24.
//

public protocol CommonCaptureData {
    var selfieImage: URL { get }
    var livenessImages: [URL]? { get }
}

// MARK: - Base Capture Results

public struct SelfieCaptureResult: CommonCaptureData {
    public let selfieImage: URL
    public let livenessImages: [URL]?
    
    public init(
        selfieImage: URL,
        livenessImages: [URL]? = nil
    ) {
        self.selfieImage = selfieImage
        self.livenessImages = livenessImages
    }
}

public struct DocumentCaptureResult: CommonCaptureData {
    public let selfieImage: URL
    public let livenessImages: [URL]?
    public let frontImage: URL
    public let backImage: URL?
    
    public init(
        selfieImage: URL,
        livenessImages: [URL]? = nil,
        frontImage: URL,
        backImage: URL? = nil
    ) {
        self.selfieImage = selfieImage
        self.livenessImages = livenessImages
        self.frontImage = frontImage
        self.backImage = backImage
    }
}
