package com.fumiyakume.viewer

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Viewerアプリケーションのエントリーポイント
 *
 * Hilt DIを有効化するためのApplicationクラス
 */
@HiltAndroidApp
class ViewerApplication : Application() {

    internal companion object {
        const val APPLICATION_TAG = "ViewerApplication"
    }
}
