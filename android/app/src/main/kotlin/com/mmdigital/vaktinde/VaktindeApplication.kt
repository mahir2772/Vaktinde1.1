package com.mmdigital.vaktinde

import android.app.Application

/**
 * Manifest'teki Flutter applicationName yer tutucusu android.app.Application'a çözülüyordu; bu
 * sınıf onun yerine geçer. Süreç her başladığında (açılış, ön plan servisi, widget yayını)
 * vakti geçmiş widget/bildirim sayaçları onarılır (WidgetRefresher). Buradaki bir hata uygulamayı
 * açılmaz hale getirir: hiçbir şey dışarı fırlatılmaz.
 */
class VaktindeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // "vaktinde/device" kanalı (Bildirim Kontrolü) cihaz durumunu bu bağlamla okur
        DeviceMethods.appContext = this
        try {
            WidgetRefresher.register(this)
        } catch (t: Throwable) {
            t.printStackTrace()
        }
        // Süreç yokken de vakti geçmiş sayaçlar onarılsın (üretici alarmı iletmediğinde)
        WidgetHealJobService.schedule(this)
    }
}
