//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Dispatch
import Sockets

class EmbeddedEventLoop : EventLoop {

    let queue = DispatchQueue(label: "embeddedEventLoopQueue", qos: .utility)
    var inEventLoop: Bool = true
    var isRunning: Bool = false

    // Would be better to have this as a Queue
    var tasks: [() -> ()] = Array()

    public func submit<T>(task: @escaping () throws-> (T)) -> Future<T> {
        let promise = Promise<T>(eventLoop: self, checkForPossibleDeadlock: false)
        
        execute(task: {() -> () in
            do {
                promise.succeed(result: try task())
            } catch let err {
                promise.fail(error: err)
            }
        })
        
        return promise.futureResult
    }
    
    public func newPromise<T>(type: T.Type) -> Promise<T> {
        return Promise<T>(eventLoop: self, checkForPossibleDeadlock: false)
    }
    
    // We're not really running a loop here. Tasks aren't run until run() is called,
    // at which point we run everything that's been submitted. Anything newly submitted
    // either gets on that train if it's still moving or
    func execute(task: @escaping () -> ()) {
        queue.sync {
            if isRunning && tasks.isEmpty {
                task()
            } else {
                tasks.append(task)
            }
        }
    }

    func run() throws {
        queue.sync {
            isRunning = true
            while !tasks.isEmpty {
                tasks[0]()
                tasks = Array(tasks.dropFirst(1)) // TODO: Seriously, get a queue
            }
        }
    }

    func close() throws {
        // Nothing to do here
    }


}

class EmbeddedChannelCore : ChannelCore {
    var closed: Bool { return closePromise.futureResult.fulfilled }

    
    var eventLoop: EventLoop = EmbeddedEventLoop()
    var closePromise: Promise<Void>

    init() {
        closePromise = eventLoop.newPromise(type: Void.self)
    }
    
    deinit { closePromise.succeed(result: ()) }

    var outboundBuffer: [Any] = []

    func close0(promise: Promise<Void>, error: Error) {
        closePromise.succeed(result: ())
        promise.succeed(result: ())
    }

    func bind0(local: SocketAddress, promise: Promise<Void>) {
        promise.succeed(result: ())
    }

    func connect0(remote: SocketAddress, promise: Promise<Void>) {
        promise.succeed(result: ())
    }

    func register0(promise: Promise<Void>) {
        promise.succeed(result: ())
    }

    func write0(data: IOData, promise: Promise<Void>) {
        outboundBuffer.append(data.forceAsByteBuffer())
        promise.succeed(result: ())
    }

    func flush0() {
        // No need
    }

    func startReading0() {
    }

    func stopReading0() {
    }

    func readIfNeeded0() {
    }
    
    func channelRead0(data: IOData) {
    }
}

public class EmbeddedChannel : Channel {
    public var closeFuture: Future<Void> { return channelcore.closePromise.futureResult }

    private let channelcore: EmbeddedChannelCore = EmbeddedChannelCore()

    public var _unsafe: ChannelCore {
        return channelcore
    }
    
    public var pipeline: ChannelPipeline {
        return _pipeline
    }

    public var isWritable: Bool {
        return true
    }
    
    private var _pipeline: ChannelPipeline!
    public let allocator: ByteBufferAllocator = ByteBufferAllocator()
    public var eventLoop: EventLoop = EmbeddedEventLoop()

    public var localAddress: SocketAddress? = nil
    public var remoteAddress: SocketAddress? = nil
    var outboundBuffer: [Any] { return (_unsafe as! EmbeddedChannelCore).outboundBuffer }

    init() {
        _pipeline = ChannelPipeline(channel: self)
    }

    public func setOption<T>(option: T, value: T.OptionType) throws where T : ChannelOption {
        // No options supported
    }

    public func getOption<T>(option: T) throws -> T.OptionType where T : ChannelOption {
        fatalError("option \(option) not supported")
    }

    public func read() {
        pipeline.read()
    }
}
