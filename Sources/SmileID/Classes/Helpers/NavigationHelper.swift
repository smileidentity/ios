import SwiftUI

enum NavigationDestination{
    case selfieInstructionScreen
    case selfieCaptureScreen
    case documentCaptureInstructionScreen
    case documentCaptureScreen
}

class NavigationHelper: ObservableObject{
    @Published var currentPage : NavigationDestination = .selfieInstructionScreen
    private var navStack : [NavigationDestination] = [.selfieCaptureScreen]
    
    func navigate(to destination:NavigationDestination){
        navStack.append(destination)
        currentPage = navStack.last ?? .selfieInstructionScreen
    }
    
    func popView(){
        navStack.removeLast()
        currentPage = navStack.last ?? .selfieInstructionScreen
    }
    
    func navBinding(to destination : NavigationDestination) -> Binding<Bool>{
        return .init {
            return self.currentPage == destination
        } set: {_ in
            self.currentPage = destination
        }
    }
    
}
