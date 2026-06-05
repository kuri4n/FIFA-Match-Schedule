import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import 'home_screen.dart';
import '../widgets/flag_widget.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<dynamic> teams = [];
  bool loading = true;
  bool syncing = false;

  StreamSubscription? connectivitySubscription;

  @override
  void initState() {
    super.initState();

    loadCacheInstantly();
    fetchInBackground();
    listenToNetwork();
  }

  Future<void> loadCacheInstantly() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_teams');

    if (cached != null) {
      teams = jsonDecode(cached);
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchInBackground() async {
    try {
      if (mounted) {
        setState(() {
          syncing = true;
        });
      }

      final response = await Supabase.instance.client
          .from('teams')
          .select()
          .limit(50);

      response.sort(
        (a, b) => a['name']
            .toString()
            .compareTo(b['name'].toString()),
      );

      if (!mounted) return;

      setState(() {
        teams = response;
        syncing = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_teams',
        jsonEncode(response),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        syncing = false;
      });
    }
  }

  void listenToNetwork() {
    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        fetchInBackground();
      }
    });
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Select Your Team'),
        actions: [
          if (syncing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : teams.isEmpty
              ? const Center(
                  child: Text(
                    'No cached data available',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];

                    return GestureDetector(
                      onTap: () async {
                        final prefs =
                            await SharedPreferences.getInstance();

                        await prefs.setInt(
                          'favorite_team_id',
                          team['id'],
                        );
                        await prefs.setString(
                          'favorite_team_name',
                          team['name'],
                        );
                        await prefs.setString(
                          'favorite_team_code',
                          team['code'],
                        );

                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          PageTransitions.fadeSlide(
                            const HomeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary1,
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            FlagWidget(
                              code: team['code'],
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Text(
                                team['name'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
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