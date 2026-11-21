import 'package:chat_app_web3/error_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_page.dart';
import 'landing_page.dart';
import 'metamask_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(
    const MaterialApp(
      title: 'Chat App',
      home: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetamaskProvider()..start(),
      child: Consumer<MetamaskProvider>(
        builder: (context, provider, child) {
          if (provider.isConnected && provider.isInOperatingChain) {
            return ChatPage(
              walletAddress: provider.currentAddress,
            );
          }

          if (provider.isConnected && !provider.isInOperatingChain) {
            return const ErrorPage(
                title: "Wrong Network",
                message:
                    "Your wallet is connected to an unsupported blockchain network.\n\n"
                    "Please switch to the Sepolia test network!",
                icon: Icons.warning_amber_rounded);
          }

          if (!provider.isEnabled) {
            return const ErrorPage(
                title: "Web3 Browser Required",
                message: 
                  "ChatApp requires a Web3 supported browser with \n "
                  "Metamask extension enabled to function. \n"
                  "Please check again that you are using both of these!",
                icon: Icons.language
            );
          }

          return const LandingPage();
        },
      ),
    );
  }
}
