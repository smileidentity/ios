//
//  Mock.swift
//
//  https://github.com/mflint/SwiftMock
//

import XCTest

/// A single expectated call on a mock.
private struct MockExpectation: CustomDebugStringConvertible {
    /// A unique string which describes the call - including function name and
    /// important parameters.
    var callSummary: String
    /// A set of actions to perform if the expected call is made.
    var actions: [([Any?]) -> Void]
    /// A value that should be returned from the mock function call.
    var result: Result<Any, Error>?

    init(callSummary: String,
         actions: [([Any?]) -> Void],
         result: Result<Any, Error>?) {
        self.callSummary = callSummary
        self.actions = actions
        self.result = result
    }

    var debugDescription: String {
        return callSummary
    }
}

/// A class which builds a `MockExpectation`; created when a test calls
/// `mock.expect`.
public final class MockExpectationBuilder<M, R>: MockExpectationHandler {
    /// The name of the mock (not the name of the expecation)
    private let mockName: String

    /// This is the block that contains the expected call:
    /// `mock.expect { $0.myFunc() }`
    private let callBlock: (M) throws -> R

    /// A function that can create a new instance of the mock, with a
    /// different expectation handler.
    ///
    /// The first instance of the mock has a handler for consuming expectations.
    /// When `.expect()` is called, a new mock object is created with a handler
    /// for creating expectations.
    private let mockInit: (String, MockExpectationHandler) -> Mock<M>

    /// A set of actions to perform if the expected call is made.
    private var actions = [([Any?]) -> Void]()

    /// A value that should be returned from the mock function call.
    private var result: Result<Any, Error>?

    /// A unique string which describes the call - including function name and
    /// important parameters.
    private var callSummary: String?

    /// Set if the test tries to set multiple expected calls in one `expect`
    /// block.
    private var multipleExpectations = false

    init(
        mockName: String,
        callBlock: @escaping (M) throws -> R,
        mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>
    ) {
        self.mockName = mockName
        self.callBlock = callBlock
        self.mockInit = mockInit
    }

    /// Adds a return value to the expectation builder.
    /// - Parameter returnValue: value to return.
    public func returning(_ returnValue: R) {
        self.result = .success(returnValue)
    }

    /// Primes this mocked function to throw an error.
    /// - Parameter error: error to throw.
    public func throwing(_ error: Error) {
        self.result = .failure(error)
    }

    /// Adds a closure action which will be performed if the expected call is
    /// made.
    /// - Parameter block: action block
    /// - Returns: `MockExpectationBuilder`
    @discardableResult
    public func doing(_ block: @escaping ([Any?]) -> Void) -> MockExpectationBuilder<M, R> {
        actions.append(block)
        return self
    }

    /// Adds the expected function call to this expectation builder.
    /// - Parameters:
    ///   - callSummary: A unique string which describes the call - including
    ///   function name and important parameters.
    ///   - actionArgs: An array of arguments that should be provided to any
    ///   action block. These arguments will not be matched on, in the
    ///   expectation.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: Optional return value.
    public func accept(
        _ callSummary: String,
        actionArgs: [Any?],
        file: StaticString,
        line: UInt
    ) -> Any? {
        if self.callSummary != nil {
            self.multipleExpectations = true
            XCTFail(
                "[\(self.mockName)]: Too many expectations in `.expect { }`",
                file: file,
                line: line
            )
        }

        self.callSummary = callSummary

        switch self.result {
        case nil:
            return nil
        case .success(let returnValue):
            return returnValue
        case .failure:
            XCTFail(
                "[\(self.mockName)]: Non-throwing function cannot throw errors",
                file: file,
                line: line
            )
            return nil
        }
    }

