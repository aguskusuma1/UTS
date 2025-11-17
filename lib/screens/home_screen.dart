import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/preferences_service.dart';
import 'news_list_screen.dart';
import 'voltage_drop_calculator_screen.dart';
import 'calculation_history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tampilkan dialog untuk memberitahu batasan penggunaan
  Future<void> _showLimitDialog(BuildContext context) async {
    final maxCount = PreferencesService.maxHitCount;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Batasan Penggunaan'),
            ],
          ),
          content: Text(
            'Anda telah menggunakan fitur sebanyak $maxCount kali.\n\n'
            'Untuk menggunakan semua fitur tanpa batasan, silakan login terlebih dahulu.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Login Sekarang'),
            ),
          ],
        );
      },
    );
  }

  // Cek dan handle penggunaan fitur
  Future<bool> _checkAndIncrementUsage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Jika sudah login, tidak ada batasan
    if (authProvider.isAuthenticated) {
      return true;
    }

    // Cek hit count saat ini
    final currentCount = await PreferencesService.getHitCount();
    
    // Jika sudah mencapai atau melebihi limit, tampilkan dialog
    if (currentCount >= PreferencesService.maxHitCount) {
      await _showLimitDialog(context);
      return false;
    }

    // Increment hit count SEBELUM menggunakan fitur
    final newCount = await PreferencesService.incrementHitCount();
    final remaining = PreferencesService.maxHitCount - newCount;

    // Tampilkan snackbar untuk memberitahu sisa penggunaan
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining > 0
                ? 'Sisa penggunaan tanpa login: $remaining kali'
                : 'Ini adalah penggunaan terakhir sebelum login diperlukan',
          ),
          backgroundColor: remaining > 1 ? Colors.blue : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daya Assist'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Jika sudah login, tampilkan logout dan profile
              if (authProvider.isAuthenticated) {
                return Row(
                  children: [
                    // Profile button
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      tooltip: 'Profil',
                    ),
                    // Logout button
                    IconButton(
                      icon: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout),
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleLogout(context),
                      tooltip: 'Logout',
                    ),
                  ],
                );
              }

              // Jika belum login, tampilkan login button
              return IconButton(
                icon: const Icon(Icons.login),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                tooltip: 'Login',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with User Info / Guest Info
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  final isLoggedIn = authProvider.isAuthenticated;

                  return Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // User Profile Picture
                          Builder(
                            builder: (context) {
                              final photoURL = user?.photoURL;
                              if (isLoggedIn && photoURL != null && photoURL.isNotEmpty) {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(photoURL),
                                );
                              } else {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                  child: Icon(
                                    isLoggedIn ? Icons.person : Icons.person_outline,
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          // User/Guest Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoggedIn ? 'Selamat Datang,' : 'Mode Tamu',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                                Text(
                                  isLoggedIn
                                      ? (user?.displayName ?? 'User')
                                      : 'Coba Fitur Kami',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Tampilkan hit counter untuk guest
                                if (!isLoggedIn)
                                  FutureBuilder<int>(
                                    future: PreferencesService.getRemainingUsage(),
                                    builder: (context, snapshot) {
                                      final remaining = snapshot.data ?? 0;
                                      return Text(
                                        'Sisa penggunaan: $remaining kali',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer
                                                  .withOpacity(0.8),
                                            ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Features Section
              Text(
                'Fitur Utama',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // News Feature Card
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () async {
                    // Cek dan increment usage sebelum membuka fitur
                    final canUse = await _checkAndIncrementUsage(context);
                    if (!canUse) return;

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewsListScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.article,
                            size: 32,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Berita Teknologi',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Baca berita terkini tentang teknologi dan kelistrikan',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Calculator Feature Card
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () async {
                    // Cek dan increment usage sebelum membuka fitur
                    final canUse = await _checkAndIncrementUsage(context);
                    if (!canUse) return;

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoltageDropCalculatorScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calculate,
                            size: 32,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalkulator Drop Tegangan JTR',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hitung drop tegangan pada jaringan tegangan rendah',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // History Card
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () async {
                    // Cek dan increment usage sebelum membuka fitur
                    final canUse = await _checkAndIncrementUsage(context);
                    if (!canUse) return;

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalculationHistoryScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 32,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History Perhitungan',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lihat riwayat perhitungan yang telah dilakukan',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Info
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tentang Aplikasi',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Daya Assist adalah aplikasi untuk membantu perhitungan teknis kelistrikan dan menyediakan informasi berita terkini seputar teknologi dan kelistrikan.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
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

