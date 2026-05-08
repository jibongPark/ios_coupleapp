package com.memorybox.android.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object MemoryBoxColors {
    val BackgroundBeige = Color(0xFFF8F1EA)
    val PrimaryTerracotta = Color(0xFFC1765D)
    val SecondaryOlive = Color(0xFFA3B18A)
    val InputBackground = Color.White
    val TextBlack = Color.Black
    val TextLightGray = Color(0xFFA0A0A0)
}

@Composable
fun MemoryBoxTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = MemoryBoxColors.PrimaryTerracotta,
            secondary = MemoryBoxColors.SecondaryOlive,
            background = MemoryBoxColors.BackgroundBeige,
            surface = MemoryBoxColors.InputBackground,
            onPrimary = Color.White,
            onBackground = MemoryBoxColors.TextBlack,
            onSurface = MemoryBoxColors.TextBlack,
        ),
        content = content,
    )
}
