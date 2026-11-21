#!/bin/bash
# Add-Fingerprint-Gesture-Support.sh  (services.jar patch, runs inside the decompiled services.jar directory)
#
# Restores the stock "swipe on the fingerprint sensor to open/close the notification shade" feature:
#   1. adds the stock gesture classes (SemFpGestureManager and helpers), with the dependencies the base lacks replaced
#   2. adds SemBiometricFeature.FP_FEATURE_GESTURE_MODE and makes FingerprintService.semHasFeature(1) return it
#      (this is what makes Settings > Advanced features > Motions and gestures > Finger sensor gestures appear)
#   3. hooks the manager into FingerprintService startup (boot phase 0x258)
# Every entry point is wrapped in try/catch(Throwable), so a runtime failure logs a warning under the tag
# FingerprintService.Gesture instead of crashing system_server.

_GD=$(dirname "$(find . -name 'SemFpGestureManager$Injector.smali' -print -quit)")
if [[ -z "$_GD" || "$_GD" == "." ]]; then
    echo "gesture: SemFpGestureManager\$Injector.smali not found" >&2
    return 1
fi

cat > "$_GD/SemFpGestureManager.smali" <<'EOF_GESTURE_SMALI'
.class public final Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;
.super Ljava/lang/Object;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"

# interfaces
.implements Lcom/android/server/biometrics/sensors/fingerprint/SemFpHalLifecycleListener;
.implements Lcom/android/server/biometrics/sensors/fingerprint/SemFpEventListener;


# static fields
.field static final ACTION_FINGERPRINT_GESTURE_SAMSUNG_PAY:Ljava/lang/String; = "com.samsung.android.spay.gesture.fingerprint"

.field static final ACTION_SCREEN_OFF_BY_PROXIMITY:Ljava/lang/String; = "android.intent.action.ACTION_SCREEN_OFF_BY_PROXIMITY"

.field static final ACTION_SCREEN_ON_BY_PROXIMITY:Ljava/lang/String; = "android.intent.action.ACTION_SCREEN_ON_BY_PROXIMITY"

.field static final DB_SPAY_GESTURE_MENU_VISIBLE:Ljava/lang/String; = "fingerprint_gesture_spay_visible"

.field static final PERMISSION_SAMSUNG_PAY_SIMPLE_PAY:Ljava/lang/String; = "com.samsung.android.spay.permission.SIMPLE_PAY"


# instance fields
.field mBroadCastReceiver:Landroid/content/BroadcastReceiver;

.field mContentObserver:Landroid/database/ContentObserver;

.field public final mContext:Landroid/content/Context;

.field public final mH:Landroid/os/Handler;

.field public final mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

.field public mIsEnabledGestureForSamsungPay:Z

.field public mIsEnabledGestureForStatusBar:Z

.field public mIsEnabledGestureMainSetting:Z

.field public final mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

.field mUserSwitchObserver:Landroid/app/SynchronousUserSwitchObserver;

.field public static sInstance:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;


