package com.aspauldingcode.wawona

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView

@Composable
fun AndroidSurfaceHost(
    modifier: Modifier = Modifier,
    onViewReady: (WawonaSurfaceView) -> Unit
) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            WawonaSurfaceView(context).also(onViewReady)
        }
    )
}
