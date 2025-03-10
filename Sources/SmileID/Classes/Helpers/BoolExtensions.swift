import Foundation

extension Bool {
    var inverted: Self {
        get { !self }
        set { self =  !newValue }
    }
}
