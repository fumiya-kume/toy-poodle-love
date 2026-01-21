package com.fumiyakume.viewer.ui.videoplayer

import android.content.Context
import androidx.media3.exoplayer.ExoPlayer
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
open class ExoPlayerFactory @Inject constructor(
    @ApplicationContext private val context: Context
) {
    open fun create(): ExoPlayer = ExoPlayer.Builder(context).build()
}

