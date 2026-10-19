package com.harshRajpurohit.freeVpn;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
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
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import androidx.multidex.MultiDex;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;

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
                case "pick_virtual_camera_image":
                    pendingImagePickResult = result;
                    Intent pickIntent = new Intent(Intent.ACTION_PICK);
                    pickIntent.setType("image/*");
                    startActivityForResult(pickIntent, PICK_VIRTUAL_CAM_IMAGE_ID);
                    break;
                case "test_virtual_camera":
                    Intent camIntent = new Intent(this, VirtualCameraActivity.class);
                    startActivity(camIntent);
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private String getInstalledAppsJson() {
        JSONArray arr = new JSONArray();
        try {
            PackageManager pm = getPackageManager();
            List<ApplicationInfo> apps = pm.getInstalledApplications(PackageManager.GET_META_DATA);
            for (ApplicationInfo app : apps) {
                if (pm.getLaunchIntentForPackage(app.packageName) != null && !app.packageName.equals(getPackageName())) {
                    JSONObject obj = new JSONObject();
                    obj.put("packageName", app.packageName);
                    obj.put("appName", pm.getApplicationLabel(app).toString());
                    arr.put(obj);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error listing apps", e);
        }
        return arr.toString();
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
            Toast.makeText(this, "Selecione 'Hide Protocol VPN' como App de Localização Fictícia nas Opções do Desenvolvedor!", Toast.LENGTH_LONG).show();
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
                    File dest = new File(getFilesDir(), "virtual_camera_frame.jpg");
                    try (InputStream in = getContentResolver().openInputStream(uri);
                         FileOutputStream out = new FileOutputStream(dest)) {
                        if (in != null) {
                            byte[] buf = new byte[8192];
                            int len;
                            while ((len = in.read(buf)) > 0) {
                                out.write(buf, 0, len);
                            }
                        }
                    }
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