    /// Adds the expected throwing function call to this expectation builder.
    /// - Parameters:
    ///   - callSummary: A unique string which describes the call - including
    ///   function name and important parameters.
    ///   - actionArgs: An array of arguments that should be provided to any
    ///   action block. These arguments will not be matched on, in the
    ///   expectation.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: Optional return value.
    public func throwingAccept(
        _ callSummary: String,
        actionArgs: [Any?],
        file: StaticString,
        line: UInt
    ) throws -> Any? {
        if self.callSummary != nil {
            self.multipleExpectations = true
            XCTFail(
                "[\(self.mockName)]: Too many expectations in `.expect { }`",
                file: file,
                line: line
            )
        }

        self.callSummary = callSummary

        switch self.result {
        case nil:
            return nil
        case .success(let returnValue):
            return returnValue
        case .failure(let error):
            throw error
        }
    }

    /// This function assembles the final expecatation.
    /// When the return value and actions have been set, this `build()` function
    /// will eventually be called which calls the captured `callBlock`.
    /// This is when we find out the expected function name and important
    /// arguments that should be matched.
    /// - Returns: A function-call expectation.
    fileprivate func build() -> MockExpectation? {
        // make an instance of the `M` mock which contains this
        // expectation builder
        let completionMock = self.mockInit(self.mockName, self) as! M
        _ = try? self.callBlock(completionMock)

        // check that an expectation was set by the callBlock
        guard let callSummary = self.callSummary else {
            return nil
        }

        if self.multipleExpectations {
            // tried to set multiple expectations in one `.expect { }` block, which
            // is not permitted - so don't expect anything
            return nil
        }

        return MockExpectation(callSummary: callSummary,
                               actions: self.actions,
                               result: self.result)
    }
}

/// A protocol for the two types that can accept a mocked function call.
/// * `MockExpectationBuilder` builds expectations that the text expects
/// * `MockExpectationConsumer` consumes those expecations when the
/// system-under-test is being exercised
public protocol MockExpectationHandler {
    func accept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> Any?
    func throwingAccept(
        _ callSummary: String,
        actionArgs: [Any?],
        file: StaticString,
        line: UInt
    ) throws -> Any?
}

/// Maintains a list of expectations on a mock object.
private class MockExpectationCreator {
    /// a collection of built expecations
    var expectations = [MockExpectation]()
    /// a collection of functions that can build expectations
    private var expectationBuilderFunctions = [() -> MockExpectation?]()
    /// the name of the mock object
    private let mockName: String

    init(mockName: String) {
        self.mockName = mockName
    }

    /// Creates a new expectation builder, which the test can use to configure
    /// an expected function call, its return value and any actions to perform.
    /// - Parameters:
    ///   - callBlock: the closure which defines the expected function call
    ///   - mockInit:
    /// - Returns: expectation builder
    func builder<M, R>(
        callBlock: @escaping (M) throws -> R,
        mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>
    ) -> MockExpectationBuilder<M, R> {
        // create the builder
        let builder = MockExpectationBuilder(
            mockName: self.mockName,
            callBlock: callBlock,
            mockInit: mockInit
        )
        // capture the builder's `build()` function for later
        self.expectationBuilderFunctions.append(builder.build)
        return builder
    }

    /// This turns the _expectation builder_ functions into actual expectations.
    /// We call this lazily when the system-under-test starts consuming
    /// expectations.
    func buildExpectations() {
        self.expectations.append(contentsOf: self.expectationBuilderFunctions.compactMap { $0() })
        self.expectationBuilderFunctions.removeAll()
    }

    /// Used by the expectation consumer to claim an expectation.
    /// - Parameter callSummary: Identifies the expecation being claimed.
    /// - Returns: An expectation, or `nil` if the call was unexpected.
    func claimExpectation(_ callSummary: String) -> MockExpectation? {
        // build any unbuild expectations
        self.buildExpectations()

        guard let index = expectations.firstIndex(where: { (expectation) -> Bool in
            expectation.callSummary == callSummary
        }) else {
            return nil
        }

        return expectations.remove(at: index)
    }
}

/// This is a call handler which consumes expectation. When the
/// system-under-test calls functions on the mock, this
/// `MockExpectationConsumer` checks that the call was expected, and
/// performs any actions associated with the expectation.
private class MockExpectationConsumer: MockExpectationHandler {
    private let mockName: String
    fileprivate let expectationCreator: MockExpectationCreator

