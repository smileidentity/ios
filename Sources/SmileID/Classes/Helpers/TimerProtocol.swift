import Foundation

protocol TimerProtocol {
    func scheduledTimer(
        withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimerProtocol) -> Void)
    func invalidate()
}

class RealTimer: TimerProtocol {
    private var timer: Timer?
    private let lock = NSLock()

    func scheduledTimer(
        withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (any TimerProtocol) -> Void
    ) {
        defer { lock.unlock() }
        timer = Timer.scheduledTimer(
            withTimeInterval: interval, repeats: repeats,
            block: { [weak self] _ in
                guard let self = self else { return }
                block(self)
            })
    }

    func invalidate() {
        lock.lock()
        defer { lock.unlock() }
        timer?.invalidate()
        timer = nil
    }
}

class MockTimer: TimerProtocol {
    private var isInvalidated: Bool = false
    private var interval: TimeInterval?
    var repeats: Bool?
    private var block: ((TimerProtocol) -> Void)?

    func scheduledTimer(
        withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (any TimerProtocol) -> Void
    ) {
        self.interval = interval
        self.repeats = repeats
        self.block = block
    }

    func invalidate() {
        isInvalidated = true
    }

    func fire() {
        block?(self)
    }
}
