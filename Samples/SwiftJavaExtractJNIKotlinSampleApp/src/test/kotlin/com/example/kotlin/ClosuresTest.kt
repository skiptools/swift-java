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

import org.junit.jupiter.api.condition.EnabledOnOs
import org.junit.jupiter.api.condition.OS
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

// Kotlin lambdas passed as Swift escaping closures. Functional-interface names follow
// `<Type>.<method>.<parameter>`; Kotlin converts lambdas to them.
class ClosuresTest {
    @Test
    fun structParameter() {
        val notifier = Notifier.init()
        val seen = mutableListOf<String>()
        notifier.setHandler { item -> seen += item.id }
        notifier.fire("a")
        notifier.fire("b")
        assertEquals(listOf("a", "b"), seen)
    }

    @Test
    fun mixedArityWithOptionalStruct() {
        val calls = mutableListOf<String>()
        val ok = Notifier.init().check { s, i, item -> calls += "$s$i${item.map { it.id }.orElse("-")}"; true }
        assertTrue(ok)
        assertEquals(listOf("a1-", "b2b"), calls)
    }

    @Test
    fun sendableClosureCalledFromAnotherThread() {
        val testThread = Thread.currentThread()
        var calledOn: Thread? = null
        var seenId = ""
        Notifier.init().deliverInBackground("bg") { item ->
            calledOn = Thread.currentThread()
            seenId = item.id
        }
        assertEquals("bg", seenId)
        assertNotEquals(testThread, calledOn)
    }

    @Test
    @EnabledOnOs(OS.MAC) // Screen is main-actor isolated, see MainActorTest
    fun mainActorCallbacks() {
        val events = mutableListOf<String>()
        val callbacks = Callbacks.init({ item -> events += "open ${item.id}" }, { events += "close" })
        Screen.open(callbacks, "7")
        assertEquals(listOf("open 7", "close"), events)
    }
}
