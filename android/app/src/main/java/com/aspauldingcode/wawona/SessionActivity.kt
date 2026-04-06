package com.aspauldingcode.wawona

import android.os.Bundle
import android.view.SurfaceHolder
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier

class SessionActivity : ComponentActivity(), SurfaceHolder.Callback {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AndroidSurfaceHost(
                modifier = Modifier.fillMaxSize(),
                onViewReady = { view -> view.holder.addCallback(this) }
            )
        }
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        WawonaNative.nativeSetSurface(holder.surface)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        WawonaNative.nativeResizeSurface(width, height)
        WawonaNative.nativeSyncOutputSize(width, height)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        WawonaNative.nativeDestroySurface()
    }
}
