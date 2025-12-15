// STATIC DATA

// My Home Page
bool flag = false;

// Dashboard
class ChartData {
  final String year;
  final double amount;
  final bool isCurrent;
  ChartData(this.year, this.amount, {this.isCurrent = false});
}
final List<ChartData> chartData = [
  ChartData("2021", 12000),
  ChartData("2022", 18500),
  ChartData("2023", 24000),
  ChartData("2024", 22000),
  ChartData("2025", 35000, isCurrent: true),
];

// Find Work
class WorkPostData {
  final String title;
  final String description;
  final String priceRange;
  final List<String> tags;
  final String clientName;
  final double rating;
  final String location;
  final String distance;
  final String timePosted;

  WorkPostData({
    required this.title,
    required this.description,
    required this.priceRange,
    required this.tags,
    required this.clientName,
    required this.rating,
    required this.location,
    required this.distance,
    required this.timePosted,
  });
}
final List<WorkPostData> workList = [
  WorkPostData(
    title: "Electrical Wiring Repair",
    description: "Kitchen electrical outlet repair needed urgently. Sparks visible.",
    priceRange: "₹800-1200",
    tags: ["Urgent", "New"],
    clientName: "Mehta Family",
    rating: 4.8,
    location: "Kothrud, Pune",
    distance: "0.8 km away",
    timePosted: "30 minutes ago",
  ),
  WorkPostData(
    title: "Bathroom Plumbing",
    description: "Leaking tap and shower head installation in master bathroom.",
    priceRange: "₹600-900",
    tags: ["New"],
    clientName: "Sharma Residence",
    rating: 4.5,
    location: "Aundh, Pune",
    distance: "1.5 km away",
    timePosted: "1 hour ago",
  ),
  WorkPostData(
    title: "Full House Deep Cleaning",
    description: "3 BHK deep cleaning required before festival. Includes sofa shampooing.",
    priceRange: "₹2500-3000",
    tags: [],
    clientName: "Vikram Singh",
    rating: 4.9,
    location: "Viman Nagar, Pune",
    distance: "3.2 km away",
    timePosted: "3 hours ago",
  ),
];

// Rating
final double rating = 4.2;
final int starCount = 5;

// My Jobs Page
enum JobStatus { ongoing, pending, completed }
class Job {
  final String id;
  final String title;
  final String clientName;
  final String price;
  final String location;
  final String time;
  final JobStatus status;

  Job({
    required this.id,
    required this.title,
    required this.clientName,
    required this.price,
    required this.location,
    required this.time,
    required this.status
  });
}
final List<Job> myJobsData = [
  Job(
    id: '101',
    title: 'AC Repair & Service',
    clientName: 'Rahul Sharma',
    price: '₹1,500',
    location: 'Lodha Amara, Kolshet Road, Thane',
    time: '2:30 PM, Today',
    status: JobStatus.ongoing,
  ),
  Job(
    id: '102',
    title: 'Plumbing Inspection',
    clientName: 'Anjali Desai',
    price: '₹850',
    location: 'Hiranandani Estate, GB Road, Thane',
    time: '4:00 PM, Tomorrow',
    status: JobStatus.pending,
  ),
  Job(
    id: '103',
    title: 'House Deep Cleaning',
    clientName: 'Vikram Singh',
    price: '₹2,200',
    location: 'Vasant Vihar, Pokhran Road 2, Thane',
    time: '11:00 AM, Yesterday',
    status: JobStatus.completed,
  ),
  Job(
    id: '104',
    title: 'Fan Installation',
    clientName: 'Meera Kapoor',
    price: '₹400',
    location: 'Manpada, Thane West',
    time: '10:00 AM, 12 Dec',
    status: JobStatus.completed,
  ),
];

// Earnings Page

// Profile Page