package com.memorybox.android.canvas

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.memorybox.android.R
import java.io.File

class CanvasSnapshotNotifier(
    private val context: Context,
) {
    fun showLatest(snapshot: CanvasSnapshot) {
        val file = snapshot.localPath?.let(::File) ?: return
        if (!file.exists()) return
        ensureChannel()
        val bitmap = BitmapFactory.decodeFile(file.absolutePath) ?: return
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher)
            .setContentTitle("우리 낙서장")
            .setContentText("새 낙서가 도착했어요")
            .setStyle(NotificationCompat.BigPictureStyle().bigPicture(bitmap))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setOngoing(false)
            .build()
        runCatching { NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification) }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(CHANNEL_ID, "우리 낙서장", NotificationManager.IMPORTANCE_LOW).apply {
            description = "페어링된 낙서장 최신 스냅샷"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "live_canvas_snapshot"
        private const val NOTIFICATION_ID = 2808
    }
}
