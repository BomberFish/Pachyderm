//
//  main.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-07-25.
//

import SwiftUI

let is26: Bool!
if #available(iOS 19.0, *) {
    is26 = true
} else {
    is26 = false
}

PachydermApp.main()
