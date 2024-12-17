import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  await dotenv.load();
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier<GraphQLClient>(
        GraphQLClient(
          link: HttpLink(
              "${dotenv.env['PERMANENT_DOMAIN']}/api/${dotenv.env['API_VERSION']}/graphql.json",
              defaultHeaders: {
                'X-Shopify-Storefront-Access-Token':
                    dotenv.env['API_KEY'].toString()
              }),
          cache: GraphQLCache(store: HiveStore()),
        ),
      ),
      child: MaterialApp(
          title: dotenv.env['STORE_NAME']!,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const LoginPage()),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  Future<void> _login(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(r'''
					mutation customerAccessTokenCreate ($input: CustomerAccessTokenCreateInput!) {
						customerAccessTokenCreate(input: $input)  {
							customerAccessToken {
								accessToken
								expiresAt
							}
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
      variables: {
        'input': {
          'email': emailController.text,
          'password': passwordController.text,
        }
      },
    ));

    if (kDebugMode) {
      print(result);
    }

    List errors =
        result.data!['customerAccessTokenCreate']['customerUserErrors'];

    if (errors.isNotEmpty) {
      setState(() {
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! Message: ${errors[0]['message']}')));
      }
      return;
    }

    Map accessToken =
        result.data!['customerAccessTokenCreate']['customerAccessToken'];
    inspect(accessToken);
    // final prefs = await SharedPreferences.getInstance();

    // await prefs.setString('customer', jsonEncode({
    // 	'accessToken': accessToken['accessToken'],
    // 	'expiresAt': accessToken['expiresAt'],
    // }));

    if (context.mounted) {
      // context.read<CustomerModel>().getCustomer(context);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sucessfully logged-in! Please wait...'),
        duration: Duration(seconds: 3),
      ));
    }

    setState(() {
      _loading = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                    label: const Text('Email'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                    label: const Text('Password'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _login(context);
                    }
                  },
                  child: Text('Login')),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Register(),
                      )),
                  child: const Text('Sign up'))
            ],
          ),
        ),
      ),
    );
  }
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _register(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(r'''
					mutation customerCreate ($input: CustomerCreateInput!) {
						customerCreate(input: $input)  {
							customer {
								id
							}
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
      variables: {
        'input': {
          'firstName': fnameController.text,
          'lastName': lnameController.text,
          'email': emailController.text,
          'password': passwordController.text,
        }
      },
    ));

    if (kDebugMode) {
      print(result);
    }

    List errors = result.data!['customerCreate']['customerUserErrors'];

    if (errors.isNotEmpty) {
      setState(() {
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! Message: ${errors[0]['message']}')));
      }
      return;
    }

    // if (context.mounted) {
    //   _login(context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextFormField(
                controller: fnameController,
                decoration: InputDecoration(
                    label: const Text('First Name'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: lnameController,
                decoration: InputDecoration(
                    label: const Text('Last Name'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                    label: const Text('Email'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                    label: const Text('Password'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _register(context);
                    }
                  },
                  child: const Text('Sign up')),
            ],
          ),
        ),
      ),
    );
  }
}
