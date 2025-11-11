import 'package:flutter/material.dart';

class Rating extends StatefulWidget {
  const Rating({super.key});

  @override
  State<Rating> createState() => _RatingState();
}

class _RatingState extends State<Rating> {
  double rating = 4.2;
  int starCount = 5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
      margin: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SizedBox(height: 20),
            Text("Your Current Rating"),

            // SizedBox(height: 20),
            Center(
              child: Row(
                  children: List.generate(starCount, (index) => buildStar(context, index)),
                ),
            ),
            // SizedBox(height: 20),
              Text("$rating"),
            // SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
Widget buildStar(BuildContext context, int index) {
  Icon icon;
  if (index >= rating) {
    icon = Icon(Icons.star_border);
  } else if (index > rating - 1 && index < rating) {
    icon = Icon(Icons.star_half);
  } else {
    icon = Icon(Icons.star);
  }
  return icon;
}
}

