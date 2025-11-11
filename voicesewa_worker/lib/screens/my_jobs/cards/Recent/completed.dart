import 'package:flutter/material.dart';

class Completed extends StatefulWidget {
  const Completed({super.key});

  @override
  State<Completed> createState() => _CompletedState();
}

class _CompletedState extends State<Completed> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        margin:EdgeInsets.all(10),
        child: Column(
          children: [

            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:[
                Text("Task Name"),
                Container(
                  child: Text("completed"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("client name"),
                Text("Price (eg: rs 2001)"),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.location_pin),
              title:Text("Location of task to be done (eg: Kasarwadavli, G.B Road,Thane)"),
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text("Scehduled time (eg: 2:30 pm)"),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.info_outline),
                  label:Text("View Details"),
                  onPressed:(){},
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
