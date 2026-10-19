package com.harshRajpurohit.freeVpn;

import android.app.Service;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.io.File;
import java.io.FileOutputStream;
import java.util.List;
import java.util.Locale;
import java.util.SortedMap;
import java.util.TreeMap;

public class FloatingControlService extends Service {
    public static boolean isRunning = false;
    private static final String PREFS_NAME = "norange_floating_prefs";
    private static final String KEY_POS_X = "pos_x";
    private static final String KEY_POS_Y = "pos_y";

    private WindowManager windowManager;
    private WindowManager.LayoutParams params;
    private LinearLayout rootLayout;
    private LinearLayout bubbleContainer;
    private TextView bubbleTitleView;
    private View statusDotView;
    private LinearLayout expandedPanel;
    private TextView statusLabel;
    private TextView foregroundAppLabel;

    // Live Telemetry section inside the native floating widget
    private TextView telemetryTitleView;
    private TextView telemetryDetailsView;
    private TextView btnToggleConnection;
    private boolean networkActive = false;

    private LinearLayout rowAppVpn;
    private TextView txtAppVpn;
    private TextView badgeAppVpn;

    private LinearLayout rowMockGps;
    private TextView txtMockGps;
    private TextView badgeMockGps;

    private LinearLayout rowVirtualCam;
    private TextView txtVirtualCam;
    private TextView badgeVirtualCam;

    // Real-time Virtual Camera Studio embedded in Floating Overlay + Pass-through Live Camera Viewfinder HUD
    private LinearLayout vcamControlsContainer;
    private ImageView vcamMiniPreview;
    private FrameLayout vcamLiveHudWindow;
    private ImageView vcamLiveHudImage;
    private WindowManager.LayoutParams hudParams;
    private boolean liveHudVisible = false;
    private TextView btnToggleLiveHud;

    private Bitmap rawVcamBitmap;
    private Bitmap transformedVcamBitmap;
    private float vcamScaleX = 1.0f;
    private float vcamScaleY = 1.0f;
    private float vcamOffsetX = 0.0f;
    private float vcamOffsetY = 0.0f;
    private float vcamRotation = 0.0f;
    private boolean vcamFlipH = false;
    private boolean vcamFlipV = false;
    private float vcamPitch = 0.0f;
    private float vcamYaw = 0.0f;

    private boolean vpnPerAppActive = false;
    private boolean mockGpsActive = false;
    private boolean virtualCamActive = false;
    private String lastDetectedPackage = "";

    private LinearLayout gpsControlsContainer;
    private TextView txtGpsCoordsDisplay;
    private TextView btnSwitchConn;
    private double currentMockLat = -23.550520;
    private double currentMockLon = -46.633308;

    private final BroadcastReceiver telemetryReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String title = intent.getStringExtra("title");
            String details = intent.getStringExtra("details");
            networkActive = intent.getBooleanExtra("isActive", false);

            boolean hasError = (title != null && (title.contains("FALHA") || title.contains("Erro") || title.contains("Fora do Ar"))) ||
                               (details != null && (details.contains("FALHA") || details.contains("Tempo limite") || details.contains("Fora do Ar")));

