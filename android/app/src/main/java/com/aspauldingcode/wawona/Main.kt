package com.aspauldingcode.wawona

import android.app.Application
import android.app.ActivityOptions
import android.content.Intent
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.SurfaceHolder
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

open class AndroidAppMain : Application() {
    override fun onCreate() {
        super.onCreate()
        ProcessInfo.launch(applicationContext)
    }
}

open class MainActivity : ComponentActivity(), SurfaceHolder.Callback {
    private var surfaceView: WawonaSurfaceView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        WawonaNative.nativeInit(cacheDir.absolutePath)
        WawonaSettings.applyFromPrefs(this)

        setContent {
            WawonaTheme {
                PresentationRoot()
            }
        }
    }

    @Composable
    private fun PresentationRoot() {
        val context = LocalContext.current
        Box(modifier = Modifier.fillMaxSize()) {
            AndroidSurfaceHost(
                onViewReady = { view ->
                    surfaceView = view
                    view.holder.addCallback(this)
                }
            )
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Wawona", style = MaterialTheme.typography.titleLarge)
                Button(
                    onClick = {
                        if (Build.VERSION.SDK_INT >= 36) {
                            launchSessionWindow()
                        }
                    }
                ) {
                    Text("Open Session Window")
                }
            }
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

    private fun launchSessionWindow() {
        val intent = Intent(this, SessionActivity::class.java)
        if (Build.VERSION.SDK_INT >= 36) {
            val options = ActivityOptions.makeBasic()
            options.launchBounds = Rect(80, 80, 980, 1480)
            startActivity(intent, options.toBundle())
        } else {
            startActivity(intent)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        WawonaNative.nativeShutdown()
    }
}
