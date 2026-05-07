import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import '../../../services/ble/bluetooth_controller.dart';

// ─────────────────────────────────────────────────────────────
// BluetoothPairingScreen  (StatefulWidget – UI only)
// ─────────────────────────────────────────────────────────────
class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() =>
      _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  late final BluetoothController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BluetoothController()..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConnect(BluetoothDevice device) async {
    try {
      await _controller.connectDevice(device);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(
              'Connected to ${_controller.deviceLabel(device)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText('Failed to connect: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Connect Device',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Connected devices ──────────────────
                  _SectionHeader(
                    title: 'Connected Devices',
                    trailing: IconButton(
                      tooltip: 'Refresh',
                      onPressed:
                          c.isBusy ? null : c.refreshConnectedDevices,
                      icon: Icon(Icons.refresh_rounded,
                          color: colors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (c.connectedDevices.isEmpty)
                    _EmptyCard(message: 'No connected devices yet.')
                  else
                    ...c.connectedDevices.map(
                      (d) => _DeviceTile(
                        name: c.deviceLabel(d),
                        status: 'Connected',
                        isConnected: true,
                        actionLabel: 'Disconnect',
                        onAction: c.isBusy
                            ? null
                            : () => _controller.disconnectDevice(d),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Scan button ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (c.isBusy || c.isScanning)
                          ? null
                          : _controller.startScan,
                      icon: Icon(c.isScanning
                          ? Icons.hourglass_bottom_rounded
                          : Icons.bluetooth_searching_rounded),
                      label: TranslatedText(
                        c.isScanning
                            ? 'Scanning...'
                            : 'Pair/Connect New Device',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Scan results ───────────────────────
                  _SectionHeader(title: 'Available Devices'),
                  const SizedBox(height: 10),
                  if (c.scanResults.isEmpty)
                    _EmptyCard(message: 'No discovered devices yet.')
                  else
                    ...c.scanResults.map((result) {
                      final device = result.device;
                      final adName =
                          result.advertisementData.advName;
                      final platform =
                          device.platformName.trim();
                      final name = adName.isNotEmpty
                          ? adName
                          : platform.isNotEmpty
                              ? platform
                              : 'Unnamed BLE Device (${device.remoteId.str})';
                      final connected = c.isConnected(device);

                      return _DeviceTile(
                        name: name,
                        status: connected
                            ? 'Connected'
                            : 'RSSI: ${result.rssi} dBm',
                        isConnected: connected,
                        actionLabel:
                            connected ? 'Connected' : 'Connect',
                        onAction: connected || c.isBusy
                            ? null
                            : () => _handleConnect(device),
                      );
                    }),

                  const SizedBox(height: 24),
                  if (c.statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TranslatedText(
                        c.statusMessage!,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary),
                      ),
                    ),
                  TranslatedText(
                    'To pair a new device, put it in discovery mode and tap on it.',
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private presentational widgets
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: TranslatedText(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: TranslatedText(
        message,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final String status;
  final bool isConnected;
  final String actionLabel;
  final VoidCallback? onAction;

  const _DeviceTile({
    required this.name,
    required this.status,
    required this.isConnected,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_rounded,
            size: 24,
            color:
                isConnected ? colors.primary : colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                TranslatedText(
                  status,
                  style: TextStyle(
                      fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TranslatedText(
                'Connected',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: TranslatedText(
                actionLabel,
                style: TextStyle(color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
