import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'online_consult_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final String? filterSpecialization;

  const AppointmentScreen({super.key, this.filterSpecialization});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);

    List<dynamic> doctors = data.doctors;
    if (widget.filterSpecialization != null) {
      doctors = doctors
          .where((doc) => doc['specialization'] == widget.filterSpecialization)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doc = doctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(doc['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['specialization']),
                        if (doc['availableNow'] == true)
                          const Text('Online Now', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showBookingOptions(context, doc, data);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showBookingOptions(BuildContext context, dynamic doc, DataProvider data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Book with ${doc['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (doc['availableNow'] == true)
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text('Consult Now (Online)'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    _initiateBookingProcess(context, doc, data, isOnline: true);
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Book Offline Clinic Visit'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  Navigator.pop(context);
                  _showOfflineSlots(context, doc, data);
                },
              )
            ],
          ),
        );
      },
    );
  }

  void _showOfflineSlots(BuildContext context, dynamic doc, DataProvider data) {
    List<dynamic> dates = doc['availableDates'] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: dates.isEmpty ? const Center(child: Text("No offline slots available")) : ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final dateObj = dates[i];
              List<dynamic> slots = dateObj['slots'] ?? [];
              return ExpansionTile(
                title: Text(dateObj['date']),
                children: slots.map((slot) {
                  return ListTile(
                    title: Text(slot),
                    trailing: ElevatedButton(
                      child: const Text('Book'),
                      onPressed: () {
                        Navigator.pop(context);
                        _initiateBookingProcess(context, doc, data, isOnline: false, date: dateObj['date'], slot: slot);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          )
        );
      },
    );
  }

  void _initiateBookingProcess(BuildContext context, dynamic doc, DataProvider data, {required bool isOnline, String? date, String? slot}) {
    // 1. Ask for patient details
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    bool isOtherPerson = false;
    TextEditingController nameCtrl = TextEditingController(text: auth.name);
    TextEditingController ageCtrl = TextEditingController();
    String gender = 'Male';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Patient Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text("Booking for someone else?"),
                      value: isOtherPerson,
                      onChanged: (val) {
                        setState(() {
                          isOtherPerson = val ?? false;
                          if (!isOtherPerson) {
                            nameCtrl.text = auth.name ?? '';
                          } else {
                            nameCtrl.clear();
                          }
                        });
                      },
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Patient Name'),
                      enabled: isOtherPerson,
                    ),
                    TextField(
                      controller: ageCtrl,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      items: ['Male', 'Female', 'Other'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          gender = val!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || ageCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }

                    int age = int.tryParse(ageCtrl.text) ?? 0;
                    Navigator.pop(context);

                    if (isOnline) {
                      // Show loading while booking
                      showDialog(context: context, barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()));
                      try {
                        final res = await data.bookOnline(doc['_id'], nameCtrl.text, age, gender);
                        if (context.mounted) Navigator.pop(context); // close loading
                        if (res.containsKey('_id')) {
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineConsultScreen(
                              appointmentId: res['_id'],
                              doctorId: doc['_id'],
                              doctorName: doc['name'],
                              pName: nameCtrl.text,
                              pAge: age,
                              pGender: gender,
                            )));
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Booking failed'), backgroundColor: Colors.red));
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    } else {
                      _processOfflineBooking(context, doc, data, date!, slot!, nameCtrl.text, age, gender);
                    }
                  },
                  child: const Text('Confirm Booking'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _processOfflineBooking(BuildContext context, dynamic doc, DataProvider data, String date, String slot, String pName, int pAge, String pGender) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final res = await data.bookOffline(doc['_id'], date, slot, pName, pAge, pGender);
      Navigator.pop(context); // pop loading

      // Show Receipt
      if(context.mounted){
         _showReceipt(context, doc['name'], date, slot, pName, pAge, pGender, res['_id'] ?? 'Pending');
      }
    } catch (e) {
      Navigator.pop(context); // pop loading
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Failed: $e')));
      }
    }
  }

  void _showReceipt(BuildContext context, String docName, String date, String slot, String pName, int pAge, String pGender, String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Receipt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor: $docName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Text('Patient: $pName'),
              Text('Age: $pAge  |  Gender: $pGender'),
              if (pAge < 18) const Text('(Minor Patient)', style: TextStyle(color: Colors.red, fontSize: 12)),
              const Divider(),
              Text('Date: $date'),
              Text('Time: $slot'),
              const Divider(),
              Text('Booking ID: $bookingId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close receipt
              },
              child: const Text('Done'),
            )
          ],
        );
      }
    );
  }
}
