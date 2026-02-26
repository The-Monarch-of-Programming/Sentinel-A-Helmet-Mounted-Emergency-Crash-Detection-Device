
import 'package:flutter/material.dart';
import 'package:sentinel_app/login.dart';
import 'package:sentinel_app/signup.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(

          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(
                    "Welcome",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,

                    ),

                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text("Welcome to Sentinel! ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,

                    ),)
                ],
              ),
              Container(
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/welcome.png")
                    )
                ),
              ),

              Column(
                children: <Widget>[
                  // the login button
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));

                    },
                    color: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18
                      ),
                    ),
                  ),
                  // creating the signup button
                  SizedBox(height:20),
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> SignupPage()));

                    },
                    color: Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 18
                      ),
                    ),
                  )

                ],
              )



            ],
          ),
        ),
      ),
    );
  }
}