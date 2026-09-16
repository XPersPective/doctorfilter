# Room generates WorkDatabase_Impl and finds it by reflection. R8 cannot see
# that use and removed its constructor, so the release build crashed on start:
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
# WorkManager arrives through the Google Mobile Ads SDK.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
