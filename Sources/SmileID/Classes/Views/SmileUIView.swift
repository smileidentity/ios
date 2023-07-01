//
//  SwiftUIView.swift
//  SmileID
//
//  Created by Japhet Ndhlovu on 2023/07/04.
//

import SwiftUI

enum NavError: Error {
    case noSelfieCaptureDelegate
    case noDocCaptureDelegate
}

public struct SmileUIView: View {
    @State var currentView = NavigationDestination.selfieInstructionScreen
    @ObservedObject var navHelper = NavigationHelper()
    private var currentSelfieDelegate: SmartSelfieResultDelegate?
    private var currentDocCaptureDelegate: DocumentCaptureResultDelegate?
    private var currentUserId = "user-\(UUID().uuidString)"
    private var jobId = "job-\(UUID().uuidString)"
    private var showDocVInstruction = true
    private var showSelfieInstruction = true
    private var isEnroll: Bool = true
    
    init(currentView: NavigationDestination = NavigationDestination.selfieInstructionScreen) {
        self.currentView = currentView
    }
    
    mutating func showSelfieCapture(currentSelfieDelegate:
                                    SmartSelfieResultDelegate,
                                    currentUserId: String,
                                    jobId: String,
                                    showInstruction: Bool,
                                    isEnroll: Bool) {
        self.currentSelfieDelegate = currentSelfieDelegate
        self.currentUserId = currentUserId
        self.jobId = jobId
        showSelfieInstruction = showInstruction
        self.isEnroll = isEnroll
        if showInstruction {
            navHelper.currentPage = NavigationDestination.selfieInstructionScreen
        } else {
            navHelper.currentPage = NavigationDestination.selfieCaptureScreen
        }
    }
    
    mutating func showDocVCapture(currentDocCaptureDelegate: DocumentCaptureResultDelegate,
                                  currentUserId: String,
                                  jobId: String,
                                  showInstruction: Bool) {
        self.currentDocCaptureDelegate = currentDocCaptureDelegate
        self.currentUserId = currentUserId
        self.jobId = jobId
        showDocVInstruction = showInstruction
        if showInstruction {
            navHelper.currentPage = NavigationDestination.documentCaptureInstructionScreen
        } else {
            navHelper.currentPage = NavigationDestination.documentCaptureScreen
        }
    }
    
    public var body: some View {
        NavigationView {
            switch navHelper.currentPage {
            case NavigationDestination.selfieInstructionScreen:
                let viewModel = SelfieCaptureViewModel(userId: self.currentUserId,
                                                       jobId: self.jobId,
                                                       isEnroll: self.isEnroll)
                SmartSelfieInstructionsView(viewModel: viewModel,
                                            delegate: currentSelfieDelegate!)
            case NavigationDestination.selfieCaptureScreen:
                let viewModel = SelfieCaptureViewModel(userId: self.currentUserId,
                                                       jobId: self.jobId,
                                                       isEnroll: self.isEnroll)
                SelfieCaptureView(viewModel: viewModel,
                                  delegate: currentSelfieDelegate!)
            case NavigationDestination.documentCaptureInstructionScreen:
                let viewModel = DocumentCaptureViewModel()
                DocumentCaptureInstructionsView(viewModel: viewModel,
                                                delegate: currentDocCaptureDelegate!)
            case NavigationDestination.documentCaptureScreen:
                let viewModel = DocumentCaptureViewModel()
                DocumentCaptureInstructionsView(viewModel: viewModel,
                                                delegate: currentDocCaptureDelegate!)
            }
        }
    }
}

struct SmileUIView_Previews: PreviewProvider {
    static var previews: some View {
        SmileUIView()
    }
}
