import Foundation

protocol DispatchQueueType {
    func async(execute work: @escaping @convention(block) () -> Void)
    func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void)
//    func asyncAfter(
//        deadline: DispatchTime,
//        qos: DispatchQoS = .unspecified,
//        flags: DispatchWorkItemFlags = [],
//        execute work: @escaping @Sendable () -> Void
//    )
}

extension DispatchQueue: DispatchQueueType {
    func async(execute work: @escaping @convention(block) () -> Void) {
        async(group: nil, qos: .unspecified, flags: [], execute: work)
    }

    func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void) {
        self.asyncAfter(deadline: deadline, qos: .unspecified, flags: [], execute: work)
    }
}
