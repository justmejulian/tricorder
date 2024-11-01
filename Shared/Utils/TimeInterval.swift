//
//  vt1
//
//  Created by Julian Visser on 14.01.2024.
//

import Foundation

extension TimeInterval {
    static let bootTime =
        Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime

    var timeIntervalSince1970: TimeInterval {
        return (TimeInterval.bootTime + self)
    }
}