# direct methods
.method public constructor <init>(Landroid/content/Context;Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iput-object p2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

    iput-object p3, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    sget-object p1, Lcom/android/server/biometrics/BiometricHandlerProvider;->sBiometricHandlerProvider:Lcom/android/server/biometrics/BiometricHandlerProvider;

    invoke-virtual {p1}, Lcom/android/server/biometrics/BiometricHandlerProvider;->getFingerprintHandler()Landroid/os/Handler;

    move-result-object p1

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    return-void
.end method


# virtual methods
.method public final handleSwipeDownEvent()V
    .locals 3

    iget-boolean v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForStatusBar:Z

    if-nez v0, :cond_5

    return-void

    :cond_5
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-class p0, Landroid/app/SemStatusBarManager;

    invoke-virtual {v0, p0}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/app/SemStatusBarManager;

    invoke-virtual {p0}, Landroid/app/SemStatusBarManager;->isPanelExpanded()Z

    move-result v0

    const-string v1, "FPGT"

    const/4 v2, 0x3

    if-eqz v0, :cond_2a

    invoke-virtual {p0}, Landroid/app/SemStatusBarManager;->expandQuickSettingsPanel()V

    invoke-static {}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->get()Lcom/android/server/biometrics/SemBioAnalyticsManager;

    move-result-object p0

    const-string v0, "ExpandQuickSettingsPanel"

    invoke-virtual {p0, v2, v1, v0}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->fpInsertLog(ILjava/lang/String;Ljava/lang/String;)V

    goto :goto_36

    :cond_2a
    invoke-virtual {p0}, Landroid/app/SemStatusBarManager;->expandNotificationsPanel()V

    invoke-static {}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->get()Lcom/android/server/biometrics/SemBioAnalyticsManager;

    move-result-object p0

    const-string v0, "ExpandNotificationPanel"

    invoke-virtual {p0, v2, v1, v0}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->fpInsertLog(ILjava/lang/String;Ljava/lang/String;)V

    :goto_36
    return-void
.end method

.method public final handleSwipeUpEvent()V
    .locals 5

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-class v1, Landroid/app/SemStatusBarManager;

    invoke-virtual {v0, v1}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/app/SemStatusBarManager;

    iget-boolean v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForStatusBar:Z

    const-string v2, "FPGT"

    const/4 v3, 0x3

    if-eqz v1, :cond_35

    invoke-virtual {v0}, Landroid/app/SemStatusBarManager;->isPanelExpanded()Z

    move-result v1

    if-eqz v1, :cond_35

    const/16 p0, 0x0

    if-eqz p0, :cond_28

    const-string p0, "FingerprintService.Gesture"

    const-string/jumbo v1, "handleGestureAction: QuickPanel Expanded"

    invoke-static {p0, v1}, Landroid/util/Slog;->v(Ljava/lang/String;Ljava/lang/String;)I

    :cond_28
    invoke-virtual {v0}, Landroid/app/SemStatusBarManager;->collapsePanels()V

    invoke-static {}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->get()Lcom/android/server/biometrics/SemBioAnalyticsManager;

    move-result-object p0

    const-string v0, "CollapseNotificationPanel"

    invoke-virtual {p0, v3, v2, v0}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->fpInsertLog(ILjava/lang/String;Ljava/lang/String;)V

    goto :goto_5c

    :cond_35
    iget-boolean v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForSamsungPay:Z

    if-eqz v0, :cond_5c

    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0}, Landroid/content/Intent;-><init>()V

    const-string/jumbo v1, "com.samsung.android.spay.gesture.fingerprint"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->setAction(Ljava/lang/String;)Landroid/content/Intent;

    const/16 v1, 0x20

    invoke-virtual {v0, v1}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    sget-object v1, Landroid/os/UserHandle;->CURRENT:Landroid/os/UserHandle;

    const-string/jumbo v4, "com.samsung.android.spay.permission.SIMPLE_PAY"

    invoke-virtual {p0, v0, v1, v4}, Landroid/content/Context;->sendBroadcastAsUser(Landroid/content/Intent;Landroid/os/UserHandle;Ljava/lang/String;)V

    invoke-static {}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->get()Lcom/android/server/biometrics/SemBioAnalyticsManager;

    move-result-object p0

    const-string v0, "SimpleSamsungPay"

    invoke-virtual {p0, v3, v2, v0}, Lcom/android/server/biometrics/SemBioAnalyticsManager;->fpInsertLog(ILjava/lang/String;Ljava/lang/String;)V

    :cond_5c
    :goto_5c
    return-void
.end method

