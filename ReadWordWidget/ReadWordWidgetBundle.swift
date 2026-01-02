//
//  ReadWordWidgetBundle.swift
//  ReadWordWidget
//
//  Created by YoSign on 2025/12/31.
//

import WidgetKit
import SwiftUI

@main
struct ReadWordWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReadWordWidget()
        ReadWordWidgetControl()
        ReadWordWidgetLiveActivity()
    }
}
