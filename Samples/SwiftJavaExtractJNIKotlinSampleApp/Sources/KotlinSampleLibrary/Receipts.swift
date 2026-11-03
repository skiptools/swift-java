//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift.org project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift.org project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public enum Receipts {
  /// Defaults the Kotlin caller can leave out, as it would with a Kotlin default.
  public static func format(_ amount: Int64, currency: String = "USD", showsSign: Bool = false) -> String {
    "\(showsSign && amount > 0 ? "+" : "")\(amount) \(currency)"
  }
}
