import 'package:material_ui/material_ui.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'supabase_service.dart';

class MetamaskProvider extends ChangeNotifier {
  // 5 - Goerli was deprecated, 11155111 - Sepholia the one which is being used
  static const operatingChain = 11155111;

  String currentAddress = "";
  int currentChain = -1;
  bool get isEnabled => ethereum != null;
  bool get isInOperatingChain => currentChain == operatingChain; 
  bool get isConnected => isEnabled && currentAddress.isNotEmpty;

  Future<void> connect() async {
    if (isEnabled) {
      final access = await ethereum!.requestAccount();
      if(access.isNotEmpty) {
        currentAddress = access.first;
        currentChain = await ethereum!.getChainId();
        // check if the user has an account
        // if not we create it
        await SupabaseService.getOrCreateProfile(currentAddress);
        notifyListeners();
      }
    }
  }
  
  reset() {
    currentAddress = "";
    currentChain = -1;
    notifyListeners();
  }

  start() {
    if (isEnabled) {
      ethereum!.onAccountsChanged((accounts) { 
        reset(); 
      });
      ethereum!.onChainChanged((accounts) { 
        reset(); 
      });  
    }
  }
}