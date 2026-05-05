import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class _FlowerBackground extends StatelessWidget {
  final Widget child;
  const _FlowerBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFFDE8F2)),
          CustomPaint(
            painter: _FlowerPainter(),
            size: Size.infinite,
          ),
          Container(color: const Color(0x26FFE6F0)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final flowers = [
      [0.10, 0.08, 38.0, const Color(0xFFF4B0C8)],
      [0.38, 0.04, 28.0, const Color(0xFFFCE0EC)],
      [0.72, 0.10, 42.0, const Color(0xFFF8C8DA)],
      [0.92, 0.07, 32.0, const Color(0xFFF4B8CC)],
      [0.04, 0.35, 34.0, const Color(0xFFFCE0EC)],
      [0.96, 0.42, 36.0, const Color(0xFFF8C8DA)],
      [0.14, 0.72, 40.0, const Color(0xFFF4B0C8)],
      [0.86, 0.78, 38.0, const Color(0xFFFCE0EC)],
      [0.50, 0.03, 24.0, const Color(0xFFF8C8DA)],
      [0.50, 0.97, 30.0, const Color(0xFFF4B8CC)],
      [0.25, 0.88, 26.0, const Color(0xFFFCE0EC)],
      [0.75, 0.90, 32.0, const Color(0xFFF4B0C8)],
    ];

    for (final f in flowers) {
      final cx = (f[0] as double) * w;
      final cy = (f[1] as double) * h;
      final r = f[2] as double;
      final color = f[3] as Color;
      _drawFlower(canvas, cx, cy, r, color);
    }

    final buds = [
      [0.22, 0.18, const Color(0xFFF4B8CC)],
      [0.80, 0.20, const Color(0xFFFCE0EC)],
      [0.45, 0.82, const Color(0xFFF8C8DA)],
      [0.62, 0.75, const Color(0xFFFCE0EC)],
      [0.08, 0.60, const Color(0xFFF4B0C8)],
      [0.94, 0.65, const Color(0xFFFCE0EC)],
    ];

    for (final b in buds) {
      final cx = (b[0] as double) * w;
      final cy = (b[1] as double) * h;
      final color = b[2] as Color;
      _drawBud(canvas, cx, cy, color);
    }

    final leaves = [
      [0.20, 0.12, -0.6],
      [0.60, 0.16, 0.4],
      [0.08, 0.50, -0.5],
      [0.92, 0.55, 0.5],
      [0.30, 0.80, -0.4],
      [0.70, 0.84, 0.4],
    ];

    final leafPaint = Paint()
      ..color = const Color(0xFF90CC90).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    for (final l in leaves) {
      final cx = (l[0] as double) * w;
      final cy = (l[1] as double) * h;
      final angle = l[2] as double;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 36, height: 14),
        leafPaint,
      );
      canvas.restore();
    }
  }

  void _drawFlower(Canvas canvas, double cx, double cy, double r, Color color) {
    final paint = Paint()..style = PaintingStyle.fill;
    final innerR = r * 0.62;
    final centerR = r * 0.32;
    final angles = [0, 45, 90, 135, 180, 225, 270, 315];

    paint.color = color;
    for (final a in angles) {
      final rad = a * 3.14159 / 180;
      final px = cx + (r * 0.72) * _cos(rad);
      final py = cy + (r * 0.72) * _sin(rad);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: r * 0.85,
          height: r * 0.55,
        ),
        paint,
      );
    }

    paint.color = color.withRed((color.red - 15).clamp(0, 255));
    for (var i = 0; i < 6; i++) {
      final rad = i * 60 * 3.14159 / 180;
      final px = cx + innerR * 0.65 * _cos(rad);
      final py = cy + innerR * 0.65 * _sin(rad);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: innerR * 0.8,
          height: innerR * 0.5,
        ),
        paint,
      );
    }

    paint.color = const Color(0xFFF9E4B0);
    canvas.drawCircle(Offset(cx, cy), centerR, paint);
  }

  void _drawBud(Canvas canvas, double cx, double cy, Color color) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = color;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 14, height: 20),
      paint,
    );

    paint.color = const Color(0xFF90C890);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 12, height: 8),
      paint,
    );
  }

  double _cos(double rad) => _mathCos(rad);
  double _sin(double rad) => _mathSin(rad);

  double _mathCos(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _mathSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginCard extends StatelessWidget {
  final Widget child;
  const _LoginCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.87),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45078).withOpacity(0.16),
                blurRadius: 32,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF0C4D4).withOpacity(0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4B0C8).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFD4537E), size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA03060),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(0xFFD4A0B5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

InputDecoration _inputDeco({
  required String label,
  required IconData prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: Color(0xFFB07090),
    ),
    prefixIcon: Icon(prefix, color: const Color(0xFFD4789A), size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFFFF0F5).withOpacity(0.7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF0C4D4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF0C4D4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD4789A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE57373)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

ButtonStyle get _btnStyle => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD4537E),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 48),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context
        .read<AuthProvider>()
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selamat, Anda berhasil login.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Login gagal',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return _FlowerBackground(
      child: _LoginCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: Icons.local_florist,
                title: 'Toko Bunga',
                subtitle: 'Keindahan dalam setiap kelopak 🌸',
              ),
              const SizedBox(height: 16),
              const Text(
                'Halo! 🌸',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB8506E),
                ),
              ),
              const Text(
                'Masuk untuk melanjutkan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFFD4A0B5),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      decoration: _inputDeco(
                        label: 'Email',
                        prefix: Icons.email_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (!v.contains('@')) return 'Email tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      decoration: _inputDeco(
                        label: 'Password',
                        prefix: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFD4789A),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Min. 6 karakter';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 4,
                    ),
                  ),
                  child: const Text(
                    'Lupa Kata Sandi?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4537E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed:
                    authProvider.status == AuthStatus.loading ? null : _login,
                style: _btnStyle,
                child: authProvider.status == AuthStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _LoginCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: Icons.lock_reset,
                title: 'Lupa Kata Sandi',
                subtitle: 'Masukkan email akunmu',
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Password 🔑',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB8506E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kami akan mengirimkan kode verifikasi ke email kamu.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFFD4A0B5),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: _inputDeco(
                  label: 'Email',
                  prefix: Icons.email_outlined,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendEmail,
                style: _btnStyle,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Kirim Kode Verifikasi'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Kembali ke Login',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFD4537E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _otpCtrls) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode OTP!'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.verifyOtp(widget.email, _otpCode);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otpCode: _otpCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _LoginCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(
              icon: Icons.mark_email_read_outlined,
              title: 'Verifikasi Email',
              subtitle: 'Masukkan kode OTP',
            ),
            const SizedBox(height: 16),
            const Text(
              'Kode OTP 📩',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB8506E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kode dikirim ke ${widget.email}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFFD4A0B5),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 42,
                  height: 48,
                  child: TextFormField(
                    controller: _otpCtrls[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Color(0xFF7B2D4E),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFFFF0F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFF0C4D4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4537E),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _verify,
              style: _btnStyle,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Verifikasi'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Kirim ulang kode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFFD4537E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.resetPassword(
        widget.email,
        widget.otpCode,
        _passCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil direset! Silakan login.'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _LoginCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CardHeader(
                icon: Icons.lock_outline,
                title: 'Password Baru',
                subtitle: 'Buat password baru kamu',
              ),
              const SizedBox(height: 16),
              const Text(
                'Buat Password Baru 🔒',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB8506E),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: _inputDeco(
                  label: 'Password Baru',
                  prefix: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFD4789A),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                  if (v.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: _inputDeco(
                  label: 'Konfirmasi Password',
                  prefix: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFD4789A),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v != _passCtrl.text) return 'Password tidak sama!';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: _btnStyle,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Password Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}