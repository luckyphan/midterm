import 'package:midterm/Screens/home_view.dart';
import 'driver.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authenticate {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _verificationId = '';

  @override
  authorize() {
    return _auth;
  }

  authorizedUser() {
    return _auth.currentUser;
  }

  user() {
    User? user = _auth.currentUser;
    String id = user!.uid;
    return id;
  }

  void anonSignIn(context) async {
    await _auth.signInAnonymously().then((result) {
      final User? user = result.user;
    }).then((value) => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (con) => AppDriver())));
  }

  void signInWithEmailAndPassword(_email, _password, context) async {
    await Firebase.initializeApp();
    try {
      UserCredential uid = await _auth.signInWithEmailAndPassword(
          email: _email, password: _password);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => AppDriver()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Wrong password")));
      } else if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not found")));
      }
    } catch (e) {
      print(e);
    }
  }

  void signInOnlyEmail(_email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("mail", _email);
    await _auth.sendSignInLinkToEmail(
      email: _email,
      actionCodeSettings: ActionCodeSettings(
          url: "https://midterm1.page.link/29hQ",
          androidPackageName: "com.example.midterm",
          iOSBundleId: "com.example.midterm",
          handleCodeInApp: true,
          androidMinimumVersion: "16",
          androidInstallApp: true),
    );
  }

  handleLink(Uri link, _email, context) async {
    if (link != null) {
      final user = (await _auth.signInWithEmailLink(
        email: _email,
        emailLink: link.toString(),
      ))
          .user;
      if (user != null) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<void> phoneSignIn(_phoneNumber, context) async {
    PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      print("Failed: $authException");
    };

    PhoneCodeSent codeSent = (String verificationId, [int? resendToken]) async {
      _verificationId = verificationId;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("verid", verificationId);
      print("code sent");
    };

    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
      timeout: const Duration(seconds: 30),
      verificationCompleted: (AuthCredential credential) async {
        UserCredential result = await _auth.signInWithCredential(credential);

        User? user = result.user;

        if (user != null) {
          print(user.uid);
        }
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void signInPhone(_sms, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: await prefs.getString("verid")!,
        smsCode: _sms,
      );
      print(credential);
      final User? user = (await _auth.signInWithCredential(credential)).user;
    } catch (e) {
      print("rrr$e");
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  void googleSignIn(context) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('user')
        .where('first_name', isEqualTo: googleUser.displayName)
        .limit(1)
        .get();
    final List<DocumentSnapshot> docs = result.docs;
    if (docs.isEmpty) {
      print("empty");
      try {
        _db
            .collection("user")
            .doc()
            .set({
              "first_name": googleUser.displayName,
              "last_name": "",
              "phone": '',
              "role": 'customer',
              "url": '',
              "uid": googleUser.id,
              "register_date": DateTime.now(),
              "age": ' ',
              "bio": ' ',
              "hometown": ' ',
            })
            .then((value) => null)
            .onError((error, stackTrace) => null);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (con) => AppDriver()));
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error")));
      } catch (e) {
        print(e);
      }
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (con) => AppDriver()));
    }
  }

  void facebookSignIn(context) async {
    try {
      final LoginResult fbUser = await FacebookAuth.instance.login();
      final AuthCredential facebookCredential =
          FacebookAuthProvider.credential(fbUser.accessToken!.token);

      final userCredential =
          await _auth.signInWithCredential(facebookCredential);
      final User? user = userCredential.user;

      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('user')
          .where('first_name', isEqualTo: user!.displayName)
          .limit(1)
          .get();
      final List<DocumentSnapshot> docs = result.docs;
      if (docs.isEmpty) {
        print("empty");
        try {
          _db
              .collection("user")
              .doc()
              .set({
                "first_name": user.displayName,
                "last_name": "",
                "phone": '',
                "role": 'customer',
                "url": user.photoURL,
                "uid": user.uid,
                "register_date": DateTime.now(),
                "age": ' ',
                "bio": ' ',
                "hometown": ' ',
              })
              .then((value) => null)
              .onError((error, stackTrace) => null);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (con) => AppDriver()));
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Error")));
        } catch (e) {
          print(e);
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (con) => HomePage()));
      }
    } catch (e) {
      print("rrr$e");
    }
  }

  void signOut(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Log Out"),
            content: Text("Are you sure you want to log out?"),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await _auth.signOut();
                  await GoogleSignIn().signOut();
                  await FacebookAuth.instance.logOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User logged out.')));
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (con) => AppDriver()));
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
                child: Text("Yes"),
              ),
            ],
          );
        });
  }
}
