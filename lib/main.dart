import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'metamask_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    const MaterialApp(home: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    List<String> contacts = [
      "Dizi",
      "Joni",
      "Getoar",
      "Joan",
      "Geni",
      "Altini"
    ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 50, 100),
      body: ChangeNotifierProvider(
        create: (context) => MetamaskProvider()..start(),
        builder: (context, child) {
          return Center(child: Consumer<MetamaskProvider>(
            builder: (context, provider, child) {
              late final String message;
              if (provider.isConnected && provider.isInOperatingChain) {
                message = "Connected";
                return ListView(
                  padding: const EdgeInsets.all(30),
                  children: contacts.map((stringOne) {
                    return SizedBox(
                      width: 300,
                      height: 45,
                      // color: Colors.white,
                      child: Center(
                        child: ElevatedButton(
                          // hoverColor: const Color.fromARGB(255, 223, 180, 131),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    ChatPage(name: stringOne)));
                          },
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.fromLTRB(100, 0, 100, 0),
                              backgroundColor:
                                  const Color.fromARGB(255, 175, 96, 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          child: Text(
                            stringOne,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 236, 236),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else if (provider.isConnected && !provider.isInOperatingChain) {
                message =
                    'Wrong chain. Please connect to ${MetamaskProvider.operatingChain}';
              } else if (provider.isEnabled) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        "Welcome to Chat App!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.splineSansMono(
                            fontSize: 30, color: Colors.orange),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () =>
                          context.read<MetamaskProvider>().connect(),
                      color: Colors.indigo,
                      padding: const EdgeInsets.all(0),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1637597384338-61f51fa5cb07?auto=format&fit=crop&q=80&w=2069&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                          width: 300,
                        )
                      ]),
                    )
                  ],
                );
              } else {
                message = 'Please use a Web3 supported browser.';
              }
              return Text(
                message,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white),
              );
            },
          ));
        },
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Chat with $name",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber.shade900,
      ),
    );
  }
}
