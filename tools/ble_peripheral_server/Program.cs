using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Devices.Radios;
using Windows.Storage.Streams;

class BlePeripheralServer {
    private static readonly Guid ServiceUuid = Guid.Parse("180D0000-7243-4E64-8843-50554C534531");
    private static readonly Guid HrCharUuid = Guid.Parse("180D0001-7243-4E64-8843-50554C534531");
    private static readonly Guid RawCharUuid = Guid.Parse("180D0002-7243-4E64-8843-50554C534531");
    private static readonly Guid StatusCharUuid = Guid.Parse("180D0003-7243-4E64-8843-50554C534531");

    // Current Telemetry State
    public static double CurrentBpm = 68.0;
    public static int CurrentSpo2 = 98;
    public static int CurrentSqi = 95;
    public static bool ContactDetected = true;
    public static bool MotionSuspected = false;
    public static bool InvalidateHr = false;
    public static bool InvalidateSpo2 = false;
    public static string CurrentSessionName = "S1-Resting";

    // Telemetry Statistics
    public static long HrPacketsTransmitted = 0;
    public static long RawPacketsTransmitted = 0;
    public static ushort SequenceNumber = 0;
    public static DateTime ServerStartTime = DateTime.UtcNow;

    private static GattServiceProvider? _provider;
    private static GattLocalCharacteristic? _hrCharacteristic;
    private static GattLocalCharacteristic? _rawCharacteristic;
    private static GattLocalCharacteristic? _statusCharacteristic;

    private static int _subscribedHrClients = 0;
    private static int _subscribedRawClients = 0;

