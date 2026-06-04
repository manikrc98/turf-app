package com.yourname.turf.ui

import android.content.Context
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.util.Date

class CrashLogger(private val context: Context) : Thread.UncaughtExceptionHandler {
    private val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()

    init {
        Thread.setDefaultUncaughtExceptionHandler(this)
    }

    override fun uncaughtException(thread: Thread, throwable: Throwable) {
        try {
            val logFile = File(context.filesDir, "crash_log.txt")
            val writer = PrintWriter(FileWriter(logFile, true))
            writer.println("=========================================")
            writer.println("CRASH TIME: ${Date()}")
            writer.println("THREAD: ${thread.name}")
            writer.println("EXCEPTION: ${throwable.javaClass.name}: ${throwable.message}")
            writer.println("STACK TRACE:")
            throwable.printStackTrace(writer)
            writer.println("=========================================\n")
            writer.flush()
            writer.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Delegate to system handler
        defaultHandler?.uncaughtException(thread, throwable)
    }
}
