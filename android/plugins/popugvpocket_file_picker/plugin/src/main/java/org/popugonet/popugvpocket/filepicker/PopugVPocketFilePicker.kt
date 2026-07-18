package org.popugonet.popugvpocket.filepicker

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import java.util.concurrent.Executors

class PopugVPocketFilePicker(godot: Godot) : GodotPlugin(godot) {
    companion object {
        private const val REQUEST_OPEN_CARTRIDGE = 7314
        private const val REQUEST_OPEN_LEGACY = 7315
        private const val DEFAULT_MAX_SIZE = 64L * 1024L * 1024L
        private const val BUFFER_SIZE = 256 * 1024
        private val FILE_SELECTED = SignalInfo("file_selected", String::class.java)
        private val SELECTION_CANCELLED = SignalInfo("selection_cancelled")
        private val IMPORT_FAILED = SignalInfo("import_failed", String::class.java, String::class.java)
        private val COPY_PROGRESS = SignalInfo(
            "copy_progress",
            java.lang.Long::class.java,
            java.lang.Long::class.java
        )
    }

    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var maxFileSize = DEFAULT_MAX_SIZE

    override fun getPluginName() = "PopugVPocketFilePicker"

    override fun getPluginSignals() = setOf(
        FILE_SELECTED,
        SELECTION_CANCELLED,
        IMPORT_FAILED,
        COPY_PROGRESS
    )

    @UsedByGodot
    fun openCartridgeFile(maxBytes: Long) {
        maxFileSize = maxBytes.coerceIn(1L, DEFAULT_MAX_SIZE)
        runOnHostThread {
            try {
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                        "application/zip",
                        "application/octet-stream",
                        "application/x-popugvpocket-cartridge"
                    ))
                }
                activity?.startActivityForResult(intent, REQUEST_OPEN_CARTRIDGE)
                    ?: emitSignal(IMPORT_FAILED, "PICKER_UNAVAILABLE", "Android activity is unavailable.")
            } catch (error: Exception) {
                Log.e(pluginName, "Unable to open document picker", error)
                emitSignal(IMPORT_FAILED, "PICKER_UNAVAILABLE", error.message ?: "Unable to open picker.")
            }
        }
    }

    @UsedByGodot
    fun openLegacyBackup(maxBytes: Long) {
        maxFileSize = maxBytes.coerceIn(1L, 16L * 1024L * 1024L)
        runOnHostThread {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/zip"
            }
            activity?.startActivityForResult(intent, REQUEST_OPEN_LEGACY)
                ?: emitSignal(IMPORT_FAILED, "PICKER_UNAVAILABLE", "Android activity is unavailable.")
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_OPEN_CARTRIDGE && requestCode != REQUEST_OPEN_LEGACY) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            emitSignal(SELECTION_CANCELLED)
            return
        }
        val uri = data.data ?: return
        executor.execute { importUri(uri, requestCode == REQUEST_OPEN_LEGACY) }
    }

    override fun onGodotTerminating() {
        executor.shutdownNow()
        super.onGodotTerminating()
    }

    private fun importUri(uri: Uri, legacy: Boolean) {
        val originalName = queryDisplayName(uri) ?: "unnamed"
        val expectedSize = querySize(uri)
        if (expectedSize > maxFileSize) {
            emitSignal(IMPORT_FAILED, "ARCHIVE_TOO_LARGE", "Selected file exceeds 64 MB.")
            return
        }
        val downloads = File(context.filesDir, "cartridges/downloads")
        if (!downloads.mkdirs() && !downloads.isDirectory) {
            emitSignal(IMPORT_FAILED, "WRITE_FAILED", "Cannot create cartridge staging directory.")
            return
        }
        val output = File(downloads, if (legacy) "legacy-${UUID.randomUUID()}.zip" else "import-${UUID.randomUUID()}.pctrg")
        try {
            context.contentResolver.openInputStream(uri).use { input ->
                if (input == null) throw IllegalStateException("Content provider returned no stream.")
                FileOutputStream(output).use { target ->
                    val buffer = ByteArray(BUFFER_SIZE)
                    var copied = 0L
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        copied += count
                        if (copied > maxFileSize) {
                            throw FileTooLargeException()
                        }
                        target.write(buffer, 0, count)
                        emitSignal(COPY_PROGRESS, copied, expectedSize)
                    }
                    target.fd.sync()
                }
            }
            Log.i(pluginName, "Imported $originalName to ${output.name}")
            emitSignal(FILE_SELECTED, output.absolutePath)
        } catch (error: FileTooLargeException) {
            output.delete()
            emitSignal(IMPORT_FAILED, "ARCHIVE_TOO_LARGE", "Selected file exceeds 64 MB.")
        } catch (error: SecurityException) {
            output.delete()
            Log.e(pluginName, "Read permission denied for $uri", error)
            emitSignal(IMPORT_FAILED, "READ_PERMISSION_DENIED", "The document provider denied read access.")
        } catch (error: Exception) {
            output.delete()
            Log.e(pluginName, "Failed to import $uri", error)
            emitSignal(IMPORT_FAILED, "COPY_FAILED", error.message ?: "Unable to copy selected file.")
        }
    }

    private fun queryDisplayName(uri: Uri): String? = queryColumn(uri, OpenableColumns.DISPLAY_NAME)

    private fun querySize(uri: Uri): Long {
        return queryColumn(uri, OpenableColumns.SIZE)?.toLongOrNull() ?: -1L
    }

    private fun queryColumn(uri: Uri, column: String): String? {
        var cursor: Cursor? = null
        return try {
            cursor = context.contentResolver.query(uri, arrayOf(column), null, null, null)
            if (cursor != null && cursor.moveToFirst() && !cursor.isNull(0)) cursor.getString(0) else null
        } catch (_: Exception) {
            null
        } finally {
            cursor?.close()
        }
    }

    private class FileTooLargeException : RuntimeException()
}
