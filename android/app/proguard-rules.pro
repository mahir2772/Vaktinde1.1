# Vaktinde R8 kuralları (release: küçültme + optimizasyon + karartma açık).
# Flutter kendi kurallarını, eklentilerin çoğu kendi tüketici kurallarını ekler; burada
# sadece eksik olanlar var. Manifest'teki sınıflar (aktivite, servis, alıcı, widget) zaten
# adlarıyla korunur.

# --- flutter_local_notifications (tüketici kuralı yok) ---
# Kurulu bildirimler Gson ile SharedPreferences'a yazılır, telefon yeniden başlayınca ve her
# yeni kurulumda okunur. Stil alt türleri sınıfın kısa adıyla, enum'lar alan adıyla kaydedilir:
# ad değişirse önceki sürümün kaydı okunamaz ve yeni bildirim de kurulamaz (ezan çalmaz).
-keep class com.dexterous.** { *; }

# --- Gson (eklentinin bağımlılığı; 2.8.9 kendi R8 kurallarını getirmiyor) ---
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# --- Pakette olmayan, sadece derlemede görülen sınıflar ---
# Flutter motoru ertelenmiş bileşenler için eski Play Core sınıflarına başvurur (kullanılmıyor)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
# Kütüphanelerin derleme zamanı açıklamaları
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
