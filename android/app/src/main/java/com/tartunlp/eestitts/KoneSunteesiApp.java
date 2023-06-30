package com.tartunlp.eestitts;

import android.app.Application;
import android.content.Context;
import android.os.Build;

public class KoneSunteesiApp extends Application {

    private static Context storageContext;

    public void onCreate() {
        super.onCreate();
        Context appContext = getApplicationContext();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            KoneSunteesiApp.storageContext = appContext.createDeviceProtectedStorageContext();
        }
        else {
            KoneSunteesiApp.storageContext = appContext;
        }
    }

    public static Context getStorageContext() {
        return KoneSunteesiApp.storageContext;
    }
}
