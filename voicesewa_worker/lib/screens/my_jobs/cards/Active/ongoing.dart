import "package:flutter/material.dart";

class Ongoing extends StatefulWidget {
  const Ongoing({super.key});

  @override
  State<Ongoing> createState() => _OngoingState();
}

class _OngoingState extends State<Ongoing> {
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
                  child: Text("ongoing"),
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
              // spacing: 8,
              // runSpacing: 4,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.phone),
                  label:Text("Call client"),
                  onPressed:(){},
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.info_outline),
                  label:Text("View Details"),
                  onPressed:(){},
                ),
              ],
            ),
                ElevatedButton(
                  child:Text("Mark As Completed"),
                  onPressed:(){},
                ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}