    static async Task Main(string[] args) {
        Console.WriteLine("==================================================");
        Console.WriteLine("PulsePatch-C3-TEST — Genuine WinRT BLE Peripheral");
        Console.WriteLine("Conforming to Master BLE Protocol (UUID 180D0000...)");
        Console.WriteLine("==================================================");

        // 1. Ensure Bluetooth Radio is ON
        var radios = await Radio.GetRadiosAsync();
        foreach (var r in radios) {
            if (r.Kind == RadioKind.Bluetooth && r.State != RadioState.On) {
                Console.WriteLine("[RADIO] Turning Bluetooth Radio ON...");
                await r.SetStateAsync(RadioState.On);
            }
        }

        // 2. Create GATT Service Provider
        Console.WriteLine($"[GATT] Creating service {ServiceUuid}...");
        var createResult = await GattServiceProvider.CreateAsync(ServiceUuid);
        if (createResult.Error != BluetoothError.Success) {
            Console.WriteLine($"[GATT] ERROR: Failed to create provider: {createResult.Error}");
            return;
        }
        _provider = createResult.ServiceProvider;
        _provider.AdvertisementStatusChanged += (s, a) => {
            Console.WriteLine($"[ADV] Status changed: {a.Status}, Error={a.Error}");
        };

        // 3. Create Characteristics
        // Characteristic 1: HR & SpO2 (Read, Notify)
        var hrParams = new GattLocalCharacteristicParameters {
            CharacteristicProperties = GattCharacteristicProperties.Notify | GattCharacteristicProperties.Read,
            ReadProtectionLevel = GattProtectionLevel.Plain
        };
        var hrResult = await _provider.Service.CreateCharacteristicAsync(HrCharUuid, hrParams);
        if (hrResult.Error != BluetoothError.Success) {
            Console.WriteLine($"[GATT] ERROR creating HR characteristic: {hrResult.Error}");
            return;
        }
        _hrCharacteristic = hrResult.Characteristic;
        _hrCharacteristic.ReadRequested += OnHrReadRequested;
        _hrCharacteristic.SubscribedClientsChanged += (charac, e) => {
            _subscribedHrClients = charac.SubscribedClients.Count;
            Console.WriteLine($"[GATT] HR Subscribed clients: {_subscribedHrClients}");
        };

        // Characteristic 2: Raw Optical Waveform (Notify)
        var rawParams = new GattLocalCharacteristicParameters {
            CharacteristicProperties = GattCharacteristicProperties.Notify
        };
        var rawResult = await _provider.Service.CreateCharacteristicAsync(RawCharUuid, rawParams);
        if (rawResult.Error != BluetoothError.Success) {
            Console.WriteLine($"[GATT] ERROR creating Raw characteristic: {rawResult.Error}");
            return;
        }
        _rawCharacteristic = rawResult.Characteristic;
        _rawCharacteristic.SubscribedClientsChanged += (charac, e) => {
            _subscribedRawClients = charac.SubscribedClients.Count;
            Console.WriteLine($"[GATT] Raw Subscribed clients: {_subscribedRawClients}");
        };

        // Characteristic 3: Device Status (Read)
        var statusParams = new GattLocalCharacteristicParameters {
            CharacteristicProperties = GattCharacteristicProperties.Read,
            ReadProtectionLevel = GattProtectionLevel.Plain
        };
        var statusResult = await _provider.Service.CreateCharacteristicAsync(StatusCharUuid, statusParams);
        if (statusResult.Error != BluetoothError.Success) {
            Console.WriteLine($"[GATT] ERROR creating Status characteristic: {statusResult.Error}");
            return;
        }
        _statusCharacteristic = statusResult.Characteristic;
        _statusCharacteristic.ReadRequested += OnStatusReadRequested;

        // 4. Start Advertising
        var advParams = new GattServiceProviderAdvertisingParameters {
            IsConnectable = true,
            IsDiscoverable = true
        };
        _provider.StartAdvertising(advParams);
        Console.WriteLine($"[BLE] Advertising started. Name: PulsePatch-C3-TEST / UUID: {ServiceUuid}");

        // 5. Start Background HTTP Control Server
        StartHttpControlServer();

        // 6. Start Telemetry Broadcast Loop
        _ = Task.Run(RunHrBroadcastLoop);
        _ = Task.Run(RunRawPpgBroadcastLoop);

        Console.WriteLine("\n[SERVER READY] Listening on http://localhost:5055/ for scenario controls.");
        Console.WriteLine("Available commands:");
        Console.WriteLine("  1: Session 1 (68 BPM, 98% SpO2, SQI 95)");
        Console.WriteLine("  2: Session 2 (76 BPM, 97% SpO2, SQI 90)");
        Console.WriteLine("  3: Session 3 (88 BPM, 97% SpO2, SQI 88)");
        Console.WriteLine("  4: Session 4 (94 BPM, 96% SpO2, SQI 85)");
        Console.WriteLine("  5: Session 5 (72 BPM, 99% SpO2, SQI 96)");
        Console.WriteLine("  c: Toggle Contact Lost");
        Console.WriteLine("  q: Toggle Low SQI");
        Console.WriteLine("  o: Toggle Invalid SpO2");
        Console.WriteLine("  h: Toggle Invalid HR");
        Console.WriteLine("  s: Print Status");
        Console.WriteLine("  x: Exit\n");

        // Interactive Console Command Loop or Background Wait
        if (Console.IsInputRedirected) {
            Console.WriteLine("[SERVER] Running in non-interactive/redirected mode. Awaiting HTTP commands...");
            await Task.Delay(Timeout.Infinite);
        } else {
            while (true) {
                var key = Console.ReadKey(true);
                if (key.KeyChar == 'x') break;
                HandleKeyCommand(key.KeyChar);
            }
        }

        Console.WriteLine("[BLE] Stopping advertising and shutting down...");
        _provider.StopAdvertising();
    }

