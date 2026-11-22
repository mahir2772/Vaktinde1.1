package com.mmdigital.vaktinde

import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetProvider

/** Vaktinde widget'larının ortak tabanı: kendi yenileme alarmı geldiğinde gecikmeyi ölçer */
abstract class VaktindeWidgetProvider : HomeWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerWidgetData.noteRefreshDelay(context, intent)
        super.onReceive(context, intent)
    }
}
