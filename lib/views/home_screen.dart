import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class HomePage extends StatelessWidget {
  final dynamic userData;

  const HomePage({super.key, this.userData});

  void _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: \$e')));
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    String displayName = '';
    String email = '';
    String? avatarUrl;
    String? bio;
    String? lastLogin;

    if (userData != null) {
      if (userData is Map && userData.containsKey('userMetadata')) {
        // Supabase user session with metadata
        displayName =
            userData['userMetadata']?['username']?.toString() ??
            userData['email']?.toString().split('@').first ??
            'User';
        email = userData['email']?.toString() ?? '';
        avatarUrl = userData['userMetadata']?['avatar_url']?.toString();
        bio = userData['userMetadata']?['bio']?.toString();
        lastLogin = userData['lastSignInAt']?.toString();
      } else if (userData is Map &&
          (userData.containsKey('username') || userData.containsKey('email'))) {
        // Profile data from Supabase table
        displayName =
            userData['username']?.toString() ??
            userData['email']?.toString().split('@').first ??
            'User';
        email = userData['email']?.toString() ?? '';
        avatarUrl = userData['avatar_url']?.toString();
        bio = userData['bio']?.toString();
        lastLogin = userData['lastLogin']?.toString();
      } else {
        // Fallback parsing from common keys
        displayName =
            (userData?.userMetadata?['full_name'] != null &&
                    userData!.userMetadata!['full_name'].toString().isNotEmpty)
                ? userData.userMetadata!['full_name'].toString()
                : (userData?.email?.split('@').first ?? 'User');

        email = userData?.email ?? '';

        avatarUrl = userData?.userMetadata?['avatar_url']?.toString();
        bio = userData?.userMetadata?['bio']?.toString();

        lastLogin = userData?.lastSignInAt ?? null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF667EEA),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF1A237E)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      51,
                                    ), // 0.2 * 255 = 51
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    avatarUrl != null
                                        ? NetworkImage(avatarUrl!)
                                        : null,
                                child:
                                    avatarUrl == null
                                        ? Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF667EEA),
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                            const Spacer(),
                            // Logout Button
                            Material(
                              color: Colors.white.withAlpha(
                                51,
                              ), // 0.2 * 255 = 51
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _logout(context),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withAlpha(
                              230,
                            ), // 0.9 * 255 = 230
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 400 ? 16 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF667EEA,
                              ).withAlpha(26), // 0.1 * 255 = 26
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.waves_rounded,
                              color: Color(0xFF1A237E),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Welcome!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to explore? Your dashboard is all set up and ready to go.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                      if (bio != null && bio!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Bio',
                          value: bio!,
                        ),
                      ],
                      if (lastLogin != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Last Login',
                          value: _formatDateTime(
                            DateTime.tryParse(lastLogin!) ?? DateTime.now(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // Quick Actions Grid as Sliver
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 20,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600
                        ? 4
                        : MediaQuery.of(context).size.width > 400
                        ? 3
                        : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9, // Slightly taller to prevent overflow
              ),
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'View & edit profile',
                  color: const Color(0xFF10B981),
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences',
                  color: const Color(0xFF1A237E),
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.help_outline,
                  title: 'Help',
                  subtitle: 'Get support',
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App information',
                  color: const Color(0xFFEF4444),
                  onTap: () {},
                ),
              ]),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withAlpha(26), // 0.1 * 255 = 26
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF667EEA)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withAlpha(13),
      // 0.05 * 255 = 13
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26), // 0.1 * 255 = 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
