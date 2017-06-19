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

public protocol ChannelInboundInvoker {
    
    func fireChannelRegistered()

    func fireChannelUnregistered()
    
    func fireChannelActive()

    func fireChannelInactive()

    func fireChannelRead(data: IOData)
    
    func fireChannelReadComplete()
    
    func fireChannelWritabilityChanged()
    
    func fireErrorCaught(error: Error)
    
    func fireUserEventTriggered(event: Any)
}
