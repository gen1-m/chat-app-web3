import 'package:material_ui/material_ui.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class MetamaskProvider extends ChangeNotifier {
  static const operatingChain = 11155111; // Sepolia

  String currentAddress = "";
  int currentChain = -1;

  bool get isEnabled => ethereum != null;

  bool get isInOperatingChain => currentChain == operatingChain;

  bool get isConnected =>
      isEnabled && currentAddress.isNotEmpty && isInOperatingChain;

  Future<void> connect() async {
    if (!isEnabled) {
      debugPrint('MetaMask is not enabled');
      return;
    }

    try {
      final access = await ethereum!.requestAccount();

      if (access.isEmpty) {
        debugPrint('No accounts returned');
        return;
      }

      currentAddress = access.first;
      currentChain = await ethereum!.getChainId();

      if (!isInOperatingChain) {
        notifyListeners();
        return;
      }
      await authenticateWithSupabase();

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('MetaMask connection failed: $e');
      debugPrint('$stackTrace');
      reset();
    }
  }

  Future<void> authenticateWithSupabase() async {
    final web3Provider = Web3Provider.fromEthereum(ethereum!);
    final signer = web3Provider.getSigner();

    final domain = Uri.base.host;
    final uri = Uri.base.origin;
    final issuedAt = DateTime.now().toUtc().toIso8601String();

    final nonce = Supabase.instance.client.auth.generateRawNonce();

    final message = 
    '''
      $domain wants you to sign in with your Ethereum account:
      $currentAddress

      Sign in to the Web3 Chat application.

      URI: $uri
      Version: 1
      Chain ID: $currentChain
      Nonce: $nonce
      Issued At: $issuedAt
    ''';

    final signature = await signer.signMessage(message);

    await Supabase.instance.client.auth.signInWithWeb3(
      chain: Web3Chain.ethereum,
      message: message,
      signature: signature,
    );

    await SupabaseService.getOrCreateProfile(
      currentAddress,
    );
  }

  void reset() {
    currentAddress = "";
    currentChain = -1;
    notifyListeners();
  }

  Future<void> start() async {
    if (!isEnabled) {
      return;
    }

    ethereum!.onAccountsChanged((accounts) {
      reset();
    });

    ethereum!.onChainChanged((chainId) {
      reset();
    });

    try {
      final accounts = await ethereum!.getAccounts();

      if (accounts.isEmpty) {
        return;
      }

      currentAddress = accounts.first;
      currentChain = await ethereum!.getChainId();

      if (!isInOperatingChain) {
        notifyListeners();
        return;
      }

      // check whether we already have a valid Supabase session.
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        await authenticateWithSupabase();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('MetaMask startup failed: $e');
      reset();
    }
  }
}