    fileprivate init(mockName: String, expectationCreator: MockExpectationCreator) {
        self.mockName = mockName
        self.expectationCreator = expectationCreator
    }

    private func claim(
        _ callSummary: String,
        actionArgs: [Any?],
        file: StaticString,
        line: UInt
    ) -> MockExpectation? {
        // try to find (and remove) this call from the collection of expectations
        guard let foundExpectation = expectationCreator.claimExpectation(callSummary) else {
            XCTFail("[\(self.mockName)] Unexpected call: \(callSummary)", file: file, line: line)
            return nil
        }

        // perform actions for this expecatation
        for action in foundExpectation.actions {
            action(actionArgs)
        }

        return foundExpectation
    }

    func accept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> Any? {
        // try to find the expectation, and peform actios
        guard let foundExpectation = self.claim(
            callSummary,
            actionArgs: actionArgs,
            file: file,
            line: line
        ) else {
            return nil
        }

        // and return the return value to the caller
        switch foundExpectation.result {
        case nil:
            return nil
        case .success(let returnValue):
            return returnValue
        case .failure:
            XCTFail(
                "[\(self.mockName)]: Non-throwing function cannot throw errors",
                file: file,
                line: line
            )
            return nil
        }
    }

    func throwingAccept(
        _ callSummary: String,
        actionArgs: [Any?],
        file: StaticString,
        line: UInt
    ) throws -> Any? {
        // try to find the expectation, and peform actios
        guard let foundExpectation = self.claim(
            callSummary,
            actionArgs: actionArgs,
            file: file,
            line: line
        ) else {
            return nil
        }

        // and return the return value to the caller
        switch foundExpectation.result {
        case nil:
            return nil
        case .success(let returnValue):
            return returnValue
        case .failure(let error):
            throw error
        }
    }
}

/// The base class for a Mock object.
open class Mock<M> {
    private let name: String
    private let expectationHandler: MockExpectationHandler

    /// Creates a mock object with the given name. If `name` is not provided,
    /// then a name of the mocked protocol (`M`) will be used.
    /// - Parameter name: Mock name.
    /// - Returns: A mock object for the `M` protocol.
    public static func create(mockName name: String? = nil) -> Self {
        let mockName = name ?? String(describing: M.self)
        let expectationCreator = MockExpectationCreator(mockName: mockName)
            let expectationConsumer = MockExpectationConsumer(
                mockName: mockName,
                expectationCreator: expectationCreator
            )

        let consumerMock = self.init(name: mockName, expectationHandler: expectationConsumer)

        return consumerMock
    }

    public required init(name: String, expectationHandler: MockExpectationHandler) {
        self.name = name
        self.expectationHandler = expectationHandler
    }

    /// Creates an expectation for a function call.
    /// - Parameter callBlock: A block containing the expected function call.
    /// - Returns: A builder object that can associate return value and actions
    /// with the expectation.
    @discardableResult
    public func expect<R>(_ callBlock: @escaping (M) throws -> R) -> MockExpectationBuilder<M, R> {
        guard let expectationCreator = (
            expectationHandler as? MockExpectationConsumer
        )?.expectationCreator else {
            preconditionFailure("internal error")
        }

        return expectationCreator.builder(callBlock: callBlock, mockInit: type(of: self).init)
    }

    /// Verifies that the expectated function calls have all been satisfied.
    /// - Parameters:
    ///   - file: Calling file.
    ///   - line: Calling line.
    public func verify(file: StaticString = #file, line: UInt = #line) {
        guard let expectationConsumer = expectationHandler as? MockExpectationConsumer else {
            preconditionFailure("internal error")
        }

        let expectationCreator = expectationConsumer.expectationCreator

        // build any unbuilt expectations
        expectationCreator.buildExpectations()

        if expectationCreator.expectations.count > 0 {
            for expectation in expectationCreator.expectations {
                let expectationDescription = String(describing: expectation)
                XCTFail(
                    "[\(self.name)] Unsatisfied expectation: \(expectationDescription)",
                    file: file,
                    line: line
                )
            }
        }

        // remove all expectations, so they don't fail again
        // later in the test
        expectationCreator.expectations.removeAll()
    }

