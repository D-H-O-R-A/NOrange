package com.harshRajpurohit.freeVpn;

import android.app.Service;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.IBinder;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

public class FloatingControlService extends Service {
    public static boolean isRunning = false;
    private WindowManager windowManager;
    private LinearLayout rootLayout;
    private LinearLayout expandedPanel;
    private TextView statusLabel;
    private TextView foregroundAppLabel;

    private boolean vpnPerAppActive = false;
    private boolean mockGpsActive = false;
    private boolean virtualCamActive = false;
    private String lastDetectedPackage = "";

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        isRunning = true;
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        int layoutFlag;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            layoutFlag = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            layoutFlag = WindowManager.LayoutParams.TYPE_PHONE;
        }

        final WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
        );

        params.gravity = Gravity.TOP | Gravity.START;
        params.x = 24;
        params.y = 260;

        rootLayout = new LinearLayout(this);
        rootLayout.setOrientation(LinearLayout.VERTICAL);

        // Floating Bubble Button
        final TextView bubbleBtn = new TextView(this);
        bubbleBtn.setText("🛡️ VPN");
        bubbleBtn.setTextColor(Color.WHITE);
        bubbleBtn.setTextSize(13f);
        bubbleBtn.setTypeface(null, Typeface.BOLD);
        bubbleBtn.setPadding(28, 20, 28, 20);

        GradientDrawable bubbleBg = new GradientDrawable();
        bubbleBg.setColor(Color.parseColor("#1565C0"));
        bubbleBg.setCornerRadius(100f);
        bubbleBg.setStroke(3, Color.parseColor("#64B5F6"));
        bubbleBtn.setBackground(bubbleBg);

        // Expanded Control Panel
        expandedPanel = new LinearLayout(this);
        expandedPanel.setOrientation(LinearLayout.VERTICAL);
        expandedPanel.setPadding(30, 24, 30, 24);
        expandedPanel.setVisibility(View.GONE);

        GradientDrawable panelBg = new GradientDrawable();
        panelBg.setColor(Color.parseColor("#EE101820"));
        panelBg.setCornerRadius(32f);
        panelBg.setStroke(2, Color.parseColor("#1E88E5"));
        expandedPanel.setBackground(panelBg);

        TextView title = new TextView(this);
        title.setText("⚡ Hide Protocol Assistente");
        title.setTextColor(Color.WHITE);
        title.setTextSize(14f);
        title.setTypeface(null, Typeface.BOLD);
        expandedPanel.addView(title);

        foregroundAppLabel = new TextView(this);
        foregroundAppLabel.setText("App Alvo: Detectando...");
        foregroundAppLabel.setTextColor(Color.parseColor("#90CAF9"));
        foregroundAppLabel.setTextSize(11.5f);
        foregroundAppLabel.setPadding(0, 6, 0, 10);
        expandedPanel.addView(foregroundAppLabel);

        statusLabel = new TextView(this);
        statusLabel.setText("Pronto para ação rápida");
        statusLabel.setTextColor(Color.parseColor("#A5D6A7"));
        statusLabel.setTextSize(11f);
        statusLabel.setPadding(0, 0, 0, 12);
        expandedPanel.addView(statusLabel);

        // Button 1: Per-App VPN / Proxy
        final Button btnAppVpn = createActionButton("🔒 VPN/Proxy Só Neste App: OFF", "#1E88E5");
        btnAppVpn.setOnClickListener(v -> {
            String targetPkg = detectForegroundApp();
            vpnPerAppActive = !vpnPerAppActive;
            btnAppVpn.setText(vpnPerAppActive
                    ? "🔒 VPN Só Neste App: ON (" + shortPkg(targetPkg) + ")"
                    : "🔒 VPN/Proxy Só Neste App: OFF");
            statusLabel.setText(vpnPerAppActive
                    ? "Tráfego isolado para: " + shortPkg(targetPkg)
                    : "VPN por app desativada");
            sendFloatingAction("toggle_app_vpn", targetPkg, vpnPerAppActive);
        });
        expandedPanel.addView(btnAppVpn);

        // Button 2: Mock GPS Location
        final Button btnMockGps = createActionButton("📍 GPS Virtual (Padrão): OFF", "#FB8C00");
        btnMockGps.setOnClickListener(v -> {
            mockGpsActive = !mockGpsActive;
            btnMockGps.setText(mockGpsActive
                    ? "📍 GPS Virtual (Padrão): ON"
                    : "📍 GPS Virtual (Padrão): OFF");
            statusLabel.setText(mockGpsActive
                    ? "Coordenada GPS padrão injetada!"
                    : "GPS retornou ao normal");
            sendFloatingAction("toggle_mock_gps", "", mockGpsActive);
        });
        expandedPanel.addView(btnMockGps);

        // Button 3: Virtual Camera
        final Button btnVirtualCam = createActionButton("📷 Câmera Virtualizada: OFF", "#8E24AA");
        btnVirtualCam.setOnClickListener(v -> {
            virtualCamActive = !virtualCamActive;
            btnVirtualCam.setText(virtualCamActive
                    ? "📷 Câmera Virtualizada: ON"
                    : "📷 Câmera Virtualizada: OFF");
            statusLabel.setText(virtualCamActive
                    ? "Foto virtual ativa para capturas!"
                    : "Câmera virtual desativada");
            sendFloatingAction("toggle_virtual_cam", "", virtualCamActive);
        });
        expandedPanel.addView(btnVirtualCam);

        // Button 4: Open App / Close Overlay
        LinearLayout bottomRow = new LinearLayout(this);
        bottomRow.setOrientation(LinearLayout.HORIZONTAL);

        Button btnOpenApp = createActionButton("Abrir App", "#37474F");
        btnOpenApp.setOnClickListener(v -> {
            expandedPanel.setVisibility(View.GONE);
            Intent launch = new Intent(this, MainActivity.class);
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(launch);
        });
        bottomRow.addView(btnOpenApp);

        Button btnClose = createActionButton("Fechar X", "#C62828");
        btnClose.setOnClickListener(v -> stopSelf());
        bottomRow.addView(btnClose);

        expandedPanel.addView(bottomRow);

        rootLayout.addView(bubbleBtn);
        rootLayout.addView(expandedPanel);

        // Drag & Tap listener on bubble
        bubbleBtn.setOnTouchListener(new View.OnTouchListener() {
            private int initialX;
            private int initialY;
            private float initialTouchX;
            private float initialTouchY;
            private long touchStartTime;

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        initialX = params.x;
                        initialY = params.y;
                        initialTouchX = event.getRawX();
                        initialTouchY = event.getRawY();
                        touchStartTime = System.currentTimeMillis();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        params.x = initialX + (int) (event.getRawX() - initialTouchX);
                        params.y = initialY + (int) (event.getRawY() - initialTouchY);
                        windowManager.updateViewLayout(rootLayout, params);
                        return true;
                    case MotionEvent.ACTION_UP:
                        long elapsed = System.currentTimeMillis() - touchStartTime;
                        float dx = Math.abs(event.getRawX() - initialTouchX);
                        float dy = Math.abs(event.getRawY() - initialTouchY);
                        if (elapsed < 260 && dx < 20 && dy < 20) {
                            if (expandedPanel.getVisibility() == View.VISIBLE) {
                                expandedPanel.setVisibility(View.GONE);
                            } else {
                                String fg = detectForegroundApp();
                                foregroundAppLabel.setText("App em foco: " + shortPkg(fg));
                                expandedPanel.setVisibility(View.VISIBLE);
                            }
                        }
                        return true;
                }
                return false;
            }
        });

        windowManager.addView(rootLayout, params);
    }

    private Button createActionButton(String text, String hexColor) {
        Button btn = new Button(this);
        btn.setAllCaps(false);
        btn.setText(text);
        btn.setTextColor(Color.WHITE);
        btn.setTextSize(11.5f);
        btn.setPadding(20, 10, 20, 10);

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(4, 6, 4, 6);
        btn.setLayoutParams(lp);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor(hexColor));
        bg.setCornerRadius(18f);
        btn.setBackground(bg);
        return btn;
    }

    private String shortPkg(String pkg) {
        if (pkg == null || pkg.isEmpty()) return "Sistema / Atual";
        String[] parts = pkg.split("\\.");
        return parts[parts.length - 1];
    }

    private String detectForegroundApp() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
                long time = System.currentTimeMillis();
                List<UsageStats> appList = usm.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60, time);
                if (appList != null && !appList.isEmpty()) {
                    SortedMap<Long, UsageStats> sortedMap = new TreeMap<>();
                    for (UsageStats usageStats : appList) {
                        if (!usageStats.getPackageName().equals(getPackageName())) {
                            sortedMap.put(usageStats.getLastTimeUsed(), usageStats);
                        }
                    }
                    if (!sortedMap.isEmpty()) {
                        lastDetectedPackage = sortedMap.get(sortedMap.lastKey()).getPackageName();
                        return lastDetectedPackage;
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return lastDetectedPackage.isEmpty() ? getPackageName() : lastDetectedPackage;
    }

    private void sendFloatingAction(String cmd, String pkg, boolean enabled) {
        Intent intent = new Intent("floatingControlEvent");
        intent.putExtra("cmd", cmd);
        intent.putExtra("package", pkg);
        intent.putExtra("enabled", enabled);
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRunning = false;
        if (rootLayout != null && windowManager != null) {
            try {
                windowManager.removeView(rootLayout);
            } catch (Exception ignored) {
            }
        }
    }
}