    private static void HandleKeyCommand(char c) {
        switch (c) {
            case '1':
                SetSession("S1-Resting", 68.0, 98, 95);
                break;
            case '2':
                SetSession("S2-Elevated-Rest", 76.0, 97, 90);
                break;
            case '3':
                SetSession("S3-Moderate-HR", 88.0, 97, 88);
                break;
            case '4':
                SetSession("S4-High-Activity", 94.0, 96, 85);
                break;
            case '5':
                SetSession("S5-Recovery", 72.0, 99, 96);
                break;
            case 'c':
                ContactDetected = !ContactDetected;
                Console.WriteLine($"[STATE] ContactDetected = {ContactDetected}");
                break;
            case 'q':
                CurrentSqi = (CurrentSqi > 50) ? 25 : 92;
                Console.WriteLine($"[STATE] CurrentSqi = {CurrentSqi}");
                break;
            case 'o':
                InvalidateSpo2 = !InvalidateSpo2;
                Console.WriteLine($"[STATE] InvalidateSpo2 = {InvalidateSpo2}");
                break;
            case 'h':
                InvalidateHr = !InvalidateHr;
                Console.WriteLine($"[STATE] InvalidateHr = {InvalidateHr}");
                break;
            case 's':
                PrintStatus();
                break;
        }
    }

    public static void SetSession(string name, double bpm, int spo2, int sqi) {
        CurrentSessionName = name;
        CurrentBpm = bpm;
        CurrentSpo2 = spo2;
        CurrentSqi = sqi;
        ContactDetected = true;
        MotionSuspected = false;
        InvalidateHr = false;
        InvalidateSpo2 = false;
        Console.WriteLine($"[SESSION] Loaded {name}: HR={bpm} BPM, SpO2={spo2}%, SQI={sqi}");
    }

    public static void PrintStatus() {
        Console.WriteLine($"--- Status: {CurrentSessionName} ---");
        Console.WriteLine($"HR: {CurrentBpm} BPM (Invalid={InvalidateHr})");
        Console.WriteLine($"SpO2: {CurrentSpo2}% (Invalid={InvalidateSpo2})");
        Console.WriteLine($"SQI: {CurrentSqi}, Contact={ContactDetected}, Motion={MotionSuspected}");
        Console.WriteLine($"Transmitted: HR Packets={HrPacketsTransmitted}, Raw PPG={RawPacketsTransmitted}");
        Console.WriteLine($"Subscribed Clients: HR={_subscribedHrClients}, Raw={_subscribedRawClients}");
    }

    // 12-byte little endian HR Packet builder
    private static byte[] BuildHrPacket() {
        var bytes = new byte[12];
        bytes[0] = 0x01; // Protocol Version

        byte flags = 0;
        if (ContactDetected) flags |= 0x01;
        if (MotionSuspected) flags |= 0x02;
        bytes[1] = flags;

        ushort bpmTimes10 = 0xFFFF;
        if (!InvalidateHr && ContactDetected) {
            bpmTimes10 = (ushort)Math.Clamp((int)(CurrentBpm * 10.0), 0, 65534);
        }
        bytes[2] = (byte)(bpmTimes10 & 0xFF);
        bytes[3] = (byte)((bpmTimes10 >> 8) & 0xFF);

        bytes[4] = (byte)Math.Clamp(CurrentSqi, 0, 100);

        uint nowMs = (uint)(DateTime.UtcNow - ServerStartTime).TotalMilliseconds;
        bytes[5] = (byte)(nowMs & 0xFF);
        bytes[6] = (byte)((nowMs >> 8) & 0xFF);
        bytes[7] = (byte)((nowMs >> 16) & 0xFF);
        bytes[8] = (byte)((nowMs >> 24) & 0xFF);

        SequenceNumber++;
        bytes[9] = (byte)(SequenceNumber & 0xFF);
        bytes[10] = (byte)((SequenceNumber >> 8) & 0xFF);

        byte spo2Val = 0;
        if (!InvalidateSpo2 && ContactDetected) {
            spo2Val = (byte)Math.Clamp(CurrentSpo2, 70, 100);
        }
        bytes[11] = spo2Val;

        return bytes;
    }

