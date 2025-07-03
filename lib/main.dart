import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(FreelancingApp());
}

// MyProposalsScreen: Shows proposals submitted by the current freelancer
class MyProposalsScreen extends StatefulWidget {
  @override
  _MyProposalsScreenState createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen> {
  List<Proposal> myProposals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProposals();
  }

  Future<void> _loadMyProposals() async {
    setState(() {
      isLoading = true;
    });
    myProposals = await DataService.getMyProposals();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Proposals')),
      body: RefreshIndicator(
        onRefresh: _loadMyProposals,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : myProposals.isEmpty
            ? Center(
                child: Text(
                  'No proposals submitted yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: myProposals.length,
                itemBuilder: (context, index) {
                  final proposal = myProposals[index];
                  final job = DataService._jobs.firstWhere(
                    (j) => j.id == proposal.jobId,
                    orElse: () => Job(
                      id: '',
                      title: 'Unknown Job',
                      description: '',
                      clientId: '',
                      clientName: '',
                      requiredSkills: [],
                      budget: 0,
                      deadline: '',
                      status: '',
                      createdAt: DateTime.now(),
                    ),
                  );
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(job.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bid: \$${proposal.bidAmount.toStringAsFixed(0)}',
                          ),
                          Text('Status: ${proposal.status}'),
                          Text(
                            'Submitted: ${proposal.submittedAt.day}/${proposal.submittedAt.month}/${proposal.submittedAt.year}',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// SubmitProposalScreen: Allows a freelancer to submit a proposal for a job
class SubmitProposalScreen extends StatefulWidget {
  final Job job;

  const SubmitProposalScreen({Key? key, required this.job}) : super(key: key);

  @override
  _SubmitProposalScreenState createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidAmountController = TextEditingController();
  final _coverLetterController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitProposal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = DataService.currentUser;
      Proposal proposal = Proposal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: widget.job.id,
        freelancerId: currentUser!.id,
        freelancerName: currentUser.name,
        bidAmount: double.parse(_bidAmountController.text),
        coverLetter: _coverLetterController.text,
        status: 'pending',
        submittedAt: DateTime.now(),
      );

      bool success = await DataService.submitProposal(proposal);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proposal submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit proposal')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Proposal')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.job.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _bidAmountController,
                decoration: InputDecoration(
                  labelText: 'Bid Amount (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your bid amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _coverLetterController,
                decoration: InputDecoration(
                  labelText: 'Cover Letter',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cover letter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Proposal',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FreelancingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freelancer Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models
class User {
  final String id;
  final String name;
  final String email;
  final String userType; // 'client' or 'freelancer'
  final String? profileImage;
  final String? bio;
  final List<String> skills;
  final double rating;
  final int completedProjects;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.profileImage,
    this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.completedProjects = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'rating': rating,
      'completedProjects': completedProjects,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      userType: json['userType'],
      profileImage: json['profileImage'],
      bio: json['bio'],
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedProjects: json['completedProjects'] ?? 0,
    );
  }
}

class Job {
  final String id;
  final String title;
  final String description;
  final String clientId;
  final String clientName;
  final List<String> requiredSkills;
  final double budget;
  final String deadline;
  final String status; // 'open', 'in_progress', 'completed'
  final DateTime createdAt;
  final String? freelancerId;
  final String? freelancerName;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.requiredSkills,
    required this.budget,
    required this.deadline,
    required this.status,
    required this.createdAt,
    this.freelancerId,
    this.freelancerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'clientId': clientId,
      'clientName': clientName,
      'requiredSkills': requiredSkills,
      'budget': budget,
      'deadline': deadline,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
    };
  }

  static Job fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      requiredSkills: List<String>.from(json['requiredSkills']),
      budget: (json['budget']).toDouble(),
      deadline: json['deadline'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      freelancerId: json['freelancerId'],
      freelancerName: json['freelancerName'],
    );
  }
}

class Proposal {
  final String id;
  final String jobId;
  final String freelancerId;
  final String freelancerName;
  final double bidAmount;
  final String coverLetter;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime submittedAt;

  Proposal({
    required this.id,
    required this.jobId,
    required this.freelancerId,
    required this.freelancerName,
    required this.bidAmount,
    required this.coverLetter,
    required this.status,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
      'bidAmount': bidAmount,
      'coverLetter': coverLetter,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  static Proposal fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'],
      jobId: json['jobId'],
      freelancerId: json['freelancerId'],
      freelancerName: json['freelancerName'],
      bidAmount: (json['bidAmount']).toDouble(),
      coverLetter: json['coverLetter'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }
}

// Data Service (Mock API)
class DataService {
  static List<User> _users = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      userType: 'client',
      bio: 'Looking for talented developers',
      completedProjects: 15,
      rating: 4.5,
    ),
    User(
      id: '2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      userType: 'freelancer',
      bio: 'Full Stack Developer with 5+ years experience',
      skills: ['Flutter', 'Python', 'Django', 'PostgreSQL'],
      completedProjects: 25,
      rating: 4.8,
    ),
    User(
      id: '3',
      name: 'Alex Johnson',
      email: 'alex@example.com',
      userType: 'freelancer',
      bio: 'UI/UX Designer passionate about creating beautiful interfaces',
      skills: ['UI/UX Design', 'Figma', 'Adobe XD', 'Photoshop'],
      completedProjects: 20,
      rating: 4.6,
    ),
  ];

  static List<Job> _jobs = [
    Job(
      id: '1',
      title: 'Flutter Mobile App Development',
      description:
          'Need a Flutter developer to build a cross-platform mobile app for food delivery.',
      clientId: '1',
      clientName: 'John Doe',
      requiredSkills: ['Flutter', 'Dart', 'Firebase'],
      budget: 2500.0,
      deadline: '2024-08-15',
      status: 'open',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Job(
      id: '2',
      title: 'Django REST API Development',
      description:
          'Looking for a Python developer to create REST APIs for an e-commerce platform.',
      clientId: '1',
      clientName: 'John Doe',
      requiredSkills: ['Python', 'Django', 'PostgreSQL', 'REST API'],
      budget: 1800.0,
      deadline: '2024-08-30',
      status: 'open',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Job(
      id: '3',
      title: 'UI/UX Design for Web Application',
      description:
          'Need a designer to create modern and intuitive UI/UX for a SaaS platform.',
      clientId: '1',
      clientName: 'John Doe',
      requiredSkills: ['UI/UX Design', 'Figma', 'Prototyping'],
      budget: 1200.0,
      deadline: '2024-09-10',
      status: 'in_progress',
      freelancerId: '3',
      freelancerName: 'Alex Johnson',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
  ];

  static List<Proposal> _proposals = [
    Proposal(
      id: '1',
      jobId: '1',
      freelancerId: '2',
      freelancerName: 'Jane Smith',
      bidAmount: 2300.0,
      coverLetter:
          'I have extensive experience in Flutter development and would love to work on this project.',
      status: 'pending',
      submittedAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Proposal(
      id: '2',
      jobId: '3',
      freelancerId: '3',
      freelancerName: 'Alex Johnson',
      bidAmount: 1200.0,
      coverLetter:
          'I specialize in UI/UX design and have worked on similar SaaS projects.',
      status: 'accepted',
      submittedAt: DateTime.now().subtract(Duration(days: 3)),
    ),
  ];

  static User? _currentUser;

  static Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call

    try {
      User user = _users.firstWhere((u) => u.email == email);
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
    String userType,
  ) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call

    String newId = (_users.length + 1).toString();
    User newUser = User(
      id: newId,
      name: name,
      email: email,
      userType: userType,
      bio: userType == 'client'
          ? 'Looking for talented freelancers'
          : 'Ready to work on exciting projects',
    );

    _users.add(newUser);
    _currentUser = newUser;
    return true;
  }

  static void logout() {
    _currentUser = null;
  }

  static User? get currentUser => _currentUser;

  static Future<List<Job>> getJobs() async {
    await Future.delayed(Duration(milliseconds: 500));
    return _jobs;
  }

  static Future<List<Job>> getMyJobs() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (_currentUser?.userType == 'client') {
      return _jobs.where((job) => job.clientId == _currentUser!.id).toList();
    } else {
      return _jobs
          .where((job) => job.freelancerId == _currentUser!.id)
          .toList();
    }
  }

  static Future<List<Proposal>> getProposals(String jobId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _proposals.where((p) => p.jobId == jobId).toList();
  }

  static Future<List<Proposal>> getMyProposals() async {
    await Future.delayed(Duration(milliseconds: 500));
    return _proposals.where((p) => p.freelancerId == _currentUser!.id).toList();
  }

  static Future<bool> createJob(Job job) async {
    await Future.delayed(Duration(milliseconds: 500));
    _jobs.add(job);
    return true;
  }

  static Future<bool> submitProposal(Proposal proposal) async {
    await Future.delayed(Duration(milliseconds: 500));
    _proposals.add(proposal);
    return true;
  }

  static Future<bool> acceptProposal(String proposalId) async {
    await Future.delayed(Duration(milliseconds: 500));

    int proposalIndex = _proposals.indexWhere((p) => p.id == proposalId);
    if (proposalIndex != -1) {
      Proposal proposal = _proposals[proposalIndex];

      // Update proposal status
      _proposals[proposalIndex] = Proposal(
        id: proposal.id,
        jobId: proposal.jobId,
        freelancerId: proposal.freelancerId,
        freelancerName: proposal.freelancerName,
        bidAmount: proposal.bidAmount,
        coverLetter: proposal.coverLetter,
        status: 'accepted',
        submittedAt: proposal.submittedAt,
      );

      // Update job status
      int jobIndex = _jobs.indexWhere((j) => j.id == proposal.jobId);
      if (jobIndex != -1) {
        Job job = _jobs[jobIndex];
        _jobs[jobIndex] = Job(
          id: job.id,
          title: job.title,
          description: job.description,
          clientId: job.clientId,
          clientName: job.clientName,
          requiredSkills: job.requiredSkills,
          budget: job.budget,
          deadline: job.deadline,
          status: 'in_progress',
          createdAt: job.createdAt,
          freelancerId: proposal.freelancerId,
          freelancerName: proposal.freelancerName,
        );
      }

      return true;
    }
    return false;
  }

  static Future<List<User>> getFreelancers() async {
    await Future.delayed(Duration(milliseconds: 500));
    return _users.where((u) => u.userType == 'freelancer').toList();
  }
}

// Screens
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Freelancer Hub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Connect. Work. Succeed.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      bool success = await DataService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              Center(
                child: Icon(Icons.work_outline, size: 80, color: Colors.blue),
              ),
              SizedBox(height: 40),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Demo Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Client: john@example.com',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Freelancer: jane@example.com',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Password: any password',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = 'freelancer';
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      bool success = await DataService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _selectedUserType,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Join our freelancing community',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Freelancer'),
                            subtitle: Text('Looking for work'),
                            value: 'freelancer',
                            groupValue: _selectedUserType,
                            onChanged: (value) {
                              setState(() {
                                _selectedUserType = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: Text('Client'),
                            subtitle: Text('Looking to hire'),
                            value: 'client',
                            groupValue: _selectedUserType,
                            onChanged: (value) {
                              setState(() {
                                _selectedUserType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = DataService.currentUser;

    List<Widget> pages = [
      JobsScreen(),
      if (currentUser?.userType == 'freelancer') FreelancersScreen(),
      if (currentUser?.userType == 'client') MyJobsScreen(),
      if (currentUser?.userType == 'freelancer') MyProposalsScreen(),
      ProfileScreen(),
    ];

    List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
      if (currentUser?.userType == 'freelancer')
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Freelancers'),
      if (currentUser?.userType == 'client')
        BottomNavigationBarItem(
          icon: Icon(Icons.my_library_books),
          label: 'My Jobs',
        ),
      if (currentUser?.userType == 'freelancer')
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Proposals',
        ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: navItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class JobsScreen extends StatefulWidget {
  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<Job> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      isLoading = true;
    });

    List<Job> fetchedJobs = await DataService.getJobs();

    setState(() {
      jobs = fetchedJobs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = DataService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Jobs'),
        actions: [
          if (currentUser?.userType == 'client')
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CreateJobScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : jobs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No jobs available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  Job job = jobs[index];
                  return JobCard(
                    job: job,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({Key? key, required this.job, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'by ${job.clientName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(job.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                job.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: job.requiredSkills.map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${job.budget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        job.deadline,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  List<Proposal> proposals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    setState(() {
      isLoading = true;
    });

    List<Proposal> fetchedProposals = await DataService.getProposals(
      widget.job.id,
    );

    setState(() {
      proposals = fetchedProposals;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = DataService.currentUser;
    bool isClient = currentUser?.userType == 'client';
    bool isJobOwner = currentUser?.id == widget.job.clientId;
    bool canSubmitProposal =
        currentUser?.userType == 'freelancer' &&
        widget.job.status == 'open' &&
        !proposals.any((p) => p.freelancerId == currentUser?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
        actions: [
          if (canSubmitProposal)
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubmitProposalScreen(job: widget.job),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.job.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.job.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.job.status.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Posted by ${widget.job.clientName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green[600]),
                        SizedBox(width: 8),
                        Text(
                          '\$${widget.job.budget.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                        SizedBox(width: 24),
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          widget.job.deadline,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.job.description,
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Required Skills
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Skills',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.job.requiredSkills.map((skill) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Proposals Section (for clients)
            if (isClient && isJobOwner) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Proposals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${proposals.length}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (isLoading)
                        Center(child: CircularProgressIndicator())
                      else if (proposals.isEmpty)
                        Text(
                          'No proposals yet',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: proposals.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            Proposal proposal = proposals[index];
                            return ProposalCard(
                              proposal: proposal,
                              onAccept: () async {
                                bool success = await DataService.acceptProposal(
                                  proposal.id,
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Proposal accepted'),
                                    ),
                                  );
                                  _loadProposals();
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final VoidCallback onAccept;

  const ProposalCard({Key? key, required this.proposal, required this.onAccept})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                proposal.freelancerName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(proposal.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  proposal.status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '\$${proposal.bidAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            proposal.coverLetter,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted ${_formatDate(proposal.submittedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (proposal.status == 'pending')
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(80, 32),
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// FreelancersScreen: Shows a list of all freelancers
class FreelancersScreen extends StatefulWidget {
  @override
  _FreelancersScreenState createState() => _FreelancersScreenState();
}

class _FreelancersScreenState extends State<FreelancersScreen> {
  List<User> freelancers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFreelancers();
  }

  Future<void> _loadFreelancers() async {
    setState(() {
      isLoading = true;
    });
    freelancers = await DataService.getFreelancers();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Freelancers')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : freelancers.isEmpty
          ? Center(child: Text('No freelancers found'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: freelancers.length,
              itemBuilder: (context, index) {
                final freelancer = freelancers[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        freelancer.name.isNotEmpty ? freelancer.name[0] : '?',
                      ),
                    ),
                    title: Text(freelancer.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (freelancer.skills.isNotEmpty)
                          Text('Skills: ${freelancer.skills.join(', ')}'),
                        Text(
                          'Completed Projects: ${freelancer.completedProjects}',
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(freelancer.rating.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

// MyJobsScreen: Shows jobs posted by the current client
class MyJobsScreen extends StatefulWidget {
  @override
  _MyJobsScreenState createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<Job> myJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  Future<void> _loadMyJobs() async {
    setState(() {
      isLoading = true;
    });
    myJobs = await DataService.getMyJobs();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Jobs')),
      body: RefreshIndicator(
        onRefresh: _loadMyJobs,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : myJobs.isEmpty
            ? Center(
                child: Text(
                  'No jobs posted yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: myJobs.length,
                itemBuilder: (context, index) {
                  final job = myJobs[index];
                  return JobCard(
                    job: job,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

// ProfileScreen: Shows the current user's profile and logout option
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = DataService.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('No user logged in')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              DataService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              user.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              user.userType == 'client' ? 'Client' : 'Freelancer',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 16),
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(user.bio!, style: TextStyle(fontSize: 16)),
            if (user.skills.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: user.skills
                    .map((skill) => Chip(label: Text(skill)))
                    .toList(),
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(user.rating.toStringAsFixed(1)),
                SizedBox(width: 16),
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 4),
                Text('Completed: ${user.completedProjects}'),
              ],
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  DataService.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Continue with remaining screens...
class CreateJobScreen extends StatefulWidget {
  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _skillsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = DataService.currentUser;
      List<String> skills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      Job newJob = Job(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        clientId: currentUser!.id,
        clientName: currentUser.name,
        requiredSkills: skills,
        budget: double.parse(_budgetController.text),
        deadline: _deadlineController.text,
        status: 'open',
        createdAt: DateTime.now(),
      );

      bool success = await DataService.createJob(newJob);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Job created successfully')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create job')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Job')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: 'Deadline (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a deadline';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: InputDecoration(
                  labelText: 'Required Skills (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Flutter, Dart, Firebase',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter required skills';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Job',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
