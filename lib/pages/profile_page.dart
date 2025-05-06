import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_platform/universal_platform.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showEditNameBottomSheet(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    bool loading = false;
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: authProvider.userInfo?.name ?? '',
    );

    void handleUpdateName() {
      if (formKey.currentState!.validate()) {
        setState(() {
          loading = true;
        });
        authProvider.updateUser({'name': nameController.text.trim()}).then((
          value,
        ) {
          authProvider.refetchUser().then((value) {
            setState(() {
              loading = false;
            });
          });
        });
        Navigator.pop(context);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Edit Name',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.8),
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.8),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }

                    final nameRegex = RegExp(r'^[a-zA-Z]+(?:\s[a-zA-Z]+)*$');
                    if (!nameRegex.hasMatch(value)) {
                      return 'Please enter a valid name';
                    }

                    if (value.length > 20) {
                      return 'Name cannot be longer than 20 characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: handleUpdateName,
                    child:
                        loading
                            ? const CircularProgressIndicator()
                            : const Text('Save'),
                  ),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReferralDrawer(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Share App',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Referral Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          authProvider.userInfo?.referralCode ?? '',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: authProvider.userInfo?.referralCode ?? '',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referral Stats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${authProvider.userInfo?.referralCount ?? 0}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              'Referrals',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${authProvider.userInfo?.referralRewards ?? 0}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              'Rewards',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () async {
                    final url = authProvider.getReferralUrl();
                    await Share.share(
                      'Join me on our app using my referral code: ${authProvider.userInfo?.referralCode}\n\n$url',
                      subject: 'Check out this app!',
                    );
                  },
                  child: const Text('Share App'),
                ),
              ),
              const SizedBox(height: 44),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Profile', style: Theme.of(context).textTheme.titleLarge),
        elevation: 4, // Adds shadow
        shadowColor: Colors.black.withValues(
          alpha: 0.2,
        ), // Controls shadow color and opacity
        surfaceTintColor:
            Colors.transparent, // Removes the surface tint in Material 3
        scrolledUnderElevation:
            4, // Controls elevation when content is scrolled under the app bar
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top content section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Info Section
                            Row(
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: CircleAvatar(
                                    radius: 100,
                                    backgroundColor: Colors.grey[200],
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.network(
                                        authProvider.userInfo?.profileImage ??
                                            authProvider.userInfo?.avatarUrl ??
                                            '',
                                        fit: BoxFit.cover,
                                        webHtmlElementStrategy:
                                            WebHtmlElementStrategy.fallback,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          authProvider
                                                      .userInfo
                                                      ?.name
                                                      ?.isEmpty ??
                                                  true
                                              ? 'Enter Your name'
                                              : authProvider.userInfo?.name ??
                                                  '',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _showEditNameBottomSheet(
                                                context,
                                                authProvider,
                                              ),
                                          tooltip: 'Edit name',
                                        ),
                                      ],
                                    ),
                                    Transform.translate(
                                      offset: const Offset(
                                        0,
                                        -8,
                                      ), // Adjust this negative value as needed
                                      child: Text(
                                        authProvider.userInfo?.username ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            // Referral Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    spacing: 16,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.network(
                                          'https://masai-website-images.s3.ap-south-1.amazonaws.com/sheild_user_07ee6d9468.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          webHtmlElementStrategy:
                                              WebHtmlElementStrategy.fallback,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Referral',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Invite friends, get rewards!',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => _showReferralDrawer(
                                          context,
                                          authProvider,
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Share'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bottom buttons section
                        Column(
                          children: [
                            // Sign Out Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  authProvider.logout();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    'Sign out',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: UniversalPlatform.isWeb ? 10 : 0),

                            // Privacy Policy and Terms
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/privacy-policy');
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      'Privacy Policy',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.underline,
                                        fontSize: 11,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/terms-and-conditions');
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: Text(
                                      'Terms & Conditions',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.underline,
                                        fontSize: 11,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
