import Foundation

class RestartableTimer {
    private var timer: Timer?
    private var timeInterval: TimeInterval
    private var target: Any
    private var selector: Selector
    var isValid: Bool { timer?.isValid ?? false }

    init(
        timeInterval: TimeInterval,
        target: Any,
        selector: Selector
    ) {
        self.timeInterval = timeInterval
        self.target = target
        self.selector = selector
    }

    func restart() {
        // Stop the timer if it's already running
        stop()

        // Create and start the timer
        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: target,
            selector: selector,
            userInfo: nil,
            repeats: false
        )
    }

    func stop() {
        // Invalidate the timer to stop it
        timer?.invalidate()
        timer = nil
    }
}
