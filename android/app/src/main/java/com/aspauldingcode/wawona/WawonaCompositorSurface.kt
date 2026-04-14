package com.aspauldingcode.wawona

import android.content.Context
import android.view.SurfaceHolder
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView

@Composable
fun WawonaCompositorSurface(
    modifier: Modifier = Modifier
) {
    val nativeStarted = remember { mutableStateOf(false) }
    val surfaceViewState = remember { mutableStateOf<WawonaSurfaceView?>(null) }

    AndroidView(
        modifier = modifier,
        factory = { context ->
            WawonaSurfaceView(context).also { view ->
                surfaceViewState.value = view
            }
        }
    )

    DisposableEffect(surfaceViewState.value) {
        val view = surfaceViewState.value
        if (view == null) {
            onDispose {}
        } else {
            val prefs = view.context.getSharedPreferences("wawona_preferences", Context.MODE_PRIVATE)
            val callback = object : SurfaceHolder.Callback {
                override fun surfaceCreated(holder: SurfaceHolder) {
                    WawonaNative.nativeSetSurface(holder.surface)
                    when {
                        prefs.getBoolean("WestonTerminalEnabled", false) -> WawonaNative.nativeRunWestonTerminal()
                        prefs.getBoolean("FootEnabled", false) -> WawonaNative.nativeRunFoot()
                        prefs.getBoolean("WestonSimpleSHMEnabled", false) -> WawonaNative.nativeRunWestonSimpleSHM()
                        prefs.getBoolean("WestonEnabled", false) -> WawonaNative.nativeRunWeston()
                    }
                    nativeStarted.value = true
                }

                override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                    WawonaNative.nativeResizeSurface(width, height)
                    WawonaNative.nativeSyncOutputSize(width, height)
                }

                override fun surfaceDestroyed(holder: SurfaceHolder) {
                    stopNativeCompositor()
                }
            }

            view.holder.addCallback(callback)
            onDispose {
                view.holder.removeCallback(callback)
                if (nativeStarted.value) {
                    stopNativeCompositor()
                }
                surfaceViewState.value = null
            }
        }
    }
}

private fun stopNativeCompositor() {
    WawonaNative.nativeStopWestonTerminal()
    WawonaNative.nativeStopFoot()
    WawonaNative.nativeStopWestonSimpleSHM()
    WawonaNative.nativeStopWeston()
    WawonaNative.nativeDestroySurface()
}