    /// A concrete mock object should call one of the `accept()` functions
    /// whenever a call to a mocked function is made.
    /// - Parameters:
    ///   - func: The name of the mocked function.
    ///   - args: A collection of arguments that should be matched.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: The optional return value for the mocked function.
    @discardableResult
    public func accept(
        func: String = #function,
        args: [Any?] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) -> Any? {
        return accept(func: `func`, checkArgs: args, actionArgs: args, file: file, line: line)
    }

    @discardableResult
    /// A concrete mock object should call one of the `accept()` functions
    /// whenever a call to a mocked function is made.
    /// - Parameters:
    ///   - func: The name of the mocked function.
    ///   - checkArgs: A collection of arguments that should be matched.
    ///   - actionArgs: A collection of arguments that should not be matched,
    ///   but may be given to any action closures associated with this call.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: The optional return value for the mocked function.
    public func accept(
        func: String = #function,
        checkArgs: [Any?],
        actionArgs: [Any?],
        file: StaticString = #file,
        line: UInt = #line
    ) -> Any? {
        var callSummary = "\(`func`)"
        if checkArgs.count > 0 {
            callSummary += " " + summary(for: checkArgs)
        }

        return expectationHandler.accept(
            callSummary,
            actionArgs: actionArgs,
            file: file,
            line: line
        )
    }

    /// A concrete mock object should call one of the `throwingAccept()`
    /// functions whenever a call to a mocked throwing function is made.
    /// - Parameters:
    ///   - func: The name of the mocked function.
    ///   - args: A collection of arguments that should be matched.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: The optional return value for the mocked function.
    @discardableResult
    public func throwingAccept(
        func: String = #function,
        args: [Any?] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Any? {
        return try throwingAccept(
            func: `func`,
            checkArgs: args,
            actionArgs: args,
            file: file,
            line: line
        )
    }

    @discardableResult
    /// A concrete mock object should call one of the `throwingAccept()`
    /// functions whenever a call to a mocked throwing function is made.
    /// - Parameters:
    ///   - func: The name of the mocked function.
    ///   - checkArgs: A collection of arguments that should be matched.
    ///   - actionArgs: A collection of arguments that should not be matched,
    ///   but may be given to any action closures associated with this call.
    ///   - file: Calling file.
    ///   - line: Calling line.
    /// - Returns: The optional return value for the mocked function.
    /// - Throws: May throw errors when the expecations are being consumed. Will not throw when expectations are being set.
    public func throwingAccept(
        func: String = #function,
        checkArgs: [Any?],
        actionArgs: [Any?],
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Any? {
        var callSummary = "\(`func`)"
        if checkArgs.count > 0 {
            callSummary += " " + summary(for: checkArgs)
        }

        return try expectationHandler.throwingAccept(
            callSummary,
            actionArgs: actionArgs,
            file: file,
            line: line
        )
    }

    private func summary(for argument: Any) -> String {
        switch argument {
        case let array as [Any]:
            var result = "["
            for (index, item) in array.enumerated() {
                result += summary(for: item)
                if index < array.count-1 {
                    result += ","
                }
            }
            result += "]"
            return result
        case let dict as [String: Any]:
            var result = "["
            for (index, key) in dict.keys.sorted().enumerated() {
                if let value = dict[key] {
                    result += "\(summary(for: key)):\(summary(for:value))"
                }
                if index < dict.count-1 {
                    result += ","
                }
            }
            result += "]"
            return result
        case  Optional<Any>.none:
            // for nil values (Optional.none), return "nil"
            return "nil"
        case Optional<Any>.some(let value):
            // for non-nil values (Optional.some), return the unwrapped value
            return String(describing: value)
        default:
            preconditionFailure("don't expect this to happen, because we're already handling Optional.none and Optional.some")
        }
    }
}
