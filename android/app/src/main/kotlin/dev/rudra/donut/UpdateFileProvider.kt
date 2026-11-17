package dev.rudra.donut

import androidx.core.content.FileProvider

/**
 * Own subclass so this provider never collides in the manifest merger with a
 * plugin that also declares androidx.core.content.FileProvider.
 */
class UpdateFileProvider : FileProvider()
