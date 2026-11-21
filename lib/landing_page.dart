import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'metamask_provider.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetamaskProvider>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 50, 100),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon / illustration
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 30,
                          offset: Offset(0, 10),
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    'Web3 Chat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.splineSansMono(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'A simple decentralized chat experience '
                    'powered by your Web3 wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 45),

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: MaterialButton(
                      onPressed: provider.isEnabled
                          ? () => provider.connect()
                          : null,
                      color: Colors.white,
                      disabledColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            provider.isEnabled
                                ? 'Connect MetaMask'
                                : 'MetaMask Not Available',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}