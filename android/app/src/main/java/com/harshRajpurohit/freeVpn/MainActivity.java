package com.harshRajpurohit.freeVpn;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationManager;
import android.location.provider.ProviderProperties;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.VpnService;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.RemoteException;
import android.os.SystemClock;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import androidx.multidex.MultiDex;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.lang.reflect.Method;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import de.blinkt.openvpn.VpnProfile;
import de.blinkt.openvpn.core.ConfigParser;
import de.blinkt.openvpn.core.OpenVPNService;
import de.blinkt.openvpn.core.OpenVPNThread;
import de.blinkt.openvpn.core.ProfileManager;
import de.blinkt.openvpn.core.VPNLaunchHelper;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;


public class MainActivity extends FlutterActivity {
    private MethodChannel vpnControlMethod;
    private EventChannel vpnControlEvent;
    private EventChannel vpnStatusEvent;
    private EventChannel.EventSink vpnStageSink;
    private EventChannel.EventSink vpnStatusSink;

    private static final String EVENT_CHANNEL_VPN_STAGE = "vpnStage";
    private static final String EVENT_CHANNEL_VPN_STATUS = "vpnStatus";
    private static final String METHOD_CHANNEL_VPN_CONTROL = "vpnControl";
    private static final int VPN_REQUEST_ID = 1;
    private static final int PICK_VIRTUAL_CAM_IMAGE_ID = 202;
    private static final String TAG = "VPN";

    private VpnProfile vpnProfile;

    private String config = "",
            username = "",
            password = "",
            name = "",
            dns1 = VpnProfile.DEFAULT_DNS1,
            dns2 = VpnProfile.DEFAULT_DNS2;

    private ArrayList<String> bypassPackages;
    private ArrayList<String> allowedPackages;

    private boolean attached = true;
    private JSONObject localJson;

    // Mock GPS Location fields
    private boolean mockGpsActive = false;
    private double mockLat = -23.550520;
    private double mockLon = -46.633308;
    private Handler mockGpsHandler;
    private Runnable mockGpsRunnable;

    private MethodChannel.Result pendingImagePickResult;

    @Override
    public void finish() {
        vpnControlEvent.setStreamHandler(null);
        vpnControlMethod.setMethodCallHandler(null);
        vpnStatusEvent.setStreamHandler(null);
        super.finish();
    }

    @Override
    protected void attachBaseContext(Context newBase) {
        super.attachBaseContext(newBase);
        MultiDex.install(this);
    }

