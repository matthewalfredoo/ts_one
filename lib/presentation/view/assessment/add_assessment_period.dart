import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ts_one/data/assessments/assessment_period.dart';
import 'package:ts_one/data/assessments/assessment_variables.dart';
import 'package:ts_one/presentation/theme.dart';
import 'package:ts_one/presentation/view_model/assessment_viewmodel.dart';
import 'package:ts_one/util/util.dart';

class AddAssessmentPeriodView extends StatefulWidget {
  const AddAssessmentPeriodView({Key? key}) : super(key: key);

  @override
  State<AddAssessmentPeriodView> createState() =>
      _AddAssessmentPeriodViewState();
}

class _AddAssessmentPeriodViewState extends State<AddAssessmentPeriodView> {
  late AssessmentViewModel viewModel;
  late AssessmentPeriod assessmentPeriod;
  final _formKey = GlobalKey<FormState>();
  late List<Map<String, TextEditingController>> controllers;
  late List<Map<String, Widget>> inputs;

  @override
  void initState() {
    viewModel = Provider.of<AssessmentViewModel>(context, listen: false);
    assessmentPeriod = AssessmentPeriod();
    controllers = [];
    inputs = [];

    super.initState();
  }

  void _selectDateAssessmentPeriod(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2006),
      lastDate: DateTime(2099),
      helpText: "Select effective period date",
    );
    if (picked != null && picked != assessmentPeriod.period) {
      setState(() {
        assessmentPeriod.period = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentViewModel>(builder: (_, model, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("New Form Assessment"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onTap: () {
                              _selectDateAssessmentPeriod(context);
                              FocusScope.of(context).unfocus();
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Effective date',
                            ),
                            controller: TextEditingController(
                                text: Util.convertDateTimeDisplay(
                                    assessmentPeriod.period.toString())
                            ),
                            readOnly: true,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _selectDateAssessmentPeriod(context);
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.calendar_today),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(
                            color: Colors.grey,
                            height: 36,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Variables to be assessed',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey,
                            height: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      child: SizedBox(
                        height: 200.0,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (var i = 0; i < inputs.length; i++)
                                Column(
                                  children: [
                                    inputs[i]["name"]!,
                                    inputs[i]["category"]!,
                                    inputs[i]["typeOfAssessment"]!,
                                    inputs[i]["applicableForFlight"]!,
                                    const Divider(
                                      color: Colors.grey,
                                      height: 36,
                                    ),
                                  ]
                                )
                            ],
                          ),
                        ),
                      )
                  ),
                  // row in a column
                  Expanded(
                    flex: 0,
                    child: SizedBox(
                      height: 88.0,
                      width: double.infinity,
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  // add the text field dynamically with the add button
                                  Expanded(
                                    child: SizedBox(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              if (inputs.isNotEmpty) {
                                                assessmentPeriod.assessmentVariables.removeLast();
                                                controllers.removeLast();
                                                inputs.removeLast();
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: tsOneColorScheme.secondary,
                                            foregroundColor: tsOneColorScheme.secondaryContainer,
                                            surfaceTintColor: tsOneColorScheme.secondary,
                                            minimumSize: const Size.fromHeight(40),
                                          ),
                                          child: const Icon(Icons.remove, color: TsOneColor.onSecondary)
                                      ),
                                    ),
                                  ),
                                  // button to delete the last text field
                                  Expanded(
                                    child: SizedBox(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _buildInput(inputs.length);
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: tsOneColorScheme.secondary,
                                            foregroundColor: tsOneColorScheme.secondaryContainer,
                                            surfaceTintColor: tsOneColorScheme.secondary,
                                            minimumSize: const Size.fromHeight(40),
                                          ),
                                          child: const Icon(Icons.add, color: TsOneColor.onSecondary)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  viewModel.addAssessmentPeriod(assessmentPeriod);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("Assessment period added successfully"),
                                        duration: const Duration(milliseconds: 1500),
                                        action: SnackBarAction(
                                          label: 'Close',
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                          },
                                        )
                                      )
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tsOneColorScheme.primary,
                                foregroundColor: tsOneColorScheme.primaryContainer,
                                surfaceTintColor: tsOneColorScheme.primary,
                                minimumSize: const Size.fromHeight(40),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: TsOneColor.onPrimary),
                              ),
                            ),
                          ),
                        ]
                      )
                    ),
                  ),
                ],
              ),
            )
        ),
      );
    },
    );
  }

  void _buildInput(int index) {
    // print("Message from AddAssessmentPeriodView: Index of assessmentVariables list $index");
    // print("Message from AddAssessmentPeriodView: Length of inputs list ${inputs.length}");

    // add new item of AssessmentVariable to AssessmentPeriod
    assessmentPeriod.assessmentVariables.add(
        AssessmentVariables());

    // add the text field
    final nameController = TextEditingController();
    final nameTextField = Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: TextFormField(
        controller: nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Name',
        ),
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter staff number';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (value) {
          setState(() {
            assessmentPeriod.assessmentVariables[index].name = value;
          });
        },
      ),
    );

    // add the dropdown field
    final categoryController = TextEditingController();
    final categoryDropdownField = Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Category',
        ),
        validator: (value) {
          if (value == null) {
            return "Category is required";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (value) {
          print("Bef. category value of ${assessmentPeriod.assessmentVariables[index].name}: ${assessmentPeriod.assessmentVariables[index].category}");
          setState(() {
            assessmentPeriod.assessmentVariables[index].category = value.toString();
          });
          print("Aft. category value of ${assessmentPeriod.assessmentVariables[index].name}: ${assessmentPeriod.assessmentVariables[index].category}");
          print("--------");
        },
        items: const [
          DropdownMenuItem(
            value: "Flight Preparation",
            child: Text("Flight Preparation"),
          ),
          DropdownMenuItem(
            value: "Takeoff",
            child: Text("Takeoff"),
          ),
          DropdownMenuItem(
            value: "Flight Maneuvers and Procedure",
            child: Text("Flight Maneuvers and Procedure"),
          ),
          DropdownMenuItem(
            value: "App. & Missed App. Procedures",
            child: Text("App. & Missed App. Procedures"),
          ),
          DropdownMenuItem(
            value: "Landing",
            child: Text("Landing"),
          ),
          DropdownMenuItem(
            value: "LVO Qualification / Checking",
            child: Text("LVO Qualification / Checking"),
          ),
          DropdownMenuItem(
            value: "SOP's",
            child: Text("SOP's"),
          ),
          DropdownMenuItem(
            value: "Advance Maneuvers",
            child: Text("Advance Maneuvers"),
          ),
          DropdownMenuItem(
            value: "Teamwork & Communication",
            child: Text("Teamwork & Communication"),
          ),
          DropdownMenuItem(
            value: "Leadership & Task Management",
            child: Text("Leadership & Task Management"),
          ),
          DropdownMenuItem(
            value: "Situational Awareness",
            child: Text("Situational Awareness"),
          ),
          DropdownMenuItem(
            value: "Decision Making",
            child: Text("Decision Making"),
          ),
          DropdownMenuItem(
            value: "Customer Focus",
            child: Text("Customer Focus"),
          ),
        ],
      ),
    );

    // add the dropdown field
    final typeOfAssessmentController = TextEditingController();
    final typeOfAssessmentDropdownField = Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Type of Assessment',
        ),
        validator: (value) {
          if (value == null) {
            return "Type of assessment is required";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (value) {
          print("Bef. type of assessment value of ${assessmentPeriod.assessmentVariables[index].name}: $value");
          setState(() {
            assessmentPeriod.assessmentVariables[index].typeOfAssessment = value.toString();
          });
          print("Aft. type of assessment value of ${assessmentPeriod.assessmentVariables[index].name}: ${assessmentPeriod.assessmentVariables[index].typeOfAssessment}");
          print("--------");
        },
        items: const [
          DropdownMenuItem(
            value: "Satisfactory",
            child: Text("Satisfactory"),
          ),
          DropdownMenuItem(
            value: "PF/PM",
            child: Text("PF/PM"),
          ),
        ],
      ),
    );

    // add the checkbox for applicable on flight TS-1 or not
    final applicableForFlight = Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: TsOneColor.onSecondary),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return CheckboxListTile(
              title: const Text('Applicable for Flight TS-1'),
              value: assessmentPeriod.assessmentVariables[index].applicableForFlight,
              onChanged: (value) {
                print("Message from AddAssessmentPeriodView: ${assessmentPeriod.assessmentVariables}");
                setState(() {
                  assessmentPeriod.assessmentVariables[index].applicableForFlight = value!;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: const BorderSide(color: TsOneColor.onPrimary),
              ),
            );
          }
        ),
      ),
    );

    controllers.add({
      'name': nameController,
      'category': categoryController,
      'typeOfAssessment': typeOfAssessmentController,
    });

    inputs.add({
      'name': nameTextField,
      'category': categoryDropdownField,
      'typeOfAssessment': typeOfAssessmentDropdownField,
      'applicableForFlight': applicableForFlight,
    });
  }
}