            if (telemetryTitleView != null && title != null) {
                telemetryTitleView.setText(title);
                telemetryTitleView.setTextColor(Color.parseColor(hasError ? "#EF4444" : "#F8FAFC"));
            }
            if (telemetryDetailsView != null && details != null) {
                telemetryDetailsView.setText(details);
            }
            if (btnToggleConnection != null) {
                btnToggleConnection.setText(networkActive ? "Desligar" : (hasError ? "Tentar" : "Ligar"));
            }
            if (btnSwitchConn != null) {
                btnSwitchConn.setText(hasError ? "Próximo Nó" : "Trocar");
                GradientDrawable bg = new GradientDrawable();
                bg.setColor(Color.parseColor(hasError ? "#991B1B" : "#1C202B"));
                bg.setCornerRadius(dp(10));
                btnSwitchConn.setBackground(bg);
            }
            if (bubbleTitleView != null) {
                bubbleTitleView.setText(hasError ? "NOrange • ERRO" : (networkActive ? "NOrange • ON" : "NOrange"));
            }
            updateBubbleIndicator();
        }
    };

    private final BroadcastReceiver vcamSyncReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent != null && !"overlay".equals(intent.getStringExtra("source"))) {
                loadVcamStateFromPrefs();
                reloadRawVcamBitmap();
                applyRealtimeVcamTransform(false);
            }
        }
    };

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private int dp(float value) {
        float density = getResources().getDisplayMetrics().density;
        return Math.round(value * density);
    }

    @Override
    public void onCreate() {
        super.onCreate();
        isRunning = true;
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        loadVcamStateFromPrefs();
        reloadRawVcamBitmap();

        LocalBroadcastManager.getInstance(this).registerReceiver(
                telemetryReceiver,
                new IntentFilter("norangeTelemetryUpdate")
        );
        LocalBroadcastManager.getInstance(this).registerReceiver(
                vcamSyncReceiver,
                new IntentFilter(VirtualCameraActivity.ACTION_VCAM_SYNC)
        );

        int layoutFlag;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            layoutFlag = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            layoutFlag = WindowManager.LayoutParams.TYPE_PHONE;
        }

        params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
        );

        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        params.gravity = Gravity.TOP | Gravity.START;
        params.x = prefs.getInt(KEY_POS_X, dp(16));
        params.y = prefs.getInt(KEY_POS_Y, dp(160));
        clampPositionToSafeScreenBounds();

        rootLayout = new LinearLayout(this);
        rootLayout.setOrientation(LinearLayout.VERTICAL);

        // 1. Compact NOrange Pill Bubble
        bubbleContainer = new LinearLayout(this);
        bubbleContainer.setOrientation(LinearLayout.HORIZONTAL);
        bubbleContainer.setGravity(Gravity.CENTER_VERTICAL);
        bubbleContainer.setPadding(dp(10), dp(7), dp(12), dp(7));

        GradientDrawable bubbleBg = new GradientDrawable();
        bubbleBg.setColor(Color.parseColor("#F508090C"));
        bubbleBg.setCornerRadius(dp(28));
        bubbleBg.setStroke(dp(1.5f), Color.parseColor("#FF6B00"));
        bubbleContainer.setBackground(bubbleBg);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            bubbleContainer.setElevation(dp(6));
        }

        NOrangeEmblemView emblemView = new NOrangeEmblemView(this);
        LinearLayout.LayoutParams emblemLp = new LinearLayout.LayoutParams(dp(22), dp(22));
        emblemLp.setMargins(0, 0, dp(7), 0);
        emblemView.setLayoutParams(emblemLp);
        bubbleContainer.addView(emblemView);

        bubbleTitleView = new TextView(this);
        bubbleTitleView.setText("NOrange");
        bubbleTitleView.setTextColor(Color.parseColor("#F8FAFC"));
        bubbleTitleView.setTextSize(12f);
        bubbleTitleView.setTypeface(Typeface.DEFAULT_BOLD);
        bubbleContainer.addView(bubbleTitleView);

        statusDotView = new View(this);
        LinearLayout.LayoutParams dotLp = new LinearLayout.LayoutParams(dp(7), dp(7));
        dotLp.setMargins(dp(7), 0, 0, 0);
        statusDotView.setLayoutParams(dotLp);
        updateBubbleIndicator();
        bubbleContainer.addView(statusDotView);

        // 2. Expanded NOrange Tactical Pod
        expandedPanel = new LinearLayout(this);
        expandedPanel.setOrientation(LinearLayout.VERTICAL);
        expandedPanel.setPadding(dp(14), dp(12), dp(14), dp(12));
        expandedPanel.setVisibility(View.GONE);
        LinearLayout.LayoutParams panelLp = new LinearLayout.LayoutParams(
                dp(296),
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        panelLp.setMargins(0, dp(6), 0, 0);
        expandedPanel.setLayoutParams(panelLp);

        GradientDrawable panelBg = new GradientDrawable();
        panelBg.setColor(Color.parseColor("#F70B0C10"));
        panelBg.setCornerRadius(dp(20));
        panelBg.setStroke(dp(1.3f), Color.parseColor("#FF6B00"));
        expandedPanel.setBackground(panelBg);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            expandedPanel.setElevation(dp(10));
        }

        // Panel Header Row
        LinearLayout headerRow = new LinearLayout(this);
        headerRow.setOrientation(LinearLayout.HORIZONTAL);
        headerRow.setGravity(Gravity.CENTER_VERTICAL);

        NOrangeEmblemView headerEmblem = new NOrangeEmblemView(this);
        LinearLayout.LayoutParams hEmblemLp = new LinearLayout.LayoutParams(dp(20), dp(20));
        hEmblemLp.setMargins(0, 0, dp(8), 0);
        headerEmblem.setLayoutParams(hEmblemLp);
        headerRow.addView(headerEmblem);

        TextView title = new TextView(this);
        title.setText("NOrange Pod • Central");
        title.setTextColor(Color.parseColor("#F8FAFC"));
        title.setTextSize(12.5f);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        LinearLayout.LayoutParams titleLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        title.setLayoutParams(titleLp);
        headerRow.addView(title);

        TextView collapseBtn = new TextView(this);
        collapseBtn.setText("Recolher");
        collapseBtn.setTextColor(Color.parseColor("#9CA3AF"));
        collapseBtn.setTextSize(11f);
        collapseBtn.setPadding(dp(8), dp(4), dp(4), dp(4));
        collapseBtn.setOnClickListener(v -> toggleExpandedPanel(false));
        headerRow.addView(collapseBtn);

        expandedPanel.addView(headerRow);

        // Scrollable body inside expandedPanel so all real-time controls fit comfortably
        ScrollView bodyScroll = new ScrollView(this);
        bodyScroll.setVerticalScrollBarEnabled(false);
        DisplayMetrics dm = getResources().getDisplayMetrics();
        int maxScrollH = Math.min(dp(430), (int) (dm.heightPixels * 0.66f));
        LinearLayout.LayoutParams scrollLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        bodyScroll.setLayoutParams(scrollLp);

        LinearLayout bodyContent = new LinearLayout(this);
        bodyContent.setOrientation(LinearLayout.VERTICAL);

        foregroundAppLabel = new TextView(this);
        foregroundAppLabel.setText("App em foco: Detectando...");
        foregroundAppLabel.setTextColor(Color.parseColor("#FF8833"));
        foregroundAppLabel.setTextSize(10.5f);
        foregroundAppLabel.setPadding(0, dp(5), 0, dp(2));
        bodyContent.addView(foregroundAppLabel);

        // Live Connection Details Box inside Native Overlay
        LinearLayout telemetryBox = new LinearLayout(this);
        telemetryBox.setOrientation(LinearLayout.VERTICAL);
        telemetryBox.setPadding(dp(10), dp(8), dp(10), dp(8));
        LinearLayout.LayoutParams telLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        telLp.setMargins(0, dp(4), 0, dp(6));
        telemetryBox.setLayoutParams(telLp);

        GradientDrawable telBg = new GradientDrawable();
        telBg.setColor(Color.parseColor("#13151D"));
        telBg.setCornerRadius(dp(12));
        telBg.setStroke(dp(1), Color.parseColor("#2A2F3D"));
        telemetryBox.setBackground(telBg);

        telemetryTitleView = new TextView(this);
        telemetryTitleView.setText("Status da Conexão NOrange");
        telemetryTitleView.setTextColor(Color.parseColor("#F8FAFC"));
        telemetryTitleView.setTextSize(11f);
        telemetryTitleView.setTypeface(Typeface.DEFAULT_BOLD);
        telemetryBox.addView(telemetryTitleView);

        telemetryDetailsView = new TextView(this);
        telemetryDetailsView.setText("VPN, Proxy e Gateway prontos para acionamento rápido.");
        telemetryDetailsView.setTextColor(Color.parseColor("#9CA3AF"));
        telemetryDetailsView.setTextSize(9.5f);
        telemetryDetailsView.setPadding(0, dp(3), 0, dp(7));
        telemetryBox.addView(telemetryDetailsView);

        LinearLayout telBtnRow = new LinearLayout(this);
        telBtnRow.setOrientation(LinearLayout.HORIZONTAL);

        btnToggleConnection = createFooterButton("Ligar / Desligar", "#FF6B00", "#08090C", true);
        LinearLayout.LayoutParams tBtn1 = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        tBtn1.setMargins(0, 0, dp(5), 0);
        btnToggleConnection.setLayoutParams(tBtn1);
        btnToggleConnection.setOnClickListener(v -> {
            animatePress(btnToggleConnection);
            sendFloatingAction("toggle_connection", "", true);
        });
        telBtnRow.addView(btnToggleConnection);

        btnSwitchConn = createFooterButton("Trocar", "#1C202B", "#F8FAFC", true);
        LinearLayout.LayoutParams tBtn2 = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.85f);
        tBtn2.setMargins(0, 0, dp(5), 0);
        btnSwitchConn.setLayoutParams(tBtn2);
        btnSwitchConn.setOnClickListener(v -> {
            animatePress(btnSwitchConn);
            sendFloatingAction("switch_connection", "", true);
        });
        telBtnRow.addView(btnSwitchConn);

        TextView btnDetails = createFooterButton("Detalhes", "#1C202B", "#FF8833", false);
        LinearLayout.LayoutParams tBtn3 = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.85f);
        btnDetails.setLayoutParams(tBtn3);
        btnDetails.setOnClickListener(v -> {
            animatePress(btnDetails);
            toggleExpandedPanel(false);
            Intent launch = new Intent(this, MainActivity.class);
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(launch);
            sendFloatingAction("open_details", "", true);
        });
        telBtnRow.addView(btnDetails);

        telemetryBox.addView(telBtnRow);
        bodyContent.addView(telemetryBox);

        statusLabel = new TextView(this);
        statusLabel.setText("Controles em tempo real sobre qualquer app:");
        statusLabel.setTextColor(Color.parseColor("#9CA3AF"));
        statusLabel.setTextSize(10f);
        statusLabel.setPadding(0, 0, 0, dp(4));
        bodyContent.addView(statusLabel);

        // Action 1: Per-App VPN / Proxy
        txtAppVpn = new TextView(this);
        badgeAppVpn = new TextView(this);
        rowAppVpn = createTacticalRow(
                NOrangeIconView.TYPE_SHIELD,
                "VPN / Proxy Neste App",
                txtAppVpn,
                badgeAppVpn,
                vpnPerAppActive
        );
        rowAppVpn.setOnClickListener(v -> {
            animatePress(rowAppVpn);
            String targetPkg = detectForegroundApp();
            vpnPerAppActive = !vpnPerAppActive;
            txtAppVpn.setText(vpnPerAppActive
                    ? "VPN Só Neste App (" + shortPkg(targetPkg) + ")"
                    : "VPN / Proxy Neste App");
            applyRowState(rowAppVpn, badgeAppVpn, vpnPerAppActive);
            statusLabel.setText(vpnPerAppActive
                    ? "Tráfego isolado para: " + shortPkg(targetPkg)
                    : "Isolamento por app desativado");
            statusLabel.setTextColor(Color.parseColor(vpnPerAppActive ? "#FF8833" : "#9CA3AF"));
            updateBubbleIndicator();
            sendFloatingAction("toggle_app_vpn", targetPkg, vpnPerAppActive);
        });
        bodyContent.addView(rowAppVpn);

        // Action 2: Mock GPS Location
        txtMockGps = new TextView(this);
        badgeMockGps = new TextView(this);
        rowMockGps = createTacticalRow(
                NOrangeIconView.TYPE_GPS,
                "GPS Virtual (Padrão)",
                txtMockGps,
                badgeMockGps,
                mockGpsActive
        );
        rowMockGps.setOnClickListener(v -> {
            animatePress(rowMockGps);
            mockGpsActive = !mockGpsActive;
            applyRowState(rowMockGps, badgeMockGps, mockGpsActive);
            if (gpsControlsContainer != null) {
                gpsControlsContainer.setVisibility(mockGpsActive ? View.VISIBLE : View.GONE);
            }
            statusLabel.setText(mockGpsActive
                    ? String.format(Locale.US, "GPS Virtual ativo (%.4f, %.4f)", currentMockLat, currentMockLon)
                    : "GPS do sistema restaurado");
            statusLabel.setTextColor(Color.parseColor(mockGpsActive ? "#34D399" : "#9CA3AF"));
            updateBubbleIndicator();
            Intent intent = new Intent("floatingControlEvent");
            intent.putExtra("cmd", "toggle_mock_gps");
            intent.putExtra("enabled", mockGpsActive);
            intent.putExtra("lat", currentMockLat);
            intent.putExtra("lon", currentMockLon);
            LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
        });
        bodyContent.addView(rowMockGps);

        // Quick GPS Real-Time Adjuster Pad (Visible when GPS is active)
        gpsControlsContainer = buildEmbeddedGpsControls();
        gpsControlsContainer.setVisibility(mockGpsActive ? View.VISIBLE : View.GONE);
        bodyContent.addView(gpsControlsContainer);

        // Action 3: Virtual Camera Toggle + Embedded Real-Time Transform Pad (Pan, Scale, Stretch, Rotate, Flip)
        txtVirtualCam = new TextView(this);
        badgeVirtualCam = new TextView(this);
        rowVirtualCam = createTacticalRow(
                NOrangeIconView.TYPE_CAMERA,
                "Câmera Virtualizada (Foto & Live)",
                txtVirtualCam,
                badgeVirtualCam,
                virtualCamActive
        );
        rowVirtualCam.setOnClickListener(v -> {
            animatePress(rowVirtualCam);
            virtualCamActive = !virtualCamActive;
            applyRowState(rowVirtualCam, badgeVirtualCam, virtualCamActive);
            vcamControlsContainer.setVisibility(virtualCamActive ? View.VISIBLE : View.GONE);
            statusLabel.setText(virtualCamActive
                    ? "Câmera virtual ativa • Ajuste escala/posição em tempo real abaixo"
                    : "Câmera virtual desativada");
            statusLabel.setTextColor(Color.parseColor(virtualCamActive ? "#FF8833" : "#9CA3AF"));
            if (!virtualCamActive && liveHudVisible) {
                setLiveCameraHudVisible(false);
            }
            updateBubbleIndicator();
            sendFloatingAction("toggle_virtual_cam", "", virtualCamActive);
        });
        bodyContent.addView(rowVirtualCam);

        // Embedded Real-Time Camera Transform Studio (Works while inside any external camera app or live stream!)
        vcamControlsContainer = buildEmbeddedVcamStudio();
        vcamControlsContainer.setVisibility(virtualCamActive ? View.VISIBLE : View.GONE);
        bodyContent.addView(vcamControlsContainer);

        // Footer Row: Open NOrange Central & Close Overlay
        LinearLayout bottomRow = new LinearLayout(this);
        bottomRow.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams bottomLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        bottomLp.setMargins(0, dp(6), 0, 0);
        bottomRow.setLayoutParams(bottomLp);

        TextView btnOpenApp = createFooterButton("Abrir NOrange", "#FF6B00", "#08090C", true);
        LinearLayout.LayoutParams openLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.3f);
        openLp.setMargins(0, 0, dp(6), 0);
        btnOpenApp.setLayoutParams(openLp);
        btnOpenApp.setOnClickListener(v -> {
            animatePress(btnOpenApp);
            toggleExpandedPanel(false);
            Intent launch = new Intent(this, MainActivity.class);
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(launch);
        });
        bottomRow.addView(btnOpenApp);

        TextView btnClose = createFooterButton("Fechar", "#15171E", "#9CA3AF", false);
        LinearLayout.LayoutParams closeLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.8f);
        btnClose.setLayoutParams(closeLp);
        btnClose.setOnClickListener(v -> stopSelf());
        bottomRow.addView(btnClose);

        bodyContent.addView(bottomRow);
        bodyScroll.addView(bodyContent);
        expandedPanel.addView(bodyScroll);

        rootLayout.addView(bubbleContainer);
        rootLayout.addView(expandedPanel);

        // Drag, Edge-Snapping & Tap Listener on NOrange Bubble
        bubbleContainer.setOnTouchListener(new View.OnTouchListener() {
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
                        bubbleContainer.animate().scaleX(0.95f).scaleY(0.95f).setDuration(90).start();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        params.x = initialX + (int) (event.getRawX() - initialTouchX);
                        params.y = initialY + (int) (event.getRawY() - initialTouchY);
                        clampPositionToSafeScreenBounds();
                        windowManager.updateViewLayout(rootLayout, params);
                        return true;
                    case MotionEvent.ACTION_UP:
                    case MotionEvent.ACTION_CANCEL:
                        bubbleContainer.animate().scaleX(1f).scaleY(1f).setDuration(120).start();
                        long elapsed = System.currentTimeMillis() - touchStartTime;
                        float dx = Math.abs(event.getRawX() - initialTouchX);
                        float dy = Math.abs(event.getRawY() - initialTouchY);
                        if (elapsed < 260 && dx < dp(10) && dy < dp(10)) {
                            boolean willShow = expandedPanel.getVisibility() != View.VISIBLE;
                            toggleExpandedPanel(willShow);
                        } else {
                            snapToNearestHorizontalEdge();
                        }
                        return true;
                }
                return false;
            }
        });

        windowManager.addView(rootLayout, params);
    }

    private LinearLayout buildEmbeddedVcamStudio() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(9), dp(8), dp(9), dp(8));
        LinearLayout.LayoutParams boxLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        boxLp.setMargins(0, dp(3), 0, dp(4));
        box.setLayoutParams(boxLp);

        GradientDrawable boxBg = new GradientDrawable();
        boxBg.setColor(Color.parseColor("#11131A"));
        boxBg.setCornerRadius(dp(12));
        boxBg.setStroke(dp(1), Color.parseColor("#55FF6B00"));
        box.setBackground(boxBg);

        // Live Interactive Mini-Preview inside the overlay (supports touch drag!)
        vcamMiniPreview = new ImageView(this);
        LinearLayout.LayoutParams prevLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(86)
        );
        prevLp.setMargins(0, 0, 0, dp(6));
        vcamMiniPreview.setLayoutParams(prevLp);
        vcamMiniPreview.setScaleType(ImageView.ScaleType.FIT_CENTER);
        GradientDrawable prevBg = new GradientDrawable();
        prevBg.setColor(Color.parseColor("#07080B"));
        prevBg.setCornerRadius(dp(8));
        prevBg.setStroke(dp(1), Color.parseColor("#2A2F3D"));
        vcamMiniPreview.setBackground(prevBg);
        if (transformedVcamBitmap != null) {
            vcamMiniPreview.setImageBitmap(transformedVcamBitmap);
        }

        vcamMiniPreview.setOnTouchListener(new View.OnTouchListener() {
            private float lastX, lastY;
            @Override
            public boolean onTouch(View v, MotionEvent ev) {
                v.getParent().requestDisallowInterceptTouchEvent(true);
                switch (ev.getActionMasked()) {
                    case MotionEvent.ACTION_DOWN:
                        lastX = ev.getX();
                        lastY = ev.getY();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        float dx = ev.getX() - lastX;
                        float dy = ev.getY() - lastY;
                        lastX = ev.getX();
                        lastY = ev.getY();
                        vcamOffsetX = Math.max(-1.0f, Math.min(1.0f, vcamOffsetX + dx / dp(95)));
                        vcamOffsetY = Math.max(-1.0f, Math.min(1.0f, vcamOffsetY + dy / dp(75)));
                        applyRealtimeVcamTransform(true);
                        return true;
                }
                return true;
            }
        });
        box.addView(vcamMiniPreview);

        // Row 1: Pan Left, Right, Up, Down (Vector Icons — Zero text arrows!)
        LinearLayout r1 = new LinearLayout(this);
        r1.setOrientation(LinearLayout.HORIZONTAL);
        r1.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_LEFT, "Esq", () -> {
            vcamOffsetX = Math.max(-1.0f, vcamOffsetX - 0.10f);
            applyRealtimeVcamTransform(true);
        }));
        r1.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_RIGHT, "Dir", () -> {
            vcamOffsetX = Math.min(1.0f, vcamOffsetX + 0.10f);
            applyRealtimeVcamTransform(true);
        }));
        r1.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_UP, "Cima", () -> {
            vcamOffsetY = Math.max(-1.0f, vcamOffsetY - 0.10f);
            applyRealtimeVcamTransform(true);
        }));
        r1.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_DOWN, "Baixo", () -> {
            vcamOffsetY = Math.min(1.0f, vcamOffsetY + 0.10f);
            applyRealtimeVcamTransform(true);
        }));
        box.addView(r1);

        // Row 2: Zoom +, Zoom -, Stretch H, Stretch V
        LinearLayout r2 = new LinearLayout(this);
        r2.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams r2Lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        r2Lp.setMargins(0, dp(4), 0, dp(4));
        r2.setLayoutParams(r2Lp);
        r2.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_ZOOM_IN, "Zoom+", () -> {
            vcamScaleX = Math.min(3.5f, vcamScaleX + 0.15f);
            vcamScaleY = Math.min(3.5f, vcamScaleY + 0.15f);
            applyRealtimeVcamTransform(true);
        }));
        r2.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_ZOOM_OUT, "Zoom-", () -> {
            vcamScaleX = Math.max(0.35f, vcamScaleX - 0.15f);
            vcamScaleY = Math.max(0.35f, vcamScaleY - 0.15f);
            applyRealtimeVcamTransform(true);
        }));
        r2.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_STRETCH_H, "Alarg H", () -> {
            vcamScaleX = Math.min(3.5f, vcamScaleX + 0.18f);
            applyRealtimeVcamTransform(true);
        }));
        r2.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_STRETCH_V, "Alarg V", () -> {
            vcamScaleY = Math.min(3.5f, vcamScaleY + 0.18f);
            applyRealtimeVcamTransform(true);
        }));
        box.addView(r2);

        // Row 2.5: 3D Perspective Transform (Nodding / Turning in 3D Perspective)
        LinearLayout rPersp = new LinearLayout(this);
        rPersp.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams rPerspLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rPerspLp.setMargins(0, dp(3), 0, dp(3));
        rPersp.setLayoutParams(rPerspLp);
        rPersp.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_PERSPECTIVE_LEFT, "Olhar Esq", () -> {
            vcamYaw = Math.max(-45f, vcamYaw - 7.5f);
            applyRealtimeVcamTransform(true);
        }));
        rPersp.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_PERSPECTIVE_RIGHT, "Olhar Dir", () -> {
            vcamYaw = Math.min(45f, vcamYaw + 7.5f);
            applyRealtimeVcamTransform(true);
        }));
        rPersp.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_PERSPECTIVE_UP, "Olhar Cima", () -> {
            vcamPitch = Math.max(-45f, vcamPitch - 7.5f);
            applyRealtimeVcamTransform(true);
        }));
        rPersp.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_PERSPECTIVE_DOWN, "Olhar Baixo", () -> {
            vcamPitch = Math.min(45f, vcamPitch + 7.5f);
            applyRealtimeVcamTransform(true);
        }));
        box.addView(rPersp);

        // Row 3: Rotate 90, Flip H, Flip V, Reset
        LinearLayout r3 = new LinearLayout(this);
        r3.setOrientation(LinearLayout.HORIZONTAL);
        r3.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_ROTATE, "90°", () -> {
            vcamRotation = (vcamRotation + 90f) % 360f;
            applyRealtimeVcamTransform(true);
        }));
        r3.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_FLIP_H, "Esp H", () -> {
            vcamFlipH = !vcamFlipH;
            applyRealtimeVcamTransform(true);
        }));
        r3.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_FLIP_V, "Esp V", () -> {
            vcamFlipV = !vcamFlipV;
            applyRealtimeVcamTransform(true);
        }));
        r3.addView(createOverlayVectorBtn(VirtualCameraActivity.VectorControlIconView.ICON_RESET, "Reset", () -> {
            vcamScaleX = 1.0f;
            vcamScaleY = 1.0f;
            vcamOffsetX = 0.0f;
            vcamOffsetY = 0.0f;
            vcamRotation = 0.0f;
            vcamFlipH = false;
            vcamFlipV = false;
            vcamPitch = 0.0f;
            vcamYaw = 0.0f;
            applyRealtimeVcamTransform(true);
        }));
        box.addView(r3);

        // Row 4: Live Camera Viewfinder HUD Toggle + Pick Photo Now
        LinearLayout r4 = new LinearLayout(this);
        r4.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams r4Lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        r4Lp.setMargins(0, dp(6), 0, 0);
        r4.setLayoutParams(r4Lp);

        btnToggleLiveHud = createFooterButton(
                "Projetar Live na Câmera",
                "#1A1D26",
                "#FF8833",
                true
        );
        LinearLayout.LayoutParams hudBtnLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.15f);
        hudBtnLp.setMargins(0, 0, dp(5), 0);
        btnToggleLiveHud.setLayoutParams(hudBtnLp);
        btnToggleLiveHud.setOnClickListener(v -> {
            animatePress(btnToggleLiveHud);
            setLiveCameraHudVisible(!liveHudVisible);
        });
        r4.addView(btnToggleLiveHud);

        TextView btnPickImg = createFooterButton(
                "Trocar Foto",
                "#FF6B00",
                "#08090C",
                true
        );
        LinearLayout.LayoutParams pickBtnLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.85f);
        btnPickImg.setLayoutParams(pickBtnLp);
        btnPickImg.setOnClickListener(v -> {
            animatePress(btnPickImg);
            toggleExpandedPanel(false);
            Intent camStudio = new Intent(this, VirtualCameraActivity.class);
            camStudio.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(camStudio);
        });
        r4.addView(btnPickImg);

        box.addView(r4);
        return box;
    }

    private LinearLayout createOverlayVectorBtn(int iconType, String label, Runnable onTap) {
        LinearLayout btn = new LinearLayout(this);
        btn.setOrientation(LinearLayout.HORIZONTAL);
        btn.setGravity(Gravity.CENTER);
        btn.setPadding(dp(4), dp(5.5f), dp(4), dp(5.5f));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
        );
        lp.setMargins(dp(2), 0, dp(2), 0);
        btn.setLayoutParams(lp);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#181B24"));
        bg.setCornerRadius(dp(6));
        bg.setStroke(dp(1), Color.parseColor("#2A2F3D"));
        btn.setBackground(bg);

        VirtualCameraActivity.VectorControlIconView icon =
                new VirtualCameraActivity.VectorControlIconView(this, iconType);
        LinearLayout.LayoutParams iconLp = new LinearLayout.LayoutParams(dp(11), dp(11));
        iconLp.setMargins(0, 0, dp(3), 0);
        icon.setLayoutParams(iconLp);
        btn.addView(icon);

        TextView tv = new TextView(this);
        tv.setText(label);
        tv.setTextColor(Color.parseColor("#F8FAFC"));
        tv.setTextSize(9f);
        tv.setTypeface(Typeface.DEFAULT_BOLD);
        btn.addView(tv);

        btn.setOnClickListener(v -> {
            animatePress(btn);
            onTap.run();
        });
        return btn;
    }

    private void setLiveCameraHudVisible(boolean show) {
        liveHudVisible = show;
        if (btnToggleLiveHud != null) {
            btnToggleLiveHud.setText(show ? "Ocultar Live HUD" : "Projetar Live na Câmera");
        }
        if (show) {
            if (vcamLiveHudWindow == null) {
                int layoutFlag;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    layoutFlag = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
                } else {
                    layoutFlag = WindowManager.LayoutParams.TYPE_PHONE;
                }
                DisplayMetrics dm = getResources().getDisplayMetrics();
                int hudW = (int) (dm.widthPixels * 0.92f);
                int hudH = (int) (dm.heightPixels * 0.62f);

                hudParams = new WindowManager.LayoutParams(
                        hudW,
                        hudH,
                        layoutFlag,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                                | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                        PixelFormat.TRANSLUCENT
                );
                hudParams.gravity = Gravity.CENTER;

                vcamLiveHudWindow = new FrameLayout(this);
                GradientDrawable hudBorder = new GradientDrawable();
                hudBorder.setColor(Color.parseColor("#00000000"));
                hudBorder.setCornerRadius(dp(16));
                hudBorder.setStroke(dp(1.5f), Color.parseColor("#88FF6B00"));
                vcamLiveHudWindow.setBackground(hudBorder);

                vcamLiveHudImage = new ImageView(this);
                vcamLiveHudImage.setScaleType(ImageView.ScaleType.FIT_CENTER);
                if (transformedVcamBitmap != null) {
                    vcamLiveHudImage.setImageBitmap(transformedVcamBitmap);
                }
                vcamLiveHudWindow.addView(vcamLiveHudImage, new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                ));

                try {
                    windowManager.addView(vcamLiveHudWindow, hudParams);
                    // Re-bring floating pod on top of the pass-through HUD
                    windowManager.removeView(rootLayout);
                    windowManager.addView(rootLayout, params);
                } catch (Exception ignored) {
                }
            }
        } else {
            if (vcamLiveHudWindow != null) {
                try {
                    windowManager.removeView(vcamLiveHudWindow);
                } catch (Exception ignored) {
                }
                vcamLiveHudWindow = null;
                vcamLiveHudImage = null;
            }
        }
    }

    private LinearLayout buildEmbeddedGpsControls() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(10), dp(8), dp(10), dp(8));
        LinearLayout.LayoutParams boxLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        boxLp.setMargins(0, dp(2), 0, dp(4));
        box.setLayoutParams(boxLp);

        GradientDrawable boxBg = new GradientDrawable();
        boxBg.setColor(Color.parseColor("#11131A"));
        boxBg.setCornerRadius(dp(10));
        boxBg.setStroke(dp(1), Color.parseColor("#4410B981"));
        box.setBackground(boxBg);

        txtGpsCoordsDisplay = new TextView(this);
        txtGpsCoordsDisplay.setTextColor(Color.parseColor("#34D399"));
        txtGpsCoordsDisplay.setTextSize(10.5f);
        txtGpsCoordsDisplay.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        updateGpsCoordsLabel();
        box.addView(txtGpsCoordsDisplay);

        // Steppers row: [-0.01 Lat] [+0.01 Lat] [-0.01 Lon] [+0.01 Lon]
        LinearLayout stepRow = new LinearLayout(this);
        stepRow.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams stepLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        stepLp.setMargins(0, dp(5), 0, dp(4));
        stepRow.setLayoutParams(stepLp);

        stepRow.addView(createGpsStepBtn("-0.01 Lat", () -> adjustGpsCoord(-0.01, 0)));
        stepRow.addView(createGpsStepBtn("+0.01 Lat", () -> adjustGpsCoord(+0.01, 0)));
        stepRow.addView(createGpsStepBtn("-0.01 Lon", () -> adjustGpsCoord(0, -0.01)));
        stepRow.addView(createGpsStepBtn("+0.01 Lon", () -> adjustGpsCoord(0, +0.01)));
        box.addView(stepRow);

        // Quick presets row: [SP] [Tokyo] [NY] [Londres]
        LinearLayout presetRow = new LinearLayout(this);
        presetRow.setOrientation(LinearLayout.HORIZONTAL);
        presetRow.addView(createGpsPresetBtn("SP", -23.550520, -46.633308));
        presetRow.addView(createGpsPresetBtn("Tokyo", 35.6762, 139.6503));
        presetRow.addView(createGpsPresetBtn("NY", 40.7128, -74.0060));
        presetRow.addView(createGpsPresetBtn("Londres", 51.5074, -0.1278));
        box.addView(presetRow);

        return box;
    }

    private View createGpsStepBtn(String text, Runnable onClick) {
        TextView btn = new TextView(this);
        btn.setText(text);
        btn.setGravity(Gravity.CENTER);
        btn.setTextColor(Color.parseColor("#E2E8F0"));
        btn.setTextSize(9f);
        btn.setTypeface(Typeface.DEFAULT_BOLD);
        btn.setPadding(dp(4), dp(4.5f), dp(4), dp(4.5f));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(dp(1.5f), 0, dp(1.5f), 0);
        btn.setLayoutParams(lp);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#1B2230"));
        bg.setCornerRadius(dp(6));
        bg.setStroke(dp(1), Color.parseColor("#334155"));
        btn.setBackground(bg);
        btn.setOnClickListener(v -> {
            animatePress(btn);
            onClick.run();
        });
        return btn;
    }

    private View createGpsPresetBtn(String name, double lat, double lon) {
        TextView btn = new TextView(this);
        btn.setText(name);
        btn.setGravity(Gravity.CENTER);
        btn.setTextColor(Color.parseColor("#34D399"));
        btn.setTextSize(9f);
        btn.setTypeface(Typeface.DEFAULT_BOLD);
        btn.setPadding(dp(4), dp(4), dp(4), dp(4));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(dp(1.5f), 0, dp(1.5f), 0);
        btn.setLayoutParams(lp);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#0C231B"));
        bg.setCornerRadius(dp(6));
        bg.setStroke(dp(1), Color.parseColor("#059669"));
        btn.setBackground(bg);
        btn.setOnClickListener(v -> {
            animatePress(btn);
            currentMockLat = lat;
            currentMockLon = lon;
            updateGpsCoordsLabel();
            sendFloatingGpsCoords(currentMockLat, currentMockLon);
        });
        return btn;
    }

    private void adjustGpsCoord(double dLat, double dLon) {
        currentMockLat = Math.round((currentMockLat + dLat) * 10000.0) / 10000.0;
        currentMockLon = Math.round((currentMockLon + dLon) * 10000.0) / 10000.0;
        updateGpsCoordsLabel();
        sendFloatingGpsCoords(currentMockLat, currentMockLon);
    }

    private void updateGpsCoordsLabel() {
        if (txtGpsCoordsDisplay != null) {
            txtGpsCoordsDisplay.setText(String.format(Locale.US, "GPS: %.4f, %.4f", currentMockLat, currentMockLon));
        }
        if (txtMockGps != null) {
            txtMockGps.setText(String.format(Locale.US, "GPS Virtual (%.2f, %.2f)", currentMockLat, currentMockLon));
        }
    }

    private void sendFloatingGpsCoords(double lat, double lon) {
        Intent intent = new Intent("floatingControlEvent");
        intent.putExtra("cmd", "update_mock_gps_coords");
        intent.putExtra("lat", lat);
        intent.putExtra("lon", lon);
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    private void loadVcamStateFromPrefs() {
        SharedPreferences sp = getSharedPreferences(VirtualCameraActivity.PREFS_VCAM, MODE_PRIVATE);
        vcamScaleX = sp.getFloat("scaleX", 1.0f);
        vcamScaleY = sp.getFloat("scaleY", 1.0f);
        vcamOffsetX = sp.getFloat("offsetX", 0.0f);
        vcamOffsetY = sp.getFloat("offsetY", 0.0f);
        vcamRotation = sp.getFloat("rotation", 0.0f);
        vcamFlipH = sp.getBoolean("flipH", false);
        vcamFlipV = sp.getBoolean("flipV", false);
        vcamPitch = sp.getFloat("pitch", 0.0f);
        vcamYaw = sp.getFloat("yaw", 0.0f);
    }

    private void reloadRawVcamBitmap() {
        File rawFile = new File(getFilesDir(), "virtual_camera_raw.jpg");
        File frameFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
        if (rawFile.exists()) {
            rawVcamBitmap = BitmapFactory.decodeFile(rawFile.getAbsolutePath());
        } else if (frameFile.exists()) {
            rawVcamBitmap = BitmapFactory.decodeFile(frameFile.getAbsolutePath());
        }
        if (rawVcamBitmap == null) {
            rawVcamBitmap = Bitmap.createBitmap(640, 480, Bitmap.Config.ARGB_8888);
            Canvas c = new Canvas(rawVcamBitmap);
            c.drawColor(Color.parseColor("#101218"));
            Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
            p.setColor(Color.parseColor("#FF6B00"));
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(8f);
            c.drawCircle(320f, 240f, 96f, p);
        }
        transformedVcamBitmap = VirtualCameraActivity.renderTransformedBitmap(
                rawVcamBitmap, vcamScaleX, vcamScaleY, vcamOffsetX, vcamOffsetY, vcamRotation, vcamFlipH, vcamFlipV, vcamPitch, vcamYaw
        );
    }

    private void applyRealtimeVcamTransform(boolean broadcast) {
        if (rawVcamBitmap == null) reloadRawVcamBitmap();
        transformedVcamBitmap = VirtualCameraActivity.renderTransformedBitmap(
                rawVcamBitmap, vcamScaleX, vcamScaleY, vcamOffsetX, vcamOffsetY, vcamRotation, vcamFlipH, vcamFlipV, vcamPitch, vcamYaw
        );
        if (vcamMiniPreview != null) {
            vcamMiniPreview.setImageBitmap(transformedVcamBitmap);
        }
        if (vcamLiveHudImage != null) {
            vcamLiveHudImage.setImageBitmap(transformedVcamBitmap);
        }

        VirtualCameraActivity.saveTransformParams(
                this, vcamScaleX, vcamScaleY, vcamOffsetX, vcamOffsetY, vcamRotation, vcamFlipH, vcamFlipV, vcamPitch, vcamYaw
        );

        final Bitmap bmpCopy = transformedVcamBitmap;
        new Thread(() -> {
            File frameFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
            try (FileOutputStream out = new FileOutputStream(frameFile)) {
                bmpCopy.compress(Bitmap.CompressFormat.JPEG, 90, out);
                out.flush();
            } catch (Exception ignored) {
            }
        }).start();

        if (broadcast) {
            Intent sync = new Intent(VirtualCameraActivity.ACTION_VCAM_SYNC);
            sync.putExtra("source", "external");
            LocalBroadcastManager.getInstance(this).sendBroadcast(sync);
        }
    }

    private void toggleExpandedPanel(boolean show) {
        if (show) {
            String fg = detectForegroundApp();
            foregroundAppLabel.setText("App em foco: " + shortPkg(fg));
            loadVcamStateFromPrefs();
            reloadRawVcamBitmap();
            if (vcamMiniPreview != null && transformedVcamBitmap != null) {
                vcamMiniPreview.setImageBitmap(transformedVcamBitmap);
            }
            expandedPanel.setAlpha(0f);
            expandedPanel.setScaleX(0.94f);
            expandedPanel.setScaleY(0.94f);
            expandedPanel.setVisibility(View.VISIBLE);
            expandedPanel.animate()
                    .alpha(1f)
                    .scaleX(1f)
                    .scaleY(1f)
                    .setDuration(150)
                    .setInterpolator(new DecelerateInterpolator())
                    .start();
        } else {
            expandedPanel.setVisibility(View.GONE);
        }
    }

    private void animatePress(View v) {
        v.animate().scaleX(0.97f).scaleY(0.97f).setDuration(70).withEndAction(() ->
                v.animate().scaleX(1f).scaleY(1f).setDuration(100).start()
        ).start();
    }

    private void updateBubbleIndicator() {
        if (statusDotView == null) return;
        boolean anyActive = networkActive || vpnPerAppActive || mockGpsActive || virtualCamActive;
        GradientDrawable dotBg = new GradientDrawable();
        dotBg.setShape(GradientDrawable.OVAL);
        dotBg.setColor(Color.parseColor(anyActive ? "#FF6B00" : "#4B5563"));
        statusDotView.setBackground(dotBg);
    }

    private LinearLayout createTacticalRow(
            int iconType,
            String labelText,
            TextView titleRef,
            TextView badgeRef,
            boolean active
    ) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(10), dp(8), dp(10), dp(8));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(0, dp(3), 0, dp(3));
        row.setLayoutParams(lp);

        NOrangeIconView iconView = new NOrangeIconView(this, iconType);
        LinearLayout.LayoutParams iconLp = new LinearLayout.LayoutParams(dp(17), dp(17));
        iconLp.setMargins(0, 0, dp(9), 0);
        iconView.setLayoutParams(iconLp);
        row.addView(iconView);

        titleRef.setText(labelText);
        titleRef.setTextColor(Color.parseColor("#F8FAFC"));
        titleRef.setTextSize(11f);
        titleRef.setTypeface(Typeface.DEFAULT_BOLD);
        LinearLayout.LayoutParams txtLp = new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
        );
        titleRef.setLayoutParams(txtLp);
        row.addView(titleRef);

        badgeRef.setTextSize(9.5f);
        badgeRef.setTypeface(Typeface.DEFAULT_BOLD);
        badgeRef.setPadding(dp(7), dp(2.5f), dp(7), dp(2.5f));
        row.addView(badgeRef);

        applyRowState(row, badgeRef, active);
        return row;
    }

    private void applyRowState(LinearLayout row, TextView badge, boolean active) {
        GradientDrawable bg = new GradientDrawable();
        bg.setCornerRadius(dp(11));
        if (active) {
            bg.setColor(Color.parseColor("#24FF6B00"));
            bg.setStroke(dp(1), Color.parseColor("#FF6B00"));
        } else {
            bg.setColor(Color.parseColor("#14161D"));
            bg.setStroke(dp(1), Color.parseColor("#232632"));
        }
        row.setBackground(bg);

        GradientDrawable badgeBg = new GradientDrawable();
        badgeBg.setCornerRadius(dp(10));
        if (active) {
            badge.setText("ON");
            badge.setTextColor(Color.parseColor("#08090C"));
            badgeBg.setColor(Color.parseColor("#FF6B00"));
        } else {
            badge.setText("OFF");
            badge.setTextColor(Color.parseColor("#9CA3AF"));
            badgeBg.setColor(Color.parseColor("#1D202A"));
        }
        badge.setBackground(badgeBg);
    }

    private TextView createFooterButton(String text, String bgHex, String textHex, boolean bold) {
        TextView btn = new TextView(this);
        btn.setText(text);
        btn.setGravity(Gravity.CENTER);
        btn.setTextColor(Color.parseColor(textHex));
        btn.setTextSize(10f);
        if (bold) {
            btn.setTypeface(Typeface.DEFAULT_BOLD);
        }
        btn.setPadding(dp(7), dp(6.5f), dp(7), dp(6.5f));

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor(bgHex));
        bg.setCornerRadius(dp(10));
        if (!"#FF6B00".equalsIgnoreCase(bgHex)) {
            bg.setStroke(dp(1), Color.parseColor("#2A2F3D"));
        }
        btn.setBackground(bg);
        return btn;
    }

    private void clampPositionToSafeScreenBounds() {
        DisplayMetrics dm = getResources().getDisplayMetrics();
        int minX = dp(8);
        int maxX = Math.max(minX, dm.widthPixels - dp(125));
        int minY = dp(48);
        int maxY = Math.max(minY, dm.heightPixels - dp(120));

        if (params.x < minX) params.x = minX;
        if (params.x > maxX) params.x = maxX;
        if (params.y < minY) params.y = minY;
        if (params.y > maxY) params.y = maxY;
    }

    private void snapToNearestHorizontalEdge() {
        DisplayMetrics dm = getResources().getDisplayMetrics();
        int centerX = dm.widthPixels / 2;
        params.x = (params.x < centerX) ? dp(12) : Math.max(dp(12), dm.widthPixels - dp(130));
        clampPositionToSafeScreenBounds();
        if (windowManager != null && rootLayout != null) {
            windowManager.updateViewLayout(rootLayout, params);
        }
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putInt(KEY_POS_X, params.x)
                .putInt(KEY_POS_Y, params.y)
                .apply();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if (params != null && windowManager != null && rootLayout != null) {
            clampPositionToSafeScreenBounds();
            windowManager.updateViewLayout(rootLayout, params);
        }
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
        setLiveCameraHudVisible(false);
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(telemetryReceiver);
            LocalBroadcastManager.getInstance(this).unregisterReceiver(vcamSyncReceiver);
        } catch (Exception ignored) {
        }
        if (rootLayout != null && windowManager != null) {
            try {
                windowManager.removeView(rootLayout);
            } catch (Exception ignored) {
            }
        }
    }

    private static class NOrangeEmblemView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF arcRect = new RectF();
        private final Path leafPath = new Path();

        public NOrangeEmblemView(Context context) {
            super(context);
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            float cx = w * 0.5f;
            float cy = h * 0.54f;
            float r = Math.min(w, h) * 0.38f;

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, r * 0.14f));
            paint.setColor(Color.parseColor("#FF6B00"));
            canvas.drawCircle(cx, cy, r, paint);

            paint.setStyle(Paint.Style.FILL);
            float segR = r * 0.76f;
            arcRect.set(cx - segR, cy - segR, cx + segR, cy + segR);
            for (int i = 0; i < 6; i++) {
                paint.setColor(i == 0 ? Color.parseColor("#FF9E44") : Color.parseColor("#FF6B00"));
                canvas.drawArc(arcRect, -54f + i * 60f, 44f, true, paint);
            }

            paint.setColor(Color.parseColor("#08090C"));
            canvas.drawCircle(cx, cy, r * 0.22f, paint);

            paint.setColor(Color.parseColor("#FFA14A"));
            leafPath.reset();
            leafPath.moveTo(cx + r * 0.05f, cy - r * 1.05f);
            leafPath.quadTo(cx + r * 0.35f, cy - r * 1.38f, cx + r * 0.72f, cy - r * 1.22f);
            leafPath.quadTo(cx + r * 0.45f, cy - r * 0.92f, cx + r * 0.05f, cy - r * 1.05f);
            leafPath.close();
            canvas.drawPath(leafPath, paint);
        }
    }

    private static class NOrangeIconView extends View {
        static final int TYPE_SHIELD = 1;
        static final int TYPE_GPS = 2;
        static final int TYPE_CAMERA = 3;

        private final int type;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private final RectF rect = new RectF();

        public NOrangeIconView(Context context, int type) {
            super(context);
            this.type = type;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, w * 0.10f));
            paint.setColor(Color.parseColor("#FF8833"));

            if (type == TYPE_SHIELD) {
                path.reset();
                path.moveTo(w * 0.5f, h * 0.12f);
                path.lineTo(w * 0.85f, h * 0.26f);
                path.lineTo(w * 0.85f, h * 0.55f);
                path.quadTo(w * 0.85f, h * 0.82f, w * 0.5f, h * 0.92f);
                path.quadTo(w * 0.15f, h * 0.82f, w * 0.15f, h * 0.55f);
                path.lineTo(w * 0.15f, h * 0.26f);
                path.close();
                canvas.drawPath(path, paint);
            } else if (type == TYPE_GPS) {
                float cx = w * 0.5f;
                float cy = h * 0.5f;
                float r = w * 0.30f;
                canvas.drawCircle(cx, cy, r, paint);
                canvas.drawLine(cx, h * 0.08f, cx, h * 0.24f, paint);
                canvas.drawLine(cx, h * 0.76f, cx, h * 0.92f, paint);
                canvas.drawLine(w * 0.08f, cy, w * 0.24f, cy, paint);
                canvas.drawLine(w * 0.76f, cy, w * 0.92f, cy, paint);
            } else if (type == TYPE_CAMERA) {
                rect.set(w * 0.12f, h * 0.26f, w * 0.88f, h * 0.82f);
                canvas.drawRoundRect(rect, w * 0.14f, w * 0.14f, paint);
                canvas.drawCircle(w * 0.5f, h * 0.54f, w * 0.16f, paint);
            }
        }
    }
}
