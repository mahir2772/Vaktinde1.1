package com.mmdigital.vaktinde

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context

/**
 * Vakti geçmiş widget/kalıcı bildirim sayaçlarının süreç yokken de onarılması. Bazı üreticiler
 * (Honor, Xiaomi…) uygulamayı öldürüp vakit anındaki yenileme alarmını geciktirir ya da hiç
 * iletmez; ekran açılınca dinleyen WidgetRefresher de süreçle birlikte gider. Sistem bu işi
 * ~15 dk'da bir, Doze'da bakım penceresinde ve cihaz uyanınca kısa sürede çalıştırır; iş sadece
 * kayıtlı hedefleri karşılaştırır, gerekirse yeniden çizer (Flutter motoru başlamaz).
 */
class WidgetHealJobService : JobService() {

    override fun onStartJob(params: JobParameters?): Boolean {
        WidgetRefresher.refreshStale(applicationContext)
        return false
    }

    override fun onStopJob(params: JobParameters?): Boolean = false

    companion object {
        // WorkManager'ın kimlikleri 0'dan artar: çakışmayacak kadar uzak sabit kimlik
        const val JOB_ID = 0x56414B54
        const val PERIOD_MS = 15 * 60 * 1000L

        /** Application.onCreate: iş zaten kuruluysa dokunmaz (dönemi sıfırlamaz). Fırlatmaz. */
        fun schedule(context: Context) {
            try {
                val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler ?: return
                if (scheduler.allPendingJobs.any { it.id == JOB_ID }) return
                val job = JobInfo.Builder(JOB_ID, ComponentName(context, WidgetHealJobService::class.java))
                    .setPeriodic(PERIOD_MS)
                    .setPersisted(true)
                    .build()
                scheduler.schedule(job)
            } catch (t: Throwable) {
                t.printStackTrace()
            }
        }
    }
}
