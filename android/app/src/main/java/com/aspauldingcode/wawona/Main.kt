package com.aspauldingcode.wawona

import android.app.Application
import android.graphics.Color as AndroidColor
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.SystemBarStyle
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import skip.foundation.ProcessInfo
import skip.ui.ColorScheme
import skip.ui.ComposeContext
import skip.ui.PresentationRoot
import skip.ui.UIApplication
import wawona.ui.WawonaAppDelegate
import wawona.ui.WawonaRootView

/**
 * Android entry points aligned with Skip Fuse dual-platform template
 * (see `skipapp-bookings-fuse/Android/app/src/main/kotlin/Main.kt`):
 * [PresentationRoot] + [ColorScheme] so SwiftUI maps to Compose with the same presentation stack as iOS.
 */
private const val LOG_TAG = "Wawona"

open class AndroidAppMain : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.i(LOG_TAG, "starting app")
        ProcessInfo.launch(applicationContext)
        WawonaAppDelegate.Companion.shared.onInit()
    }
}

open class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(LOG_TAG, "starting activity")
        WawonaNative.nativeInit(cacheDir.absolutePath)
        WawonaSettings.apply(getSharedPreferences("wawona_preferences", MODE_PRIVATE))
        UIApplication.Companion.launch(this)
        enableEdgeToEdge()
        setContent {
            val saveableStateHolder = rememberSaveableStateHolder()
            saveableStateHolder.SaveableStateProvider(true) {
                PresentationRootView(ComposeContext())
                SideEffect { saveableStateHolder.removeState(true) }
            }
        }
        WawonaAppDelegate.Companion.shared.onLaunch()
    }

    override fun onStart() {
        Log.i(LOG_TAG, "onStart")
        super.onStart()
    }

    override fun onResume() {
        super.onResume()
        WawonaAppDelegate.Companion.shared.onResume()
    }

    override fun onPause() {
        super.onPause()
        WawonaAppDelegate.Companion.shared.onPause()
    }

    override fun onStop() {
        super.onStop()
        WawonaAppDelegate.Companion.shared.onStop()
    }

    override fun onDestroy() {
        super.onDestroy()
        WawonaAppDelegate.Companion.shared.onDestroy()
        WawonaNative.nativeShutdown()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        WawonaAppDelegate.Companion.shared.onLowMemory()
    }

    override fun onRestart() {
        Log.i(LOG_TAG, "onRestart")
        super.onRestart()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
    }

    override fun onRestoreInstanceState(bundle: Bundle) {
        Log.i(LOG_TAG, "onRestoreInstanceState")
        super.onRestoreInstanceState(bundle)
    }
}

@Composable
private fun SyncSystemBarsWithTheme() {
    val dark = MaterialTheme.colorScheme.background.luminance() < 0.5f
    val transparent = AndroidColor.TRANSPARENT
    val style =
        if (dark) {
            SystemBarStyle.dark(transparent)
        } else {
            SystemBarStyle.light(transparent, transparent)
        }
    val activity = LocalContext.current as? ComponentActivity
    DisposableEffect(style) {
        activity?.enableEdgeToEdge(
            statusBarStyle = style,
            navigationBarStyle = style,
        )
        onDispose { }
    }
}

@Composable
private fun PresentationRootView(context: ComposeContext) {
    val colorScheme = if (isSystemInDarkTheme()) ColorScheme.dark else ColorScheme.light
    PresentationRoot(defaultColorScheme = colorScheme, context = context) { ctx ->
        SyncSystemBarsWithTheme()
        val contentContext = ctx.content()
        Box(modifier = ctx.modifier.fillMaxSize()) {
            WawonaRootView().Compose(context = contentContext)
        }
    }
}