.method public final onGestureEventInner(I)V
    .locals 7

    iget-boolean v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-nez v0, :cond_5

    goto :goto_5b

    :cond_5
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-class v1, Landroid/os/PowerManager;

    invoke-virtual {v0, v1}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/os/PowerManager;

    invoke-virtual {v0}, Landroid/os/PowerManager;->isInteractive()Z

    move-result v0

    const-string v1, "FingerprintService.Gesture"

    if-nez v0, :cond_23

    const-string/jumbo p0, "handleGestureAction: SKIP gesture action because of interactive status"

    invoke-static {v1, p0}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_5b

    :cond_23
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    const/16 v2, 0x0

    const/16 v2, 0x0

    if-eqz v2, :cond_49

    const-class v2, Lcom/samsung/android/desktopmode/SemDesktopModeManager;

    invoke-virtual {v0, v2}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Lcom/samsung/android/desktopmode/SemDesktopModeManager;

    if-eqz v0, :cond_49

    invoke-virtual {v0}, Lcom/samsung/android/desktopmode/SemDesktopModeManager;->getDesktopModeState()Lcom/samsung/android/desktopmode/SemDesktopModeState;

    move-result-object v0

    if-eqz v0, :cond_49

    invoke-virtual {v0}, Lcom/samsung/android/desktopmode/SemDesktopModeState;->getEnabled()I

    move-result v0

    const/4 v2, 0x4

    if-ne v0, v2, :cond_49

    const-string/jumbo p0, "handleGestureAction: SKIP gesture action because of DeX Mode"

    invoke-static {v1, p0}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_5b

    :cond_49
    const/16 v0, 0x4e22

    if-ne p1, v0, :cond_5c

    iget-object v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    const/16 v2, 0x0

    if-eqz v2, :cond_5c

    const-string/jumbo p0, "handleGestureAction: SKIP gesture action because of flip folded status"

    invoke-static {v1, p0}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    :goto_5b
    return-void

    :cond_5c
    :try_start_5c
    iget-object v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    const-class v3, Landroid/os/PowerManager;

    invoke-virtual {v2, v3}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/os/PowerManager;

    invoke-static {}, Landroid/os/SystemClock;->uptimeMillis()J

    move-result-wide v3

    const/4 v5, 0x2

    const/4 v6, 0x0

    invoke-virtual {v2, v3, v4, v5, v6}, Landroid/os/PowerManager;->userActivity(JII)V

    const/16 v2, 0x4e21

    if-eq p1, v2, :cond_7c

    if-eq p1, v0, :cond_76

    goto :goto_96

    :cond_76
    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->handleSwipeDownEvent()V

    goto :goto_96

    :catch_7a
    move-exception p0

    goto :goto_80

    :cond_7c
    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->handleSwipeUpEvent()V
    :try_end_7f
    .catch Ljava/lang/RuntimeException; {:try_start_5c .. :try_end_7f} :catch_7a

    goto :goto_96

    :goto_80
    new-instance p1, Ljava/lang/StringBuilder;

    const-string/jumbo v0, "onGestureEvent: "

    invoke-direct {p1, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {p0}, Ljava/lang/RuntimeException;->getMessage()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-static {v1, p0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    :goto_96
    return-void
.end method

.method public final onHalStarted(Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;)V
    .locals 0

    iget-boolean p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-eqz p1, :cond_7

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOnGestureMode()V

    :cond_7
    return-void
.end method

.method public final turnOffGestureModeInner()V
    .locals 8

    sget-boolean v0, Lcom/android/server/biometrics/SemBiometricFeature;->FEATURE_FINGERPRINT_JDM_HAL:Z

    if-eqz v0, :cond_5

    return-void

    :cond_5
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

    move-object v1, v0

    check-cast v1, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;

    invoke-virtual {v1}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->getSensorProperties()Ljava/util/List;

    move-result-object v1

    const/4 v2, 0x0

    check-cast v1, Ljava/util/ArrayList;

    invoke-virtual {v1, v2}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    iget v3, v1, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;->sensorId:I

    const/4 v7, 0x0

    move-object v2, v0

    check-cast v2, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;

    const/16 v4, 0x10

    const/4 v5, 0x0

    const/4 v6, 0x0

    invoke-virtual/range {v2 .. v7}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->semRequest(III[B[B)I

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mBroadCastReceiver:Landroid/content/BroadcastReceiver;

    if-nez v0, :cond_29

    goto :goto_31

    :cond_29
    iget-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    invoke-virtual {v1, v0}, Landroid/content/Context;->unregisterReceiver(Landroid/content/BroadcastReceiver;)V

    const/4 v0, 0x0

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mBroadCastReceiver:Landroid/content/BroadcastReceiver;

    :goto_31
    return-void
.end method

.method public final turnOnGestureModeInner()V
    .locals 8

    sget-boolean v0, Lcom/android/server/biometrics/SemBiometricFeature;->FEATURE_FINGERPRINT_JDM_HAL:Z

    if-eqz v0, :cond_5

    return-void

    :cond_5
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

    move-object v1, v0

    check-cast v1, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;

    invoke-virtual {v1}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->getSensorProperties()Ljava/util/List;

    move-result-object v0

    const/4 v2, 0x0

    check-cast v0, Ljava/util/ArrayList;

    invoke-virtual {v0, v2}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    iget v2, v0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;->sensorId:I

    const/4 v4, 0x0

    const/4 v5, 0x0

    const/16 v3, 0xf

    const/4 v6, 0x0

    invoke-virtual/range {v1 .. v6}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->semRequest(III[B[B)I

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mBroadCastReceiver:Landroid/content/BroadcastReceiver;

    if-eqz v0, :cond_26

    goto :goto_53

    :cond_26
    new-instance v0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;

    invoke-direct {v0, p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mBroadCastReceiver:Landroid/content/BroadcastReceiver;

    new-instance v3, Landroid/content/IntentFilter;

    invoke-direct {v3}, Landroid/content/IntentFilter;-><init>()V

    const-string v0, "android.intent.action.SCREEN_ON"

    invoke-virtual {v3, v0}, Landroid/content/IntentFilter;->addAction(Ljava/lang/String;)V

    const-string v0, "android.intent.action.SCREEN_OFF"

    invoke-virtual {v3, v0}, Landroid/content/IntentFilter;->addAction(Ljava/lang/String;)V

    const-string v0, "android.intent.action.ACTION_SCREEN_ON_BY_PROXIMITY"

    invoke-virtual {v3, v0}, Landroid/content/IntentFilter;->addAction(Ljava/lang/String;)V

    const-string v0, "android.intent.action.ACTION_SCREEN_OFF_BY_PROXIMITY"

    invoke-virtual {v3, v0}, Landroid/content/IntentFilter;->addAction(Ljava/lang/String;)V

    iget-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mBroadCastReceiver:Landroid/content/BroadcastReceiver;

    sget-object v4, Landroid/os/UserHandle;->ALL:Landroid/os/UserHandle;

    const/4 v5, 0x0

    const/4 v7, 0x0

    iget-object v6, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    invoke-static/range {v1 .. v6}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->regAsUser(Landroid/content/Context;Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Landroid/os/UserHandle;Ljava/lang/String;Landroid/os/Handler;)V

    :goto_53
    return-void
.end method

.method public final updateGestureSettingValue()V
    .locals 5

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    invoke-virtual {v0}, Landroid/content/Context;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v0

    iget-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-string/jumbo v1, "fingerprint_gesture_quick"

    const/4 v2, 0x0

    const/4 v3, -0x2

    invoke-static {v0, v1, v2, v3}, Landroid/provider/Settings$System;->getIntForUser(Landroid/content/ContentResolver;Ljava/lang/String;II)I

    move-result v1

    const/4 v4, 0x1

    if-ne v1, v4, :cond_19

    move v1, v4

    goto :goto_1a

    :cond_19
    move v1, v2

    :goto_1a
    iput-boolean v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForStatusBar:Z

    const-string/jumbo v1, "fingerprint_gesture_spay"

    invoke-static {v0, v1, v2, v3}, Landroid/provider/Settings$System;->getIntForUser(Landroid/content/ContentResolver;Ljava/lang/String;II)I

    move-result v0

    if-ne v0, v4, :cond_29

    sget-boolean v0, Lcom/android/server/biometrics/SemBiometricFeature;->FEATURE_LOGGING_MODE:Z

    move v0, v4

    goto :goto_2a

    :cond_29
    move v0, v2

    :goto_2a
    iput-boolean v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForSamsungPay:Z

    iget-boolean v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForStatusBar:Z

    if-nez v1, :cond_32

    if-eqz v0, :cond_33

    :cond_32
    move v2, v4

    :cond_33
    iput-boolean v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    new-instance v0, Ljava/lang/StringBuilder;

    const-string/jumbo v1, "updateGestureSettingValue: "

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    iget-boolean v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForStatusBar:Z

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    const-string v1, ", "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    iget-boolean p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureForSamsungPay:Z

    const-string v1, "FingerprintService.Gesture"

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v1, v0}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method


.method public static regAsUser(Landroid/content/Context;Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Landroid/os/UserHandle;Ljava/lang/String;Landroid/os/Handler;)V
    .locals 6

    :try_start_0
    move-object v0, p0

    move-object v1, p1

    move-object v2, p3

    move-object v3, p2

    move-object v4, p4

    move-object v5, p5

    invoke-virtual/range {v0 .. v5}, Landroid/content/Context;->registerReceiverAsUser(Landroid/content/BroadcastReceiver;Landroid/os/UserHandle;Landroid/content/IntentFilter;Ljava/lang/String;Landroid/os/Handler;)Landroid/content/Intent;
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "FingerprintService.Gesture"

    const-string v2, "regAsUser failed"

    invoke-static {v1, v2, v0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public final onGestureEvent(I)V
    .locals 2

    :try_start_0
    invoke-virtual {p0, p1}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->onGestureEventInner(I)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception p0

    const-string p1, "FingerprintService.Gesture"

    const-string v0, "onGestureEvent failed"

    invoke-static {p1, v0, p0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public final turnOnGestureMode()V
    .locals 3

    :try_start_0
    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOnGestureModeInner()V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception p0

    const-string v0, "FingerprintService.Gesture"

    const-string v1, "turnOnGestureMode failed"

    invoke-static {v0, v1, p0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public final turnOffGestureMode()V
    .locals 3

    :try_start_0
    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOffGestureModeInner()V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception p0

    const-string v0, "FingerprintService.Gesture"

    const-string v1, "turnOffGestureMode failed"

    invoke-static {v0, v1, p0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public final registerObservers()V
    .locals 6

    const-string v0, "FingerprintService.Gesture"

    :try_start_0
    new-instance v1, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

    invoke-direct {v1, p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V

    iput-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mUserSwitchObserver:Landroid/app/SynchronousUserSwitchObserver;

    invoke-static {}, Landroid/app/ActivityManager;->getService()Landroid/app/IActivityManager;

    move-result-object v2

    invoke-interface {v2, v1, v0}, Landroid/app/IActivityManager;->registerUserSwitchObserver(Landroid/app/IUserSwitchObserver;Ljava/lang/String;)V

    new-instance v1, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$2;

    iget-object v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    invoke-direct {v1, p0, v2}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$2;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;Landroid/os/Handler;)V

    iput-object v1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContentObserver:Landroid/database/ContentObserver;

    iget-object v2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    invoke-virtual {v2}, Landroid/content/Context;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v2

    const-string v3, "fingerprint_gesture_quick"

    invoke-static {v3}, Landroid/provider/Settings$System;->getUriFor(Ljava/lang/String;)Landroid/net/Uri;

    move-result-object v3

    const/4 v4, 0x0

    const/4 v5, -0x1

    invoke-virtual {v2, v3, v4, v1, v5}, Landroid/content/ContentResolver;->registerContentObserver(Landroid/net/Uri;ZLandroid/database/ContentObserver;I)V

    const-string v3, "fingerprint_gesture_spay"

    invoke-static {v3}, Landroid/provider/Settings$System;->getUriFor(Ljava/lang/String;)Landroid/net/Uri;

    move-result-object v3

    invoke-virtual {v2, v3, v4, v1, v5}, Landroid/content/ContentResolver;->registerContentObserver(Landroid/net/Uri;ZLandroid/database/ContentObserver;I)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v1

    const-string v2, "registerObservers failed"

    invoke-static {v0, v2, v1}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public static install(Lcom/android/server/biometrics/sensors/fingerprint/SemFingerprintServiceExtImpl;Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;)V
    .locals 5

    :try_start_0
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFingerprintServiceExtImpl;->mContext:Landroid/content/Context;

    new-instance v1, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-direct {v1}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;-><init>()V

    new-instance v2, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-direct {v2, v0, p1, v1}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;-><init>(Landroid/content/Context;Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;)V

    sput-object v2, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->sInstance:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-interface {p1, v2}, Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;->semAddEventListener(Lcom/android/server/biometrics/sensors/fingerprint/SemFpEventListener;)V

    invoke-virtual {v2}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->updateGestureSettingValue()V

    invoke-virtual {v2}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->registerObservers()V

    iget-object v3, v2, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    new-instance v4, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Starter;

    invoke-direct {v4, v2}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Starter;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V

    invoke-virtual {v3, v4}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "FingerprintService.Gesture"

    const-string v2, "install failed"

    invoke-static {v1, v2, v0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$1.smali" <<'EOF_GESTURE_SMALI'
.class public final Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;
.super Landroid/app/SynchronousUserSwitchObserver;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"


# instance fields
.field public final synthetic this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;


# direct methods
.method public constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V
    .locals 0

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-direct {p0}, Landroid/app/SynchronousUserSwitchObserver;-><init>()V

    return-void
.end method


# virtual methods
.method public final onUserSwitchComplete(I)V
    .locals 2

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    iget-object v0, v0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    new-instance v1, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;

    invoke-direct {v1, p0, p1}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;I)V

    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    return-void
.end method

.method public final onUserSwitching(I)V
    .locals 1

    iget-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    iget-object p1, p1, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mH:Landroid/os/Handler;

    new-instance v0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda0;

    invoke-direct {v0, p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda0;-><init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;)V

    invoke-virtual {p1, v0}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$1\$\$ExternalSyntheticLambda0.smali" <<'EOF_GESTURE_SMALI'
.class public final synthetic Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;


# direct methods
.method public synthetic constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda0;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 0

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda0;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOffGestureMode()V

    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$1\$\$ExternalSyntheticLambda1.smali" <<'EOF_GESTURE_SMALI'
.class public final synthetic Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;
.super Ljava/lang/Object;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

.field public final synthetic f$1:I


# direct methods
.method public synthetic constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;I)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

    iput p2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;->f$1:I

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 3

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;

    iget p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1$$ExternalSyntheticLambda1;->f$1:I

    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    new-instance v1, Ljava/lang/StringBuilder;

    const-string/jumbo v2, "onUserSwitchComplete: "

    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string v1, "FingerprintService.Gesture"

    invoke-static {v1, p0}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    iget-object p0, v0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->updateGestureSettingValue()V

    iget-object p0, v0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$1;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    iget-boolean v0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-eqz v0, :cond_29

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOnGestureMode()V

    :cond_29
    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$2.smali" <<'EOF_GESTURE_SMALI'
.class public final Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$2;
.super Landroid/database/ContentObserver;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"


# instance fields
.field public final synthetic this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;


# direct methods
.method public constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;Landroid/os/Handler;)V
    .locals 0

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$2;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-direct {p0, p2}, Landroid/database/ContentObserver;-><init>(Landroid/os/Handler;)V

    return-void
.end method


# virtual methods
.method public final onChange(Z)V
    .locals 0

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$2;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->updateGestureSettingValue()V

    sget-boolean p1, Lcom/android/server/biometrics/SemBiometricFeature;->FEATURE_LOGGING_MODE:Z

    iget-boolean p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-eqz p1, :cond_f

    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOnGestureMode()V

    goto :goto_12

    :cond_f
    invoke-virtual {p0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->turnOffGestureMode()V

    :goto_12
    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$4.smali" <<'EOF_GESTURE_SMALI'
.class public final Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;
.super Landroid/content/BroadcastReceiver;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"


# instance fields
.field public final synthetic this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;


# direct methods
.method public constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V
    .locals 0

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    invoke-direct {p0}, Landroid/content/BroadcastReceiver;-><init>()V

    return-void
.end method


# virtual methods
.method public final onReceive(Landroid/content/Context;Landroid/content/Intent;)V
    .locals 7

    invoke-virtual {p2}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object p1

    const-string p2, "android.intent.action.SCREEN_OFF"

    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    const/4 v0, 0x0

    if-nez p2, :cond_6d

    const-string p2, "android.intent.action.ACTION_SCREEN_OFF_BY_PROXIMITY"

    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_16

    goto :goto_6d

    :cond_16
    const-string p2, "android.intent.action.SCREEN_ON"

    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-nez p2, :cond_26

    const-string p2, "android.intent.action.ACTION_SCREEN_ON_BY_PROXIMITY"

    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_b2

    :cond_26
    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    iget-boolean p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-nez p1, :cond_2e

    goto/16 :goto_b2

    :cond_2e
    iget-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object p2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {p2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-class p2, Landroid/os/PowerManager;

    invoke-virtual {p1, p2}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/PowerManager;

    invoke-virtual {p1}, Landroid/os/PowerManager;->isInteractive()Z

    move-result p1

    if-eqz p1, :cond_b2

    const-class p1, Landroid/os/PowerManagerInternal;

    invoke-static {p1}, Lcom/android/server/LocalServices;->getService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/PowerManagerInternal;

    invoke-virtual {p1}, Landroid/os/PowerManagerInternal;->isProximityPositive()Z

    move-result p1

    if-nez p1, :cond_b2

    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

    move-object v1, p0

    check-cast v1, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;

    invoke-virtual {v1}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->getSensorProperties()Ljava/util/List;

    move-result-object p0

    check-cast p0, Ljava/util/ArrayList;

    invoke-virtual {p0, v0}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    iget v2, p0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;->sensorId:I

    const/4 v4, 0x1

    const/4 v5, 0x0

    const/16 v3, 0x11

    const/4 v6, 0x0

    invoke-virtual/range {v1 .. v6}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->semRequest(III[B[B)I

    goto :goto_b2

    :cond_6d
    :goto_6d
    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$4;->this$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    iget-boolean p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mIsEnabledGestureMainSetting:Z

    if-nez p1, :cond_74

    goto :goto_b2

    :cond_74
    iget-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mContext:Landroid/content/Context;

    iget-object p2, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mInjector:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Injector;

    invoke-virtual {p2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    const-class p2, Landroid/os/PowerManager;

    invoke-virtual {p1, p2}, Landroid/content/Context;->getSystemService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/PowerManager;

    invoke-virtual {p1}, Landroid/os/PowerManager;->isInteractive()Z

    move-result p1

    if-eqz p1, :cond_97

    const-class p1, Landroid/os/PowerManagerInternal;

    invoke-static {p1}, Lcom/android/server/LocalServices;->getService(Ljava/lang/Class;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Landroid/os/PowerManagerInternal;

    invoke-virtual {p1}, Landroid/os/PowerManagerInternal;->isProximityPositive()Z

    move-result p1

    if-eqz p1, :cond_b2

    :cond_97
    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->mServiceProvider:Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;

    move-object v1, p0

    check-cast v1, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;

    invoke-virtual {v1}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->getSensorProperties()Ljava/util/List;

    move-result-object p0

    check-cast p0, Ljava/util/ArrayList;

    invoke-virtual {p0, v0}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    iget v2, p0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;->sensorId:I

    const/4 v4, 0x0

    const/4 v5, 0x0

    const/16 v3, 0x11

    const/4 v6, 0x0

    invoke-virtual/range {v1 .. v6}, Lcom/android/server/biometrics/sensors/fingerprint/aidl/FingerprintProvider;->semRequest(III[B[B)I

    :cond_b2
    :goto_b2
    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpGestureManager\$Starter.smali" <<'EOF_GESTURE_SMALI'
.class public final Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Starter;
.super Ljava/lang/Object;
.source "SemFpGestureManager.java"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;


# direct methods
.method public constructor <init>(Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Starter;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 2

    :try_start_0
    iget-object p0, p0, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager$Starter;->f$0:Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;

    const/4 v0, 0x0

    invoke-virtual {p0, v0}, Lcom/android/server/biometrics/sensors/fingerprint/SemFpGestureManager;->onHalStarted(Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception p0

    const-string v0, "FingerprintService.Gesture"

    const-string v1, "start failed"

    invoke-static {v0, v1, p0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method
EOF_GESTURE_SMALI

cat > "$_GD/SemFpHalLifecycleListener.smali" <<'EOF_GESTURE_SMALI'
.class public interface abstract Lcom/android/server/biometrics/sensors/fingerprint/SemFpHalLifecycleListener;
.super Ljava/lang/Object;
.source "qb/114523926 fe3a31b9c59b36bb29a50db6deed590282a850d6144aa53a7c98c7c7ddad59a9"


# virtual methods
.method public onHalStarted(Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;)V
    .locals 0

    return-void
.end method
EOF_GESTURE_SMALI

python3 - <<'EOF_GESTURE_PY' || return 1
import re, glob, sys

def find(name):
    r = glob.glob('**/' + name, recursive=True)
    if len(r) != 1:
        sys.exit('gesture: expected exactly one %s, found %s' % (name, r))
    return r[0]

BF = 'Lcom/android/server/biometrics/SemBiometricFeature;'
FP = 'Lcom/android/server/biometrics/sensors/fingerprint/'

# 1) SemBiometricFeature: add FP_FEATURE_GESTURE_MODE (true: this ROM targets a side/power-key sensor, like stock)
p = find('SemBiometricFeature.smali'); t = open(p).read()
if 'FP_FEATURE_GESTURE_MODE' not in t:
    fld = '.field public static final FP_FEATURE_SENSOR_IS_SIDE:Z'
    if fld not in t: sys.exit('gesture: IS_SIDE field not found')
    t = t.replace(fld, fld + '\n\n.field public static final FP_FEATURE_GESTURE_MODE:Z', 1)
    m = re.search(r'(\n[ \t]*sput-boolean (v\d+), ' + re.escape(BF) + r'->FP_FEATURE_SENSOR_IS_SIDE:Z\n)', t)
    if not m: sys.exit('gesture: IS_SIDE sput not found')
    r = m.group(2)
    t = t.replace(m.group(1), m.group(1) + '\n    const/4 %s, 0x1\n\n    sput-boolean %s, %s->FP_FEATURE_GESTURE_MODE:Z\n' % (r, r, BF), 1)
    open(p, 'w').write(t)

# 2) FingerprintService$1.semHasFeature(1) -> FP_FEATURE_GESTURE_MODE
p = find('FingerprintService$1.smali'); t = open(p).read()
m = re.search(r'\.method public final semHasFeature\(I\)Z.*?\.end method', t, re.S)
if not m: sys.exit('gesture: semHasFeature not found')
body = m.group(0)
if 'FP_FEATURE_GESTURE_MODE' not in body:
    m1 = re.search(r'const/4 (p\d), 0x1\s+if-eq p1, \1, :(\w+)', body)
    if not m1: sys.exit('gesture: semHasFeature id 1 branch not found')
    m2 = re.search(r'(:%s\s+)sget-boolean (p\d), %s->FEATURE_LOGGING_MODE:Z' % (m1.group(2), re.escape(BF)), body)
    if not m2: sys.exit('gesture: semHasFeature id 1 block not found')
    new = body[:m2.start()] + m2.group(1) + 'sget-boolean %s, %s->FP_FEATURE_GESTURE_MODE:Z\n\n    return %s' % (m2.group(2), BF, m2.group(2)) + body[m2.end():]
    open(p, 'w').write(t.replace(body, new, 1))

# 3) hook: build the gesture manager in the 0x258 boot-phase block of FingerprintService
p = find('FingerprintService$$ExternalSyntheticLambda1.smali'); t = open(p).read()
if 'SemFpGestureManager;->install' not in t:
    i = t.find('const/16 v1, 0x258')
    if i < 0: sys.exit('gesture: boot phase 0x258 not found')
    pat = re.compile(r'invoke-virtual \{(v\d+)\}, Lcom/android/server/biometrics/sensors/BiometricServiceRegistry;->getSingleProvider\(\)Landroid/util/Pair;\s+move-result-object (v\d+)\s+if-eqz \2, :(\w+)\s+iget-object (v\d+), \2, Landroid/util/Pair;->second:Ljava/lang/Object;\s+check-cast \4, ' + re.escape(FP) + r'ServiceProvider;\n')
    m = pat.search(t, i)
    if not m: sys.exit('gesture: getSingleProvider block not found')
    m2 = re.compile(r'iget-boolean \w+, (v\d+), ' + re.escape(FP) + r'SemFingerprintServiceExtImpl;->mHasUdfps:Z').search(t, m.end())
    if not m2 or m2.start() - m.end() > 600: sys.exit('gesture: ExtImpl register not found')
    ext, prov = m2.group(1), m.group(4)
    hook = ('\n    :gest_try_start\n'
            '    invoke-static {%s, %s}, %sSemFpGestureManager;->install(%sSemFingerprintServiceExtImpl;%sServiceProvider;)V\n'
            '    :gest_try_end\n'
            '    .catch Ljava/lang/Throwable; {:gest_try_start .. :gest_try_end} :gest_catch\n\n'
            '    goto :gest_done\n\n'
            '    :gest_catch\n'
            '    move-exception %s\n\n'
            '    :gest_done\n') % (ext, prov, FP, FP, FP, prov)
    t = t[:m.end()] + hook + t[m.end():]
    open(p, 'w').write(t)
print('gesture: services.jar patched')
EOF_GESTURE_PY