    // 12-byte Raw PPG packet builder
    private static byte[] BuildRawPpgPacket(double tSec) {
        var bytes = new byte[12];
        uint nowMs = (uint)(DateTime.UtcNow - ServerStartTime).TotalMilliseconds;

        bytes[0] = (byte)(nowMs & 0xFF);
        bytes[1] = (byte)((nowMs >> 8) & 0xFF);
        bytes[2] = (byte)((nowMs >> 16) & 0xFF);
        bytes[3] = (byte)((nowMs >> 24) & 0xFF);

        // Generate realistic optical PPG pulse waveform
        uint irVal, redVal;
        if (ContactDetected) {
            double freqHz = CurrentBpm / 60.0;
            double phase = 2.0 * Math.PI * freqHz * tSec;
            // Morphological pulse model: primary systolic peak + dicrotic wave
            double pulse = Math.Sin(phase) + 0.45 * Math.Sin(2.0 * phase - 0.7) + 0.15 * Math.Sin(3.0 * phase - 1.2);
            irVal = (uint)Math.Clamp(60000.0 + 1500.0 * pulse, 1000.0, 260000.0);
            redVal = (uint)Math.Clamp(55000.0 + 1200.0 * pulse, 1000.0, 260000.0);
        } else {
            // Low ambient noise, below finger detection threshold
            irVal = (uint)(8000 + (nowMs % 200));
            redVal = (uint)(7500 + (nowMs % 180));
        }

        bytes[4] = (byte)(irVal & 0xFF);
        bytes[5] = (byte)((irVal >> 8) & 0xFF);
        bytes[6] = (byte)((irVal >> 16) & 0xFF);
        bytes[7] = (byte)((irVal >> 24) & 0xFF);

        bytes[8] = (byte)(redVal & 0xFF);
        bytes[9] = (byte)((redVal >> 8) & 0xFF);
        bytes[10] = (byte)((redVal >> 16) & 0xFF);
        bytes[11] = (byte)((redVal >> 24) & 0xFF);

        return bytes;
    }

    private static async void OnHrReadRequested(GattLocalCharacteristic sender, GattReadRequestedEventArgs args) {
        var deferral = args.GetDeferral();
        try {
            var request = await args.GetRequestAsync();
            var payload = BuildHrPacket();
            var writer = new DataWriter();
            writer.WriteBytes(payload);
            request.RespondWithValue(writer.DetachBuffer());
        } catch (Exception ex) {
            Console.WriteLine($"[GATT] Read HR Error: {ex.Message}");
        } finally {
            deferral.Complete();
        }
    }

    private static async void OnStatusReadRequested(GattLocalCharacteristic sender, GattReadRequestedEventArgs args) {
        var deferral = args.GetDeferral();
        try {
            var request = await args.GetRequestAsync();
            var json = $"{{\"fw\":\"2.0.0-test\",\"sensor\":\"MAX30102_SIM_OK\",\"spo2_supported\":true,\"session\":\"{CurrentSessionName}\"}}";
            var bytes = Encoding.UTF8.GetBytes(json);
            var writer = new DataWriter();
            writer.WriteBytes(bytes);
            request.RespondWithValue(writer.DetachBuffer());
            Console.WriteLine($"[GATT] Status Read Requested -> Responded: {json}");
        } catch (Exception ex) {
            Console.WriteLine($"[GATT] Read Status Error: {ex.Message}");
        } finally {
            deferral.Complete();
        }
    }

    private static async Task RunHrBroadcastLoop() {
        while (true) {
            try {
                if (_hrCharacteristic != null) {
                    var payload = BuildHrPacket();
                    var writer = new DataWriter();
                    writer.WriteBytes(payload);
                    var buffer = writer.DetachBuffer();

                    // Send notification to subscribed clients (or set value)
                    if (_subscribedHrClients > 0) {
                        await _hrCharacteristic.NotifyValueAsync(buffer);
                        HrPacketsTransmitted++;
                    }
                }
            } catch (Exception ex) {
                // Ignore transient notify errors
            }
            await Task.Delay(1000); // 1 Hz standard HR packet broadcast
        }
    }

