package com.fumiyakume.viewer

/**
 * Small helpers to support app metadata formatting.
 */
internal object AppInfo {
    const val APP_NAME = "Viewer"

    fun appTitle(version: String?): String =
        if (version.isNullOrBlank()) APP_NAME else "$APP_NAME v$version"

    fun isValidRoute(route: String): Boolean = route.isNotBlank()
}
