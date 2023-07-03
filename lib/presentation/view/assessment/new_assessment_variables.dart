import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:provider/provider.dart';
import 'package:ts_one/data/assessments/assessment_flight_details.dart';
import 'package:ts_one/data/assessments/assessment_period.dart';
import 'package:ts_one/presentation/theme.dart';

import '../../../data/assessments/assessment_variables.dart';
import '../../../data/assessments/new_assessment.dart';
import '../../../util/util.dart';
import '../../view_model/assessment_viewmodel.dart';

class NewAssessmentVariables extends StatefulWidget {
  const NewAssessmentVariables(
      {Key? key,
      required this.assessmentFlightDetails,
      required this.dataCandidate})
      : super(key: key);

  final AssessmentFlightDetails assessmentFlightDetails;
  final NewAssessment dataCandidate;

  @override
  State<NewAssessmentVariables> createState() => _NewAssessmentVariablesState();
}

class _NewAssessmentVariablesState extends State<NewAssessmentVariables> {
  late AssessmentViewModel viewModel;
  late AssessmentPeriod dataAssessmentPeriod;
  late List<String> assessmentCategories;
  late Map<AssessmentVariables, bool> allAssessmentVariables;

  @override
  void initState() {
    viewModel = Provider.of<AssessmentViewModel>(context, listen: false);
    dataAssessmentPeriod = AssessmentPeriod();
    assessmentCategories = [];
    allAssessmentVariables = {};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAllAssessment();
    });

    super.initState();
  }

  void getAllAssessment() async {
    dataAssessmentPeriod =
        await viewModel.getAllAssessmentVariablesFromLastPeriod();

    print("size: ${dataAssessmentPeriod.assessmentVariables.length}");

    for (var assessmentVariable in dataAssessmentPeriod.assessmentVariables) {
      if (!assessmentCategories.contains(assessmentVariable.category)) {
        assessmentCategories.add(assessmentVariable.category);
      }
      allAssessmentVariables.addAll({assessmentVariable: false});
    }
    print("jlh: ${allAssessmentVariables.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentViewModel>(
      builder: (_, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "New Assessment",
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: model.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children:
                                _expansionTilesForNewAssessmentVariables(),
                          ),
                        ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    backgroundColor: TsOneColor.primary,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 48,
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Next",
                        style: TextStyle(color: TsOneColor.secondary),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _expansionTilesForNewAssessmentVariables() {
    List<Widget> expansionTilesVariables = [];

    // print("dadas: $assessmentVariables");
    print("JUMLAH: ${allAssessmentVariables.length}");
    for (var assessmentCategory in assessmentCategories) {
      // for (var data in allAssessmentVariables.keys) {
      //   if (data.category == assessmentCategory) {
      //     assessmentVariablesByCategory.addAll({assessmentVariable: false});
      //   }
      // }
      expansionTilesVariables.add(
        ExpansionTile(
          title: Text(assessmentCategory),
          backgroundColor: TsOneColor.primary,
          collapsedBackgroundColor: TsOneColor.surface,
          textColor: TsOneColor.onPrimary,
          collapsedTextColor: TsOneColor.onSecondary,
          iconColor: TsOneColor.onPrimary,
          collapsedIconColor: TsOneColor.onSecondary,
          collapsedShape: RoundedRectangleBorder(
            side: BorderSide(color: TsOneColor.primary.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(5.0),
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: TsOneColor.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(5.0),
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(5.0),
                  ),
                  color: TsOneColor.secondary),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  children: [
                    for (var data in allAssessmentVariables.keys)
                      if (data.category == assessmentCategory)
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                data.name,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  flex: 3,
                                  child: ListTileTheme(
                                    horizontalTitleGap: 0.0,
                                    contentPadding: EdgeInsets.zero,
                                    child: CheckboxListTile(
                                      value: allAssessmentVariables[data],
                                      contentPadding:
                                          const EdgeInsets.only(bottom: 10),
                                      dense: true,
                                      onChanged: (newValue) {
                                        setState(() {
                                          allAssessmentVariables[data] =
                                              newValue!;
                                        });
                                      },
                                      title: const Text("N/A"),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ),
                                if (data.typeOfAssessment == "Satisfactory")
                                  Flexible(
                                    flex: 7,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 5, bottom: 15),
                                            child: DropdownButtonFormField(
                                              padding: const EdgeInsets.all(0),
                                              isExpanded: false,
                                              isDense: true,
                                              onChanged: (value) {},
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                label: Text(
                                                  "Assessment",
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "Satisfactory",
                                                  child: Text(
                                                    "Satisfactory",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "Unsatisfactory",
                                                  child: Text(
                                                    "Unsatisfactory",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        Flexible(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 5, bottom: 15),
                                            child: DropdownButtonFormField(
                                              onChanged: (value) {},
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  hintMaxLines: 1,
                                                  label: Text(
                                                    "Markers",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  )),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "1",
                                                  child: Text(
                                                    "1",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "2",
                                                  child: Text(
                                                    "2",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "3",
                                                  child: Text(
                                                    "3",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "4",
                                                  child: Text(
                                                    "4",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "5",
                                                  child: Text(
                                                    "5",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                else
                                  Flexible(
                                    flex: 7,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 5, bottom: 15),
                                            child: DropdownButtonFormField(
                                              onChanged: (value) {},
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  hintMaxLines: 1,
                                                  label: Text(
                                                    "PF",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  )),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "1",
                                                  child: Text(
                                                    "1",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "2",
                                                  child: Text(
                                                    "2",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "3",
                                                  child: Text(
                                                    "3",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "4",
                                                  child: Text(
                                                    "4",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "5",
                                                  child: Text(
                                                    "5",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5,),
                                        Flexible(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 5, bottom: 15),
                                            child: DropdownButtonFormField(
                                              onChanged: (value) {},
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  hintMaxLines: 1,
                                                  label: Text(
                                                    "PM",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  )),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "1",
                                                  child: Text(
                                                    "1",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "2",
                                                  child: Text(
                                                    "2",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "3",
                                                  child: Text(
                                                    "3",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "4",
                                                  child: Text(
                                                    "4",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "5",
                                                  child: Text(
                                                    "5",
                                                    style:
                                                    TextStyle(fontSize: 12),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ],
                        )
                  ],
                ),
              ),
            )
          ],
        ),
      );
      expansionTilesVariables.add(const SizedBox(
        height: 15,
      ));
    }

    return expansionTilesVariables;
  }
}
