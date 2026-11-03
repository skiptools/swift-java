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

package com.example.kotlin

import kotlinx.coroutines.future.await
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame
import kotlin.test.assertTrue

class JavaEnumsTest {
    @Test
    fun exhaustiveWhen() {
        val label = when (Orders.fill(OrderStatus.PENDING)) {
            OrderStatus.PENDING -> "pending"
            OrderStatus.FILLED -> "filled"
            OrderStatus.CANCELLED -> "cancelled"
        }
        assertEquals("filled", label)
    }

    @Test
    fun constantsAreTheValuesSwiftReturns() {
        assertSame(OrderStatus.FILLED, Orders.fill(OrderStatus.PENDING))
        assertEquals(OrderStatus.entries, Orders.all().toList())
        assertEquals("cancelled", OrderStatus.CANCELLED.rawValue)
        assertTrue(OrderStatus.CANCELLED.isFinal)
    }

    @Test
    fun everywhereAValueCrosses() = runBlocking {
        assertSame(OrderStatus.PENDING, Orders.status("a"))
        assertSame(OrderStatus.FILLED, Orders.byID()["a"])
        assertSame(OrderStatus.CANCELLED, Order.init("a", OrderStatus.CANCELLED).status)
        assertSame(OrderStatus.FILLED, (Orders.event(OrderStatus.FILLED).case as OrderEvent.Case.Changed).arg0)
        var seen: OrderStatus? = null
        Orders.watch { seen = it }
        assertSame(OrderStatus.CANCELLED, seen)
        assertSame(OrderStatus.FILLED, Orders.settle().await())
    }

    @Test
    fun manyRoundTrips() {
        repeat(10_000) { assertSame(OrderStatus.FILLED, Orders.fill(OrderStatus.FILLED)) }
    }
}