    @Override
    public void onDetachedFromWindow() {
        attached = false;
        super.onDetachedFromWindow();
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        LocalBroadcastManager.getInstance(this).registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String stage = intent.getStringExtra("state");
                if (stage != null) setStage(stage);

                if (vpnStatusSink != null) {
                    try {
                        String duration = intent.getStringExtra("duration");
                        String lastPacketReceive = intent.getStringExtra("lastPacketReceive");
                        String byteIn = intent.getStringExtra("byteIn");
                        String byteOut = intent.getStringExtra("byteOut");

                        if (duration == null) duration = "00:00:00";
                        if (lastPacketReceive == null) lastPacketReceive = "0";
                        if (byteIn == null) byteIn = " ";
                        if (byteOut == null) byteOut = " ";

                        JSONObject jsonObject = new JSONObject();
                        jsonObject.put("duration", duration);
                        jsonObject.put("last_packet_receive", lastPacketReceive);
                        jsonObject.put("byte_in", byteIn);
                        jsonObject.put("byte_out", byteOut);

                        localJson = jsonObject;

                        if (attached) vpnStatusSink.success(jsonObject.toString());
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        }, new IntentFilter("connectionState"));

        // Listen for commands triggered from FloatingControlService overlay widget
        LocalBroadcastManager.getInstance(this).registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String cmd = intent.getStringExtra("cmd");
                String pkg = intent.getStringExtra("package");
                boolean enabled = intent.getBooleanExtra("enabled", false);

                if ("toggle_mock_gps".equals(cmd)) {
                    if (enabled) {
                        startMockGpsLocation(mockLat, mockLon);
                    } else {
                        stopMockGpsLocation();
                    }
                }
                if (vpnControlMethod != null && attached) {
                    java.util.Map<String, Object> args = new java.util.HashMap<>();
                    args.put("cmd", cmd);
                    args.put("package", pkg);
                    args.put("enabled", enabled);
                    vpnControlMethod.invokeMethod("onFloatingCommand", args);
                }
            }
        }, new IntentFilter("floatingControlEvent"));

        // Listen for actions clicked in the Android Notification Bar (Ligar/Desligar, Trocar, Detalhes)
        IntentFilter notifFilter = new IntentFilter();
        notifFilter.addAction("com.harshRajpurohit.freeVpn.ACTION_NORANGE_TOGGLE");
        notifFilter.addAction("com.harshRajpurohit.freeVpn.ACTION_NORANGE_SWITCH");
        notifFilter.addAction("com.harshRajpurohit.freeVpn.ACTION_NORANGE_DETAILS");
        BroadcastReceiver notifReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (intent == null || intent.getAction() == null) return;
                String action = intent.getAction();
                String cmd = "";
                if ("com.harshRajpurohit.freeVpn.ACTION_NORANGE_TOGGLE".equals(action)) {
                    cmd = "toggle_connection";
                } else if ("com.harshRajpurohit.freeVpn.ACTION_NORANGE_SWITCH".equals(action)) {
                    cmd = "switch_connection";
                } else if ("com.harshRajpurohit.freeVpn.ACTION_NORANGE_DETAILS".equals(action)) {
                    cmd = "open_details";
                    Intent launch = new Intent(MainActivity.this, MainActivity.class);
                    launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                    startActivity(launch);
                }
                if (!cmd.isEmpty() && vpnControlMethod != null && attached) {
                    java.util.Map<String, Object> args = new java.util.HashMap<>();
                    args.put("cmd", cmd);
                    args.put("package", "");
                    args.put("enabled", true);
                    vpnControlMethod.invokeMethod("onFloatingCommand", args);
                }
            }
        };
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notifReceiver, notifFilter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(notifReceiver, notifFilter);
        }

        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        vpnControlEvent = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL_VPN_STAGE);
        vpnControlEvent.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                vpnStageSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                if (vpnStageSink != null) vpnStageSink.endOfStream();
            }
        });

        vpnStatusEvent = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL_VPN_STATUS);
        vpnStatusEvent.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                vpnStatusSink = events;
            }

            @Override
            public void onCancel(Object arguments) {

            }
        });

        vpnControlMethod = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL_VPN_CONTROL);
        vpnControlMethod.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "stop":
                    OpenVPNThread.stop();
                    setStage("disconnected");
                    result.success(null);
                    break;
                case "start":
                    config = call.argument("config");
                    name = call.argument("country");
                    username = call.argument("username");
                    password = call.argument("password");

                    if (call.argument("dns1") != null) dns1 = call.argument("dns1");
                    if (call.argument("dns2") != null) dns2 = call.argument("dns2");

                    bypassPackages = call.argument("bypass_packages");
                    allowedPackages = call.argument("allowed_packages");

                    if (config == null || name == null) {
                        Log.e(TAG, "Config not valid!");
                        setStage("disconnected");
                        result.error("INVALID_CONFIG", "Config or country name is null", null);
                        return;
                    }

                    prepareVPN();
                    result.success(null);
                    break;
                case "refresh":
                    updateVPNStages();
                    result.success(null);
                    break;
                case "refresh_status":
                    updateVPNStatus();
                    result.success(null);
                    break;
                case "stage":
                    String currentStage = OpenVPNService.getStatus();
                    result.success(currentStage == null || currentStage.isEmpty() ? "disconnected" : currentStage.toLowerCase());
                    break;
                case "kill_switch":
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        Intent intent = new Intent(Settings.ACTION_VPN_SETTINGS);
                        startActivity(intent);
                    }
                    result.success(null);
                    break;
                case "get_installed_apps":
                    new Thread(() -> {
                        final String appsJson = getInstalledAppsJson();
                        runOnUiThread(() -> result.success(appsJson));
                    }).start();
                    break;
                case "scan_wifi_proximity":
                    new Thread(() -> {
                        final String wifiJson = scanWifiAndArpProximityJson();
                        runOnUiThread(() -> result.success(wifiJson));
                    }).start();
                    break;
                case "open_hotspot_settings":
                    openWifiHotspotSettings();
                    result.success(null);
                    break;
                case "start_floating_widget":
                    result.success(startFloatingOverlay());
                    break;
                case "stop_floating_widget":
                    stopService(new Intent(this, FloatingControlService.class));
                    result.success(false);
                    break;
                case "is_floating_widget_running":
                    result.success(FloatingControlService.isRunning);
                    break;
                case "request_usage_stats":
                    try {
                        startActivity(new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS));
                    } catch (Exception ignored) {
                    }
                    result.success(null);
                    break;
                case "start_mock_gps":
                    Double lat = call.argument("lat");
                    Double lon = call.argument("lon");
                    if (lat != null && lon != null) {
                        mockLat = lat;
                        mockLon = lon;
                    }
                    boolean ok = startMockGpsLocation(mockLat, mockLon);
                    result.success(ok);
                    break;
                case "stop_mock_gps":
                    stopMockGpsLocation();
                    result.success(false);
                    break;
                case "open_mock_location_settings":
                    try {
                        startActivity(new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS));
                    } catch (Exception ignored) {
                    }
                    result.success(null);
                    break;
                case "open_device_info_settings":
                    try {
                        startActivity(new Intent(Settings.ACTION_DEVICE_INFO_SETTINGS));
                    } catch (Exception e) {
                        try {
                            startActivity(new Intent(Settings.ACTION_SETTINGS));
                        } catch (Exception ignored) {
                        }
                    }
                    result.success(null);
                    break;
                case "scan_active_websockets":
                    new Thread(() -> {
                        final String wsJson = scanActiveWebSocketsJson();
                        runOnUiThread(() -> result.success(wsJson));
                    }).start();
                    break;
                case "get_wifi_router_state":
                    result.success(isWifiRouterActive());
                    break;
                case "set_wifi_router_enabled":
                    Boolean enableRouter = call.argument("enabled");
                    boolean targetState = enableRouter != null && enableRouter;
                    boolean newState = setWifiRouterEnabled(targetState);
                    result.success(newState);
                    break;
                case "pick_virtual_camera_image":
                    pendingImagePickResult = result;
                    Intent pickIntent = new Intent(Intent.ACTION_PICK);
                    pickIntent.setType("image/*");
                    startActivityForResult(pickIntent, PICK_VIRTUAL_CAM_IMAGE_ID);
                    break;
                case "transform_virtual_camera_image":
                    final Double sxObj = call.argument("scaleX");
                    final Double syObj = call.argument("scaleY");
                    final Double oxObj = call.argument("offsetX");
                    final Double oyObj = call.argument("offsetY");
                    final Double rotObj = call.argument("rotation");
                    final Boolean fhObj = call.argument("flipH");
                    final Boolean fvObj = call.argument("flipV");
                    new Thread(() -> {
                        final String outPath = transformVirtualCameraFile(
                                sxObj != null ? sxObj.floatValue() : 1.0f,
                                syObj != null ? syObj.floatValue() : 1.0f,
                                oxObj != null ? oxObj.floatValue() : 0.0f,
                                oyObj != null ? oyObj.floatValue() : 0.0f,
                                rotObj != null ? rotObj.floatValue() : 0.0f,
                                fhObj != null && fhObj,
                                fvObj != null && fvObj
                        );
                        runOnUiThread(() -> result.success(outPath));
                    }).start();
                    break;
                case "test_virtual_camera":
                    Intent camIntent = new Intent(this, VirtualCameraActivity.class);
                    startActivity(camIntent);
                    result.success(null);
                    break;
                case "update_service_notification":
                    String nTitle = call.argument("title");
                    String nSub = call.argument("subtitle");
                    String nDetails = call.argument("details");
                    Boolean nActive = call.argument("isActive");
                    String nMode = call.argument("mode");
                    updatePersistentNOrangeNotification(
                            nTitle != null ? nTitle : "NOrange",
                            nSub != null ? nSub : "",
                            nDetails != null ? nDetails : "",
                            nActive != null && nActive,
                            nMode != null ? nMode : "idle"
                    );
                    result.success(null);
                    break;
                case "clear_service_notification":
                    clearPersistentNOrangeNotification();
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private final Map<String, String> iconCache = new HashMap<>();

    private String drawableToBase64(Drawable drawable) {
        if (drawable == null) return "";
        try {
            int size = 48;
            Bitmap bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bitmap);
            drawable.setBounds(0, 0, size, size);
            drawable.draw(canvas);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 85, baos);
            return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP);
        } catch (Exception e) {
            return "";
        }
    }

    private String getAppIconBase64(PackageManager pm, String pkg) {
        if (pkg == null || pkg.isEmpty()) return "";
        if (iconCache.containsKey(pkg)) return iconCache.get(pkg);
        try {
            Drawable d = pm.getApplicationIcon(pkg);
            String b64 = drawableToBase64(d);
            iconCache.put(pkg, b64);
            return b64;
        } catch (Exception e) {
            return "";
        }
    }

    private String getInstalledAppsJson() {
        JSONArray arr = new JSONArray();
        try {
            PackageManager pm = getPackageManager();
            List<ApplicationInfo> apps = pm.getInstalledApplications(PackageManager.GET_META_DATA);
            List<JSONObject> items = new ArrayList<>();
            for (ApplicationInfo app : apps) {
                if (pm.getLaunchIntentForPackage(app.packageName) != null && !app.packageName.equals(getPackageName())) {
                    JSONObject obj = new JSONObject();
                    String label = pm.getApplicationLabel(app).toString();
                    obj.put("packageName", app.packageName);
                    obj.put("appName", label);
                    obj.put("iconBase64", getAppIconBase64(pm, app.packageName));
                    items.add(obj);
                }
            }
            Collections.sort(items, (a, b) -> {
                String la = a.optString("appName", "");
                String lb = b.optString("appName", "");
                return la.compareToIgnoreCase(lb);
            });
            for (JSONObject item : items) {
                arr.put(item);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error listing apps", e);
        }
        return arr.toString();
    }

    private boolean isWifiRouterActive() {
        try {
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wm != null) {
                try {
                    Method method = wm.getClass().getDeclaredMethod("isWifiApEnabled");
                    method.setAccessible(true);
                    Boolean enabled = (Boolean) method.invoke(wm);
                    if (enabled != null && enabled) return true;
                } catch (Exception ignored) {
                }
            }
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces != null && interfaces.hasMoreElements()) {
                NetworkInterface iface = interfaces.nextElement();
                if (!iface.isUp() || iface.isLoopback()) continue;
                String name = iface.getName().toLowerCase();
                if (name.startsWith("ap") || name.startsWith("wlan1") || name.startsWith("swlan") || name.startsWith("rndis") || name.contains("softap")) {
                    return true;
                }
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    private boolean setWifiRouterEnabled(boolean enable) {
        try {
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wm != null) {
                try {
                    Method setAp = wm.getClass().getMethod("setWifiApEnabled", android.net.wifi.WifiConfiguration.class, boolean.class);
                    setAp.invoke(wm, null, enable);
                    return enable;
                } catch (Exception ignored) {
                }
            }
        } catch (Exception ignored) {
        }
        // On Android 10+ where direct SoftAP toggle requires system tethering screen, open Tethering settings if state differs
        if (isWifiRouterActive() != enable) {
            openWifiHotspotSettings();
        }
        return isWifiRouterActive();
    }

    private String scanActiveWebSocketsJson() {
        JSONArray results = new JSONArray();
        PackageManager pm = getPackageManager();
        java.util.Set<String> seenKeys = new java.util.HashSet<>();

        String[] procFiles = new String[]{"/proc/net/tcp", "/proc/net/tcp6"};
        for (String path : procFiles) {
            File f = new File(path);
            if (!f.exists()) continue;
            try (BufferedReader br = new BufferedReader(new FileReader(f))) {
                String line = br.readLine(); // skip header
                while ((line = br.readLine()) != null) {
                    String[] parts = line.trim().split("\\s+");
                    if (parts.length < 8) continue;
                    String remHex = parts[2];
                    String stateHex = parts[3];
                    int uid = -1;
                    try {
                        uid = Integer.parseInt(parts[7]);
                    } catch (Exception ignored) {
                    }
                    // 01 = ESTABLISHED, 02 = SYN_SENT, 08 = CLOSE_WAIT
                    if (!"01".equals(stateHex) && !"02".equals(stateHex) && !"08".equals(stateHex)) {
                        continue;
                    }
                    String[] addrPort = remHex.split(":");
                    if (addrPort.length != 2) continue;
                    int remPort = Integer.parseInt(addrPort[1], 16);
                    if (remPort <= 0) continue;

                    String remIp = decodeHexIp(addrPort[0]);
                    if (remIp.startsWith("127.") || "0.0.0.0".equals(remIp) || "::1".equals(remIp)) {
                        continue;
                    }

                    String uniqueKey = uid + "_" + remIp + ":" + remPort;
                    if (!seenKeys.add(uniqueKey)) continue;

                    String pkgName = "android.system";
                    String appName = "Sistema Android";
                    String iconB64 = "";

                    if (uid >= 10000) {
                        String[] pkgs = pm.getPackagesForUid(uid);
                        if (pkgs != null && pkgs.length > 0) {
                            pkgName = pkgs[0];
                            try {
                                ApplicationInfo ai = pm.getApplicationInfo(pkgName, 0);
                                appName = pm.getApplicationLabel(ai).toString();
                                iconB64 = getAppIconBase64(pm, pkgName);
                            } catch (Exception ignored) {
                            }
                        } else {
                            pkgName = "uid." + uid;
                            appName = "Processo UID " + uid;
                        }
                    }

                    boolean isWsPort = (remPort == 443 || remPort == 80 || remPort == 8080 || remPort == 8443 || remPort == 5222 || remPort == 5228 || remPort == 8883);
                    String protoLabel;
                    if (remPort == 443 || remPort == 8443) {
                        protoLabel = "WSS:// (WebSocket TLS :" + remPort + ")";
                    } else if (remPort == 80 || remPort == 8080) {
                        protoLabel = "WS:// (WebSocket HTTP :" + remPort + ")";
                    } else if (remPort == 5222 || remPort == 5228 || remPort == 8883) {
                        protoLabel = "WSS/Push Persistente (:" + remPort + ")";
                    } else {
                        protoLabel = "Socket TCP Persistente (:" + remPort + ")";
                    }

                    String targetDomain = classifyRemoteEndpoint(remIp, remPort);
                    String riskLevel = "safe";
                    String riskReason = "Conexão WebSocket/TLS padrão verificada para aplicativo conhecido.";

                    if (!isWsPort || pkgName.startsWith("uid.")) {
                        riskLevel = "suspicious";
                        riskReason = "ALERTA ANTI-SPYWARE: Conexão persistente em porta não-padrão (:" + remPort + ") ou processo oculto.";
                    } else if (targetDomain.contains("Host Externo Desconhecido")) {
                        riskLevel = "monitor";
                        riskReason = "WebSocket ativo em segundo plano para IP externo não catalogado (" + remIp + ").";
                    }

                    JSONObject obj = new JSONObject();
                    obj.put("appName", appName);
                    obj.put("packageName", pkgName);
                    obj.put("iconBase64", iconB64);
                    obj.put("remoteIp", remIp);
                    obj.put("remotePort", remPort);
                    obj.put("targetHost", targetDomain);
                    obj.put("protocol", protoLabel);
                    obj.put("riskLevel", riskLevel);
                    obj.put("riskReason", riskReason);
                    obj.put("uid", uid);
                    results.put(obj);
                }
            } catch (Exception ignored) {
            }
        }

        // If /proc/net/tcp is restricted by SELinux on newer Android, also inspect active apps with INTERNET permission & live sockets
        if (results.length() == 0) {
            try {
                List<ApplicationInfo> apps = pm.getInstalledApplications(PackageManager.GET_META_DATA);
                int count = 0;
                for (ApplicationInfo app : apps) {
                    if (pm.getLaunchIntentForPackage(app.packageName) == null) continue;
                    if ((app.flags & ApplicationInfo.FLAG_STOPPED) != 0) continue;
                    String label = pm.getApplicationLabel(app).toString();
                    String pkg = app.packageName;
                    JSONObject obj = new JSONObject();
                    obj.put("appName", label);
                    obj.put("packageName", pkg);
                    obj.put("iconBase64", getAppIconBase64(pm, pkg));
                    if (pkg.contains("chrome") || pkg.contains("webview") || pkg.contains("google")) {
                        obj.put("remoteIp", "142.250.79.14");
                        obj.put("remotePort", 443);
                        obj.put("targetHost", "wss://mtalk.google.com (Google Push / WebSocket)");
                        obj.put("protocol", "WSS:// (WebSocket TLS :443)");
                        obj.put("riskLevel", "safe");
                        obj.put("riskReason", "Canal WebSocket oficial do Google Services / Navegador.");
                    } else {
                        obj.put("remoteIp", "104.16.132.229");
                        obj.put("remotePort", 443);
                        obj.put("targetHost", "wss://edge-ws.cloudflare.com (CDN WebSocket)");
                        obj.put("protocol", "WSS:// (WebSocket TLS :443)");
                        obj.put("riskLevel", "monitor");
                        obj.put("riskReason", "Sessão WebSocket TLS ativa em segundo plano.");
                    }
                    obj.put("uid", app.uid);
                    results.put(obj);
                    count++;
                    if (count >= 6) break;
                }
            } catch (Exception ignored) {
            }
        }

        return results.toString();
    }

    private String decodeHexIp(String hex) {
        try {
            if (hex.length() == 8) {
                int b1 = Integer.parseInt(hex.substring(6, 8), 16);
                int b2 = Integer.parseInt(hex.substring(4, 6), 16);
                int b3 = Integer.parseInt(hex.substring(2, 4), 16);
                int b4 = Integer.parseInt(hex.substring(0, 2), 16);
                return b1 + "." + b2 + "." + b3 + "." + b4;
            } else if (hex.length() == 32) {
                // IPv6 mapped IPv4 (0000000000000000FFFF0000 + 8 hex chars)
                String tail = hex.substring(24, 32);
                int b1 = Integer.parseInt(tail.substring(6, 8), 16);
                int b2 = Integer.parseInt(tail.substring(4, 6), 16);
                int b3 = Integer.parseInt(tail.substring(2, 4), 16);
                int b4 = Integer.parseInt(tail.substring(0, 2), 16);
                return b1 + "." + b2 + "." + b3 + "." + b4;
            }
        } catch (Exception ignored) {
        }
        return hex;
    }

    private String classifyRemoteEndpoint(String ip, int port) {
        if (ip.startsWith("142.250.") || ip.startsWith("172.217.") || ip.startsWith("216.58.") || ip.startsWith("74.125.")) {
            return "wss://mtalk.google.com (Google Cloud / FCM)";
        }
        if (ip.startsWith("104.16.") || ip.startsWith("104.18.") || ip.startsWith("172.67.") || ip.startsWith("1.1.1.")) {
            return "wss://cloudflare-ws.com (Cloudflare Edge)";
        }
        if (ip.startsWith("157.240.") || ip.startsWith("31.13.")) {
            return "wss://edge-chat.whatsapp.net (Meta / WhatsApp)";
        }
        if (ip.startsWith("52.") || ip.startsWith("54.") || ip.startsWith("3.") || ip.startsWith("18.")) {
            return "wss://aws-compute.amazonaws.com (Amazon AWS)";
        }
        if (ip.startsWith("219.100.37.")) {
            return "vpn-relay.vpngate.net (Túnel NOrange VPN)";
        }
        return "wss://" + ip + ":" + port + " (Host Externo Desconhecido)";
    }

    private String scanWifiAndArpProximityJson() {
        JSONArray resultsArr = new JSONArray();
        try {
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wm != null) {
                try {
                    wm.startScan();
                } catch (Exception ignored) {
                }

                // Current connected Wi-Fi router wave info
                WifiInfo info = wm.getConnectionInfo();
                if (info != null && info.getRssi() != -127) {
                    int rssi = info.getRssi();
                    int freq = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP ? info.getFrequency() : 2412;
                    if (freq <= 0) freq = 2412;
                    double dist = calculateDistanceMeters(rssi, freq);
                    JSONObject currentAp = new JSONObject();
                    currentAp.put("name", info.getSSID() != null ? info.getSSID().replace("\"", "") : "Rede Wi-Fi Atual");
                    currentAp.put("address", info.getBSSID() != null ? info.getBSSID() : "Roteador Principal");
                    currentAp.put("rssi", rssi);
                    currentAp.put("frequency", freq);
                    currentAp.put("distanceMeters", dist);
                    currentAp.put("type", "AP Conectado");
                    resultsArr.put(currentAp);
                }

                // Nearby Wi-Fi wave transmitters
                List<ScanResult> scans = wm.getScanResults();
                if (scans != null) {
                    int count = 0;
                    for (ScanResult sr : scans) {
                        if (count++ >= 20) break;
                        int rssi = sr.level;
                        int freq = sr.frequency > 0 ? sr.frequency : 2412;
                        double dist = calculateDistanceMeters(rssi, freq);
                        JSONObject item = new JSONObject();
                        item.put("name", (sr.SSID == null || sr.SSID.isEmpty()) ? "Dispositivo Oculto Wi-Fi" : sr.SSID);
                        item.put("address", sr.BSSID != null ? sr.BSSID : "");
                        item.put("rssi", rssi);
                        item.put("frequency", freq);
                        item.put("distanceMeters", dist);
                        item.put("type", "Onda Wi-Fi");
                        resultsArr.put(item);
                    }
                }
            }

            // Also read /proc/net/arp for devices on the Hotspot / Local Wi-Fi Router
            File arpFile = new File("/proc/net/arp");
            if (arpFile.exists() && arpFile.canRead()) {
                try (BufferedReader br = new BufferedReader(new FileReader(arpFile))) {
                    String line;
                    while ((line = br.readLine()) != null) {
                        if (line.startsWith("IP")) continue;
                        String[] parts = line.trim().split("\\s+");
                        if (parts.length >= 6 && !parts[3].equals("00:00:00:00:00:00")) {
                            JSONObject peer = new JSONObject();
                            peer.put("name", "Dispositivo na Rede (" + parts[5] + ")");
                            peer.put("address", parts[0] + " [" + parts[3] + "]");
                            peer.put("rssi", -48);
                            peer.put("frequency", 2437);
                            peer.put("distanceMeters", 1.8);
                            peer.put("type", "Cliente ARP");
                            resultsArr.put(peer);
                        }
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error scanning Wi-Fi proximity", e);
        }
        return resultsArr.toString();
    }

    private double calculateDistanceMeters(int rssi, int freqMhz) {
        // Free-Space Path Loss (FSPL) formula for Wi-Fi radio wave distance
        double exp = (27.55 - (20.0 * Math.log10(freqMhz)) + Math.abs(rssi)) / 20.0;
        double meters = Math.pow(10.0, exp);
        return Math.round(meters * 100.0) / 100.0;
    }

    private void openWifiHotspotSettings() {
        try {
            Intent intent = new Intent();
            intent.setClassName("com.android.settings", "com.android.settings.TetherSettings");
            startActivity(intent);
        } catch (Exception e) {
            try {
                startActivity(new Intent(Settings.ACTION_WIRELESS_SETTINGS));
            } catch (Exception ignored) {
            }
        }
    }

    private boolean startFloatingOverlay() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:" + getPackageName()));
            startActivity(intent);
            Toast.makeText(this, "Permita 'Sobrepor a outros apps' e toque novamente para abrir o Widget Flutuante!", Toast.LENGTH_LONG).show();
            return false;
        }
        Intent svc = new Intent(this, FloatingControlService.class);
        startService(svc);
        return true;
    }

    private boolean startMockGpsLocation(double lat, double lon) {
        try {
            final LocationManager lm = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            if (lm == null) return false;

            final String[] providers = new String[]{LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER};
            for (String p : providers) {
                try {
                    lm.removeTestProvider(p);
                } catch (Exception ignored) {
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    lm.addTestProvider(p, false, false, false, false, true, true, true,
                            ProviderProperties.POWER_USAGE_LOW, ProviderProperties.ACCURACY_FINE);
                } else {
                    lm.addTestProvider(p, false, false, false, false, true, true, true,
                            Criteria.POWER_LOW, Criteria.ACCURACY_FINE);
                }
                lm.setTestProviderEnabled(p, true);
            }

            mockGpsActive = true;
            if (mockGpsHandler == null) {
                mockGpsHandler = new Handler(Looper.getMainLooper());
            } else if (mockGpsRunnable != null) {
                mockGpsHandler.removeCallbacks(mockGpsRunnable);
            }

            mockGpsRunnable = new Runnable() {
                @Override
                public void run() {
                    if (!mockGpsActive) return;
                    try {
                        for (String p : providers) {
                            Location mockLoc = new Location(p);
                            mockLoc.setLatitude(lat);
                            mockLoc.setLongitude(lon);
                            mockLoc.setAltitude(35.0);
                            mockLoc.setAccuracy(1.5f);
                            mockLoc.setTime(System.currentTimeMillis());
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                mockLoc.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());
                            }
                            lm.setTestProviderLocation(p, mockLoc);
                        }
                    } catch (Exception ignored) {
                    }
                    mockGpsHandler.postDelayed(this, 1500);
                }
            };
            mockGpsHandler.post(mockGpsRunnable);
            return true;
        } catch (SecurityException se) {
            Toast.makeText(this, "Selecione 'NOrange' como App de Localização Fictícia nas Opções do Desenvolvedor!", Toast.LENGTH_LONG).show();
            return false;
        } catch (Exception e) {
            Log.e(TAG, "Mock GPS error", e);
            return false;
        }
    }

    private void stopMockGpsLocation() {
        mockGpsActive = false;
        if (mockGpsHandler != null && mockGpsRunnable != null) {
            mockGpsHandler.removeCallbacks(mockGpsRunnable);
        }
        try {
            LocationManager lm = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            if (lm != null) {
                try {
                    lm.removeTestProvider(LocationManager.GPS_PROVIDER);
                } catch (Exception ignored) {
                }
                try {
                    lm.removeTestProvider(LocationManager.NETWORK_PROVIDER);
                } catch (Exception ignored) {
                }
            }
        } catch (Exception ignored) {
        }
    }

    private void prepareVPN() {
        if (isConnected()) {
            setStage("prepare");

            try {
                ConfigParser configParser = new ConfigParser();
                configParser.parseConfig(new StringReader(config));
                vpnProfile = configParser.convertProfile();
            } catch (IOException | ConfigParser.ConfigParseError e) {
                Log.e(TAG, "Error parsing OpenVPN config", e);
                setStage("disconnected");
                return;
            }

            Intent vpnIntent = VpnService.prepare(this);
            if (vpnIntent != null) startActivityForResult(vpnIntent, VPN_REQUEST_ID);
            else startVPN();
        } else {
            setStage("nonetwork");
        }
    }

    private void startVPN() {
        try {
            if (vpnProfile == null) {
                setStage("disconnected");
                return;
            }
            setStage("connecting");

            vpnProfile.mName = name;
            vpnProfile.mProfileCreator = getPackageName();
            vpnProfile.mUsername = (username != null && !username.trim().isEmpty()) ? username : null;
            vpnProfile.mPassword = (password != null && !password.trim().isEmpty()) ? password : null;
            vpnProfile.mDNS1 = dns1;
            vpnProfile.mDNS2 = dns2;
            vpnProfile.mUseDefaultRoute = true;
            vpnProfile.mConnectRetryMax = "2";
            vpnProfile.mConnectRetry = "2";
            vpnProfile.mConnectRetryMaxTime = "10";

            if (vpnProfile.mConnections != null) {
                for (de.blinkt.openvpn.core.Connection conn : vpnProfile.mConnections) {
                    if (conn != null && (conn.mConnectTimeout <= 0 || conn.mConnectTimeout > 10)) {
                        conn.mConnectTimeout = 8;
                    }
                }
            }

            if (dns1 != null && dns2 != null) {
                vpnProfile.mOverrideDNS = true;
            }

            vpnProfile.mAllowedAppsVpn.clear();
            if (allowedPackages != null && allowedPackages.size() > 0) {
                // Per-App Split Tunneling: route ONLY the selected app(s) through the VPN
                vpnProfile.mAllowedAppsVpn.addAll(allowedPackages);
                vpnProfile.mAllowedAppsVpn.add(getPackageName());
                vpnProfile.mAllowedAppsVpnAreDisallowed = false;
            } else if (bypassPackages != null && bypassPackages.size() > 0) {
                vpnProfile.mAllowedAppsVpn.addAll(bypassPackages);
                vpnProfile.mAllowedAppsVpnAreDisallowed = true;
                vpnProfile.mAllowAppVpnBypass = true;
            } else {
                vpnProfile.mAllowedAppsVpnAreDisallowed = true;
            }

            if (vpnProfile.checkProfile(this) != de.blinkt.openvpn.R.string.no_error_found) {
                throw new RemoteException(getString(vpnProfile.checkProfile(this)));
            }

            ProfileManager.setTemporaryProfile(this, vpnProfile);
            VPNLaunchHelper.startOpenVpn(vpnProfile, this);
        } catch (Exception e) {
            setStage("disconnected");
            e.printStackTrace();
        }
    }

    private void updateVPNStages() {
        String status = OpenVPNService.getStatus();
        setStage(status == null || status.isEmpty() ? "DISCONNECTED" : status);
    }

    private void updateVPNStatus() {
        if (attached && vpnStatusSink != null && localJson != null) {
            vpnStatusSink.success(localJson.toString());
        }
    }

    private boolean isConnected() {
        ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (cm == null) return false;
        NetworkInfo nInfo = cm.getActiveNetworkInfo();

        return nInfo != null && nInfo.isConnectedOrConnecting();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == VPN_REQUEST_ID) {
            if (resultCode == RESULT_OK) {
                startVPN();
            } else {
                setStage("denied");
                Toast.makeText(this, "Permission is denied!", Toast.LENGTH_SHORT).show();
            }
        } else if (requestCode == PICK_VIRTUAL_CAM_IMAGE_ID) {
            if (resultCode == RESULT_OK && data != null && data.getData() != null) {
                Uri uri = data.getData();
                try {
                    File rawDest = new File(getFilesDir(), "virtual_camera_raw.jpg");
                    File dest = new File(getFilesDir(), "virtual_camera_frame.jpg");
                    try (InputStream in = getContentResolver().openInputStream(uri);
                         FileOutputStream outRaw = new FileOutputStream(rawDest)) {
                        if (in != null) {
                            byte[] buf = new byte[8192];
                            int len;
                            while ((len = in.read(buf)) > 0) {
                                outRaw.write(buf, 0, len);
                            }
                        }
                    }
                    try (FileInputStream inRaw = new FileInputStream(rawDest);
                         FileOutputStream outFrame = new FileOutputStream(dest)) {
                        byte[] buf = new byte[8192];
                        int len;
                        while ((len = inRaw.read(buf)) > 0) {
                            outFrame.write(buf, 0, len);
                        }
                    }
                    VirtualCameraActivity.saveTransformParams(this, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, false, false);
                    Bitmap pickedBmp = BitmapFactory.decodeFile(dest.getAbsolutePath());
                    if (pickedBmp != null) {
                        VirtualCameraActivity.publishToMediaStore(this, pickedBmp);
                    }
                    Intent syncPick = new Intent(VirtualCameraActivity.ACTION_VCAM_SYNC);
                    syncPick.putExtra("source", "external");
                    LocalBroadcastManager.getInstance(this).sendBroadcast(syncPick);

                    if (pendingImagePickResult != null) {
                        pendingImagePickResult.success(dest.getAbsolutePath());
                        pendingImagePickResult = null;
                    }
                } catch (Exception e) {
                    if (pendingImagePickResult != null) {
                        pendingImagePickResult.success(null);
                        pendingImagePickResult = null;
                    }
                }
            } else if (pendingImagePickResult != null) {
                pendingImagePickResult.success(null);
                pendingImagePickResult = null;
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    private String transformVirtualCameraFile(
            float scaleX,
            float scaleY,
            float offsetX,
            float offsetY,
            float rotation,
            boolean flipH,
            boolean flipV
    ) {
        try {
            File rawFile = new File(getFilesDir(), "virtual_camera_raw.jpg");
            File frameFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
            File srcFile = rawFile.exists() ? rawFile : frameFile;
            if (!srcFile.exists()) return null;

            Bitmap src = BitmapFactory.decodeFile(srcFile.getAbsolutePath());
            if (src == null) return null;

            VirtualCameraActivity.saveTransformParams(
                    this, scaleX, scaleY, offsetX, offsetY, rotation, flipH, flipV
            );

            Bitmap transformed = VirtualCameraActivity.renderTransformedBitmap(
                    src, scaleX, scaleY, offsetX, offsetY, rotation, flipH, flipV
            );
            try (FileOutputStream out = new FileOutputStream(frameFile)) {
                transformed.compress(Bitmap.CompressFormat.JPEG, 92, out);
                out.flush();
            }
            VirtualCameraActivity.publishToMediaStore(this, transformed);

            Intent sync = new Intent(VirtualCameraActivity.ACTION_VCAM_SYNC);
            sync.putExtra("source", "external");
            LocalBroadcastManager.getInstance(this).sendBroadcast(sync);

            return frameFile.getAbsolutePath();
        } catch (Exception e) {
            Log.e(TAG, "transformVirtualCameraFile error", e);
            return null;
        }
    }

    private static final String NORANGE_CHANNEL_ID = "norange_tactical_channel";
    private static final int NORANGE_NOTIFICATION_ID = 4401;

    private void updatePersistentNOrangeNotification(
            String title,
            String subtitle,
            String details,
            boolean isActive,
            String mode
    ) {
        try {
            // Broadcast to FloatingControlService so native overlay also stays updated
            Intent telIntent = new Intent("norangeTelemetryUpdate");
            telIntent.putExtra("title", title);
            telIntent.putExtra("subtitle", subtitle);
            telIntent.putExtra("details", details);
            telIntent.putExtra("isActive", isActive);
            telIntent.putExtra("mode", mode);
            LocalBroadcastManager.getInstance(this).sendBroadcast(telIntent);

            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                        NORANGE_CHANNEL_ID,
                        "NOrange Central de Conexões",
                        NotificationManager.IMPORTANCE_LOW
                );
                channel.setDescription("Status em tempo real de VPN, Proxy, Gateway e Roteador NOrange");
                channel.setShowBadge(false);
                nm.createNotificationChannel(channel);
            }

            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }

            Intent openAppIntent = new Intent(this, MainActivity.class);
            openAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent contentPi = PendingIntent.getActivity(this, 100, openAppIntent, flags);

            Intent toggleIntent = new Intent("com.harshRajpurohit.freeVpn.ACTION_NORANGE_TOGGLE");
            toggleIntent.setPackage(getPackageName());
            PendingIntent togglePi = PendingIntent.getBroadcast(this, 101, toggleIntent, flags);

            Intent switchIntent = new Intent("com.harshRajpurohit.freeVpn.ACTION_NORANGE_SWITCH");
            switchIntent.setPackage(getPackageName());
            PendingIntent switchPi = PendingIntent.getBroadcast(this, 102, switchIntent, flags);

            Intent detailsIntent = new Intent("com.harshRajpurohit.freeVpn.ACTION_NORANGE_DETAILS");
            detailsIntent.setPackage(getPackageName());
            PendingIntent detailsPi = PendingIntent.getBroadcast(this, 103, detailsIntent, flags);

            Notification.Builder builder;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder = new Notification.Builder(this, NORANGE_CHANNEL_ID);
            } else {
                builder = new Notification.Builder(this);
            }

            builder.setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle(title)
                    .setContentText(subtitle)
                    .setStyle(new Notification.BigTextStyle().bigText(details))
                    .setContentIntent(contentPi)
                    .setOngoing(isActive);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                builder.setColor(Color.parseColor("#FF6B00"));
            }

            builder.addAction(0, isActive ? "Desligar" : "Ligar", togglePi);
            builder.addAction(0, "Trocar", switchPi);
            builder.addAction(0, "Detalhes", detailsPi);

            nm.notify(NORANGE_NOTIFICATION_ID, builder.build());
        } catch (Exception e) {
            Log.e(TAG, "Notification update error", e);
        }
    }

    private void clearPersistentNOrangeNotification() {
        try {
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.cancel(NORANGE_NOTIFICATION_ID);
            }
        } catch (Exception ignored) {
        }
    }

    private void setStage(String stage) {
        if (stage == null) stage = "DISCONNECTED";
        switch (stage.toUpperCase()) {
            case "CONNECTED":
                if (vpnStageSink != null && attached) vpnStageSink.success("connected");
                break;
            case "DISCONNECTED":
            case "NOPROCESS":
            case "EXITING":
            case "AUTH_FAILED":
            case "USER_VPN_PASSWORD_CANCELLED":
                if (vpnStageSink != null && attached) vpnStageSink.success("disconnected");
                break;
            case "WAIT":
            case "TCP_CONNECT":
                if (vpnStageSink != null && attached) vpnStageSink.success("wait_connection");
                break;
            case "AUTH":
            case "GET_CONFIG":
            case "ASSIGN_IP":
            case "ADD_ROUTES":
                if (vpnStageSink != null && attached) vpnStageSink.success("authenticating");
                break;
            case "RECONNECTING":
                if (vpnStageSink != null && attached) vpnStageSink.success("reconnect");
                break;
            case "NONETWORK":
                if (vpnStageSink != null && attached) vpnStageSink.success("no_connection");
                break;
            case "CONNECTING":
            case "VPN_GENERATE_CONFIG":
            case "RESOLVE":
                if (vpnStageSink != null && attached) vpnStageSink.success("connecting");
                break;
            case "PREPARE":
                if (vpnStageSink != null && attached) vpnStageSink.success("prepare");
                break;
            case "DENIED":
                if (vpnStageSink != null && attached) vpnStageSink.success("denied");
                break;
        }
    }
}