    private static async Task RunRawPpgBroadcastLoop() {
        int sampleIndex = 0;
        while (true) {
            try {
                if (_rawCharacteristic != null && _subscribedRawClients > 0) {
                    double tSec = sampleIndex * 0.04; // 25 Hz
                    var payload = BuildRawPpgPacket(tSec);
                    var writer = new DataWriter();
                    writer.WriteBytes(payload);
                    var buffer = writer.DetachBuffer();

                    await _rawCharacteristic.NotifyValueAsync(buffer);
                    RawPacketsTransmitted++;
                    sampleIndex++;
                }
            } catch { }
            await Task.Delay(40); // 25 Hz PPG sample rate (40 ms)
        }
    }

    private static void StartHttpControlServer() {
        try {
            var listener = new HttpListener();
            listener.Prefixes.Add("http://localhost:5055/");
            listener.Start();

            Task.Run(async () => {
                while (listener.IsListening) {
                    try {
                        var ctx = await listener.GetContextAsync();
                        var path = ctx.Request.Url?.AbsolutePath.ToLowerInvariant() ?? "";
                        string response = "OK";

                        if (path.StartsWith("/session/1")) {
                            SetSession("S1-Resting", 68.0, 98, 95);
                            response = "Loaded Session 1: 68 BPM, 98% SpO2, SQI 95";
                        } else if (path.StartsWith("/session/2")) {
                            SetSession("S2-Elevated-Rest", 76.0, 97, 90);
                            response = "Loaded Session 2: 76 BPM, 97% SpO2, SQI 90";
                        } else if (path.StartsWith("/session/3")) {
                            SetSession("S3-Moderate-HR", 88.0, 97, 88);
                            response = "Loaded Session 3: 88 BPM, 97% SpO2, SQI 88";
                        } else if (path.StartsWith("/session/4")) {
                            SetSession("S4-High-Activity", 94.0, 96, 85);
                            response = "Loaded Session 4: 94 BPM, 96% SpO2, SQI 85";
                        } else if (path.StartsWith("/session/5")) {
                            SetSession("S5-Recovery", 72.0, 99, 96);
                            response = "Loaded Session 5: 72 BPM, 99% SpO2, SQI 96";
                        } else if (path.StartsWith("/scenario/contact_lost")) {
                            ContactDetected = false;
                            response = "Contact Lost activated";
                        } else if (path.StartsWith("/scenario/contact_restored")) {
                            ContactDetected = true;
                            response = "Contact Restored";
                        } else if (path.StartsWith("/scenario/low_sqi")) {
                            CurrentSqi = 25;
                            response = "Low SQI (25) activated";
                        } else if (path.StartsWith("/scenario/invalid_spo2")) {
                            InvalidateSpo2 = true;
                            response = "Invalid SpO2 (0) activated";
                        } else if (path.StartsWith("/scenario/invalid_hr")) {
                            InvalidateHr = true;
                            response = "Invalid HR (0xFFFF) activated";
                        } else if (path.StartsWith("/stats")) {
                            response = $"{{\"session\":\"{CurrentSessionName}\",\"bpm\":{CurrentBpm},\"spo2\":{CurrentSpo2},\"sqi\":{CurrentSqi},\"contact\":{ContactDetected.ToString().ToLower()},\"hr_tx\":{HrPacketsTransmitted},\"raw_tx\":{RawPacketsTransmitted},\"hr_subscribers\":{_subscribedHrClients},\"raw_subscribers\":{_subscribedRawClients}}}";
                            ctx.Response.ContentType = "application/json";
                        }

                        var buf = Encoding.UTF8.GetBytes(response);
                        ctx.Response.ContentLength64 = buf.Length;
                        await ctx.Response.OutputStream.WriteAsync(buf, 0, buf.Length);
                        ctx.Response.Close();
                    } catch { }
                }
            });
        } catch (Exception ex) {
            Console.WriteLine($"[HTTP] Could not start control server on :5055: {ex.Message}");
        }
    }
}
