import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';

class VoiceSearchButton extends StatefulWidget {
  final Function(String) onResult;
  final String? label;

  const VoiceSearchButton({super.key, required this.onResult, this.label});

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(encoder: AudioEncoder.aacLc);
        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Listening... Tap again to stop"), duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _showLoadingOverlay();
        final text = await _apiService.speechToText(path);
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          if (text.isNotEmpty) {
            widget.onResult(text);
          }
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Processing voice..."),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceDialog(
        onResult: (text) {
          widget.onResult(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.mic, color: Theme.of(context).primaryColor),
      onPressed: _showVoiceDialog,
    );
  }
}

class VoiceDialog extends StatefulWidget {
  final Function(String) onResult;
  const VoiceDialog({super.key, required this.onResult});

  @override
  State<VoiceDialog> createState() => _VoiceDialogState();
}

class _VoiceDialogState extends State<VoiceDialog> with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _resultText = "";
  final ApiService _apiService = ApiService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startRecordingFlow();
  }

  Future<void> _startRecordingFlow() async {
    try {
      print('DEBUG: Requesting microphone permission...');
      if (await _audioRecorder.hasPermission()) {
        print('DEBUG: Permission GRANTED');
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        print('DEBUG: Starting recorder at path: $path');
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        );
        
        await _audioRecorder.start(config, path: path);
        setState(() => _isRecording = true);
        print('DEBUG: Recorder STARTED successfully');
      } else {
        print('DEBUG: Permission DENIED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mic permission denied")));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('DEBUG: Error in startRecordingFlow: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _stopRecording() async {
    try {
      print('DEBUG: Stopping recorder...');
      final path = await _audioRecorder.stop();
      print('DEBUG: Recorder STOPPED. File path: $path');
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        print('DEBUG: Sending audio file to backend...');
        final text = await _apiService.speechToText(path);
        print('DEBUG: Backend response received: "$text"');
        
        setState(() {
          final cleanText = text.toLowerCase().trim();
          if (cleanText == "you" || cleanText == "you." || cleanText.contains("thank you") || text.isEmpty) {
            _resultText = "No speech detected. Please speak louder.";
          } else {
            _resultText = text;
          }
          _isProcessing = false;
        });
      } else {
        print('DEBUG: Path was NULL after stopping');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('DEBUG: Error in _stopRecording: $e');
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecording ? Icons.mic_rounded : Icons.auto_awesome_rounded,
                  color: const Color(0xFF1E3A8A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? "Listening" : (_isProcessing ? "Processing" : "Transcription"),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Content ──
            if (_isRecording) ...[
              _VoiceWaveform(),
              const SizedBox(height: 32),
              const Text(
                "I am listening to your voice...",
                style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
            ] else if (_isProcessing) ...[
              const Center(
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Color(0xFF1E3A8A),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Whisper AI is transcribing...",
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  _resultText,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 40),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_isRecording)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop_rounded, size: 20),
                      label: const Text("Finish Speaking"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                else if (!_isProcessing)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onResult(_resultText);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text("Use Result"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceWaveform extends StatefulWidget {
  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (index) {
            double h = 12 + (index % 5 * 8 * _controller.value) + (index % 3 * 10);
            if (h > 60) h = 60;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5,
              height: h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        );
      },
    );
  }
}
