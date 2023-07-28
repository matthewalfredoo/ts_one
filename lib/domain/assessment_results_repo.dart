import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ts_one/data/assessments/assessment_results.dart';
import 'package:ts_one/data/assessments/assessment_variable_results.dart';
import 'package:ts_one/data/assessments/new_assessment.dart';
import 'package:ts_one/data/users/user_preferences.dart';
import 'package:ts_one/util/util.dart';

abstract class AssessmentResultsRepo {
  Future<List<AssessmentResults>> addAssessmentResults(
      List<AssessmentResults> assessmentResults, NewAssessment newAssessment);

  Future<List<AssessmentResults>> getAllAssessmentResults();

  Future<List<AssessmentResults>> getAssessmentResultsFilteredByDate(DateTime startDate, DateTime endDate);

  Future<List<AssessmentResults>> getAssessmentResultsByCurrentUserNotConfirm();

  Future<List<AssessmentResults>> getAssessmentResultsNotConfirmByCPTS();

  Future<List<AssessmentVariableResults>> getAssessmentVariableResult(String idAssessment);

  Future<void> updateAssessmentResultForExaminee(AssessmentResults assessmentResults);

  Future<List<AssessmentResults>> searchAssessmentResultsBasedOnName(String searchName, int searchLimit);

  Future<List<AssessmentResults>> getAllAssessmentResultsPaginated(
      int limit, AssessmentResults? lastAssessment, DateTime? filterStart, DateTime? filterEnd);

  Future<String> makePDFSimulator(AssessmentResults assessmentResults);
}

class AssessmentResultsRepoImpl implements AssessmentResultsRepo {
  AssessmentResultsRepoImpl({FirebaseFirestore? db, UserPreferences? userPreferences})
      : _db = db ?? FirebaseFirestore.instance,
        _userPreferences = userPreferences;

  final FirebaseFirestore? _db;
  final UserPreferences? _userPreferences;

  @override
  Future<List<AssessmentResults>> addAssessmentResults(
      List<AssessmentResults> assessmentResults, NewAssessment newAssessment) async {
    List<AssessmentResults> assessmentResultsList = AssessmentResults.extractDataFromNewAssessment(newAssessment);
    try {
      for (var assessmentResult in assessmentResultsList) {
        assessmentResult.id =
            "assessment-result-${assessmentResult.examineeStaffIDNo}-${Util.convertDateTimeDisplay(assessmentResult.date.toString())}";
        await _db!
            .collection(AssessmentResults.firebaseCollection)
            .doc(assessmentResult.id)
            .set(assessmentResult.toFirebase());

        for (var assessmentVariableResult in assessmentResult.variableResults) {
          assessmentVariableResult.id =
              "assessment-variable-result-${assessmentVariableResult.assessmentVariableId}-${assessmentResult.examineeStaffIDNo}-${Util.convertDateTimeDisplay(assessmentResult.date.toString())}";

          log("SINI ${assessmentVariableResult.id}");
          assessmentVariableResult.assessmentResultsId = assessmentResult.id;
          await _db!
              .collection(AssessmentVariableResults.firebaseCollection)
              .doc(assessmentVariableResult.id)
              .set(assessmentVariableResult.toFirebase());
        }
      }
    } catch (e) {
      log("Exception on assessment results repo: ${e.toString()}");
    }
    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAllAssessmentResults() async {
    List<AssessmentResults> assessmentResultsList = [];
    try {
      QuerySnapshot querySnapshot = await _db!.collection(AssessmentResults.firebaseCollection).get();

      for (var doc in querySnapshot.docs) {
        AssessmentResults assessmentResults = AssessmentResults.fromFirebase(doc.data() as Map<String, dynamic>);
        QuerySnapshot querySnapshot2 = await _db!
            .collection(AssessmentVariableResults.firebaseCollection)
            .where(AssessmentVariableResults.keyAssessmentResultsId, isEqualTo: assessmentResults.id)
            .get();

        for (var doc2 in querySnapshot2.docs) {
          AssessmentVariableResults assessmentVariableResults =
              AssessmentVariableResults.fromFirebase(doc2.data() as Map<String, dynamic>);
          assessmentResults.variableResults.add(assessmentVariableResults);
        }
        assessmentResultsList.add(assessmentResults);
      }
    } catch (e) {
      log("Exception on assessment results repo: ${e.toString()}");
    }
    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAssessmentResultsFilteredByDate(DateTime startDate, DateTime endDate) async {
    List<AssessmentResults> assessmentResultsList = [];
    try {
      QuerySnapshot querySnapshot = await _db!
          .collection(AssessmentResults.firebaseCollection)
          .where(AssessmentResults.keyDate, isGreaterThanOrEqualTo: startDate)
          .where(AssessmentResults.keyDate, isLessThanOrEqualTo: endDate)
          .get();

      for (var doc in querySnapshot.docs) {
        AssessmentResults assessmentResults = AssessmentResults.fromFirebase(doc.data() as Map<String, dynamic>);
        QuerySnapshot querySnapshot2 = await _db!
            .collection(AssessmentVariableResults.firebaseCollection)
            .where(AssessmentVariableResults.keyAssessmentResultsId, isEqualTo: assessmentResults.id)
            .get();

        for (var doc2 in querySnapshot2.docs) {
          AssessmentVariableResults assessmentVariableResults =
              AssessmentVariableResults.fromFirebase(doc2.data() as Map<String, dynamic>);
          assessmentResults.variableResults.add(assessmentVariableResults);
        }
        assessmentResultsList.add(assessmentResults);
      }
    } catch (e) {
      log("Exception on assessment results repo: ${e.toString()}");
    }
    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAssessmentResultsByCurrentUserNotConfirm() async {
    final userPreferences = _userPreferences;
    final userId = userPreferences!.getIDNo();
    int dummyUserId = 11720032;
    List<AssessmentResults> assessmentResults = [];

    try {
      await _db!
          .collection(AssessmentResults.firebaseCollection)
          .where(AssessmentResults.keyExamineeStaffIDNo, isEqualTo: dummyUserId)
          .where(AssessmentResults.keyConfirmedByExaminer, isEqualTo: false)
          .get()
          .then((value) {
        for (var element in value.docs) {
          assessmentResults.add(AssessmentResults.fromFirebase(element.data()));
        }
      });
    } catch (e) {
      log("Exception in AssessmentResultRepo on getAssessmentResultsByCurrentUserNotConfirm: $e");
    }
    return assessmentResults;
  }

  @override
  Future<List<AssessmentResults>> getAssessmentResultsNotConfirmByCPTS() async {
    List<AssessmentResults> assessmentResults = [];

    try {
      await _db!
          .collection(AssessmentResults.firebaseCollection)
          // .where(AssessmentResults.keyConfirmedByExaminer, isEqualTo: true)
          .where(AssessmentResults.keyConfirmedByInstructor, isEqualTo: true)
          .where(AssessmentResults.keyConfirmedByCPTS, isEqualTo: false)
          .get()
          .then((value) {
        for (var element in value.docs) {
          assessmentResults.add(AssessmentResults.fromFirebase(element.data()));
        }
      });
    } catch (e) {
      log("Exception in AssessmentResultRepo on getAssessmentResultsNotConfirmByCPTS: $e");
      log("Exception in AssessmentResultRepo on getAssessmentResultsByCurrentUserNotConfirm: $e");
    }

    return assessmentResults;
  }

  int assessmentVariableCollectionComparator(DocumentSnapshot a, DocumentSnapshot b) {
    final idA = int.tryParse(a.id.split('-')[4]); // Extract the numerical part from the ID of document A
    final idB = int.tryParse(b.id.split('-')[4]); // Extract the numerical part from the ID of document B

    if (idA != null && idB != null) {
      return idA.compareTo(idB);
    }
    return 0;
  }

  @override
  Future<List<AssessmentVariableResults>> getAssessmentVariableResult(String idAssessment) async {
    List<AssessmentVariableResults> assessmentVariableResults = [];

    try {
      final documents = await _db!
          .collection(AssessmentVariableResults.firebaseCollection)
          .where(AssessmentVariableResults.keyAssessmentResultsId, isEqualTo: idAssessment)
          .get()
          .then((value) {
        return value.docs;
      });

      documents.sort(assessmentVariableCollectionComparator);

      for (var element in documents) {
        assessmentVariableResults.add(AssessmentVariableResults.fromFirebase(element.data()));
      }
    } catch (e) {
      log("Exception in AssessmentResultRepo on getAssessmentVariableResult: $e");
    }

    return assessmentVariableResults;
  }

  @override
  Future<void> updateAssessmentResultForExaminee(AssessmentResults assessmentResults) async {
    try {
      await _db!
          .collection(AssessmentResults.firebaseCollection)
          .doc(assessmentResults.id)
          .update(assessmentResults.toFirebase());
    } catch (e) {
      log("Exception in AssessmentResultRepo on updateAssessmentResultForExaminee: $e");
    }
  }

  @override
  Future<List<AssessmentResults>> searchAssessmentResultsBasedOnName(String searchName, int searchLimit) async {
    List<AssessmentResults> assessmentResultsList = [];

    try {
      log("KAMU SEARCH NAME: $searchName");
      Query query = _db!
          .collection(AssessmentResults.firebaseCollection)
          .orderBy(AssessmentResults.keyNameExaminee)
          .limit(searchLimit)
          .startAt([searchName]).endAt(['$searchName\uf8ff']);

      final assessmentData = await query.get();

      assessmentResultsList =
          assessmentData.docs.map((e) => AssessmentResults.fromFirebase(e.data() as Map<String, dynamic>)).toList();

      log("JUMLAH SEARCH ${assessmentResultsList.length}");
    } catch (e) {
      log("Exception in AssessmentResultRepo on searchAssessmentResultsBasedOnName: $e");
    }

    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAllAssessmentResultsPaginated(
      int limit, AssessmentResults? lastAssessment, DateTime? filterStart, DateTime? filterEnd) async {
    List<AssessmentResults> assessmentResultsList = [];

    try {
      Query query;
      log("BRAPa jln ${filterStart.toString()} ${filterEnd.toString()}");
      if (filterStart != null && filterEnd != null) {
        query = _db!
            .collection(AssessmentResults.firebaseCollection)
            .where('date', isGreaterThanOrEqualTo: filterStart)
            .where('date', isLessThanOrEqualTo: filterEnd)
            .orderBy(AssessmentResults.keyDate, descending: true)
            .limit(limit);
      } else {
        query = _db!
            .collection(AssessmentResults.firebaseCollection)
            .orderBy(AssessmentResults.keyDate, descending: true)
            .limit(limit);
      }

      if (lastAssessment != null) {
        final lastDocumentAssessment =
            await _db!.collection(AssessmentResults.firebaseCollection).doc(lastAssessment.id).get();

        query = query.startAfterDocument(lastDocumentAssessment);
      }

      final assessmentData = await query.get();
      log("BRAPa ${assessmentData.docs.length}");
      // assessmentResultsList = assessmentData.docs
      //   .map((e) => AssessmentResults.fromFirebase(e.data() as Map<String, dynamic>))
      //   .toList();

      for (var element in assessmentData.docs) {
        assessmentResultsList.add(AssessmentResults.fromFirebase(element.data() as Map<String, dynamic>));
      }
    } catch (e) {
      log("Exception in AssessmentResultRepo on getAllAssessmentResultsPaginated: $e");
    }

    return assessmentResultsList;
  }

  @override
  Future<String> makePDFSimulator(AssessmentResults assessmentResults) async {
    List<String> listOfTrainingCheckingDetails = assessmentResults.trainingCheckingDetails;
    String flightDetails = assessmentResults.sessionDetails;

    try {
      // get temporary directory path
      Directory? tempDir = await getExternalStorageDirectory();

      // Load the existing PDF document.
      PdfDocument document =
          PdfDocument(inputBytes: File('${tempDir?.path}/QZ_TS1_SIM_04JUL2020_rev02.pdf').readAsBytesSync());

      // ============================= FOR CANDIDATE DETAIL ================================================

      List<String> pdfCandidateDetail = [
        "Other Crew Member Rank & Name.",
        "Rank & Name.",
        "License No.",
        "License Expiry",
        "Staff No.",
        "SIM ident.",
        "Aircraft Type.",
        "Airport & Route.",
        "Sim Hours",
        "Date (dd/mm/yyyy)"
      ];

      // For name
      List<MatchedItem> candidateDetailCollection = PdfTextExtractor(document).findText(pdfCandidateDetail);
      bool sameName = false;
      for (var matched in candidateDetailCollection) {
        Rect textbounds = matched.bounds;

        switch (matched.text) {
          case "Other Crew Member Rank & Name.":
            document.pages[0].graphics.drawString(
              "${assessmentResults.otherStaffRank}. ${assessmentResults.otherStaffName}",
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Rank & Name.":
            if (!sameName) {
              document.pages[0].graphics.drawString(
                "${assessmentResults.rank}. ${assessmentResults.examineeName}",
                PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                brush: PdfBrushes.black,
                bounds: Rect.fromLTWH(textbounds.topLeft.dx, textbounds.topLeft.dy + 8, 300, 50),
              );
              sameName = true;
            }
            break;

          case "License No.":
            document.pages[0].graphics.drawString(
              assessmentResults.examineeStaffIDNo.toString(),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "License Expiry":
            document.pages[0].graphics.drawString(
              Util.convertDateTimeDisplay(assessmentResults.licenseExpiry.toString()),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Staff No.":
            document.pages[0].graphics.drawString(
              assessmentResults.examineeStaffIDNo.toString(),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "SIM ident.":
            document.pages[0].graphics.drawString(
              assessmentResults.simIdent == "" ? "-" : assessmentResults.simIdent.toString(),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Aircraft Type.":
            document.pages[0].graphics.drawString(
              assessmentResults.aircraftType,
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Airport & Route.":
            document.pages[0].graphics.drawString(
              assessmentResults.airportAndRoute,
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Sim Hours":
            document.pages[0].graphics.drawString(
              assessmentResults.simulationHours,
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx + 3, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;

          case "Date (dd/mm/yyyy)":
            document.pages[0].graphics.drawString(
              Util.convertDateTimeDisplay(assessmentResults.date.toString()),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textbounds.topLeft.dx, textbounds.topLeft.dy + 8, 100, 50),
            );
            break;
        }
      }

      // ====================================== FOR TRAINING / CHECKING DETAILS ======================================

      //Find the text and get matched items.
      List<MatchedItem> listOfTrainingCheckingDetailsMatchedItemCollection =
          PdfTextExtractor(document).findText(listOfTrainingCheckingDetails);

      // Get the matched item in the collection using index.
      // MatchedItem matchedText = listOfTrainingCheckingDetailsMatchedItemCollection[0];

      // Loop for listOfTrainingCheckingDetailsMatchedItemCollection
      for (var matched in listOfTrainingCheckingDetailsMatchedItemCollection) {
        MatchedItem text = matched;
        Rect textBounds = text.bounds;

        // Draw pages 1 on Training / Checking Details
        document.pages[0].graphics.drawString(
            flightDetails.substring(0, 1), PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
            brush: PdfBrushes.black,
            bounds: Rect.fromLTWH(textBounds.topLeft.dx - 14, textBounds.topLeft.dy - 2, 100, 50));
      }

      // ====================================== FOR ASSESSMENT VARIABLES ==============================================
      List<AssessmentVariableResults> assessmentVariableResults = assessmentResults.variableResults;

      List<String> titleVariableResults =
          assessmentVariableResults.map((e) => e.assessmentVariableName.trim()).toList();

      //Find the text and get matched items.
      List<MatchedItem> flightAssessmentMatchedItemCollection =
          PdfTextExtractor(document).findText(titleVariableResults);

      List<String> uniqueText = [];
      List<MatchedItem> nonDuplicateMatchedItemVariable = [];

      for (MatchedItem item in flightAssessmentMatchedItemCollection) {
        if (!uniqueText.contains(item.text)) {
          uniqueText.add(item.text);
          nonDuplicateMatchedItemVariable.add(item);
        } else {
          if (item.text == "Precision Approaches") {
            nonDuplicateMatchedItemVariable.removeWhere((element) => element.text == item.text);
            nonDuplicateMatchedItemVariable.add(item);
          }
        }
      }

      for (var matchedVariable in nonDuplicateMatchedItemVariable) {
        MatchedItem text = matchedVariable;
        Rect textBounds = text.bounds;

        for (var assessment in assessmentVariableResults) {
          // Check if the assessment variable name is the same with the matched variable text
          if (assessment.assessmentVariableName.trim().toLowerCase() == matchedVariable.text.trim().toLowerCase()) {

            // Assessment Type = Satisfactory
            if (assessment.assessmentType == "Satisfactory") {
              if (assessment.isNotApplicable) {
                document.pages[0].graphics.drawString(
                    "v", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                    brush: PdfBrushes.black,
                    bounds: Rect.fromLTWH(textBounds.topLeft.dx + 163, textBounds.topLeft.dy - 2, 100, 50));
              } else {
                // For Satisfactory
                if (assessment.assessmentSatisfactory == "Satisfactory") {
                  document.pages[0].graphics.drawString(
                      "v", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                      brush: PdfBrushes.black,
                      bounds: Rect.fromLTWH(textBounds.topLeft.dx + 146, textBounds.topLeft.dy - 2, 100, 50));
                } else {
                  // FOR Unsatisfactory
                  document.pages[0].graphics.drawString(
                      "v", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                      brush: PdfBrushes.black,
                      bounds: Rect.fromLTWH(textBounds.topLeft.dx + 128, textBounds.topLeft.dy - 2, 100, 50));
                }

                // Assessment Markers
                switch (assessment.assessmentMarkers) {
                  case 1:
                    document.pages[0].graphics.drawString(
                        "1", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 180, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 2:
                    document.pages[0].graphics.drawString(
                        "2", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 200, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 3:
                    document.pages[0].graphics.drawString(
                        "3", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 220, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 4:
                    document.pages[0].graphics.drawString(
                        "4", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 238, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 5:
                    document.pages[0].graphics.drawString(
                        "5", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 255, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                }
              }

              // Assessment Type = PF/PM ========================================================
            } else if (assessment.assessmentType == "PF/PM") {
              if (assessment.isNotApplicable) {
                document.pages[0].graphics.drawString(
                    "v", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                    brush: PdfBrushes.black,
                    bounds: Rect.fromLTWH(textBounds.topLeft.dx + 124, textBounds.topLeft.dy - 2, 100, 50));
              } else {
                switch (assessment.pilotFlyingMarkers) {
                  case 1:
                    document.pages[0].graphics.drawString(
                        "1", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 140, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 2:
                    document.pages[0].graphics.drawString(
                        "2", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 155, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 3:
                    document.pages[0].graphics.drawString(
                        "3", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 170, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 4:
                    document.pages[0].graphics.drawString(
                        "4", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 185, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 5:
                    document.pages[0].graphics.drawString(
                        "5", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 200, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                }

                switch (assessment.pilotMonitoringMarkers) {
                  case 1:
                    document.pages[0].graphics.drawString(
                        "1", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 213, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 2:
                    document.pages[0].graphics.drawString(
                        "2", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 233, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 3:
                    document.pages[0].graphics.drawString(
                        "3", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 248, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 4:
                    document.pages[0].graphics.drawString(
                        "4", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 263, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                  case 5:
                    document.pages[0].graphics.drawString(
                        "5", PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                        brush: PdfBrushes.black,
                        bounds: Rect.fromLTWH(textBounds.topLeft.dx + 278, textBounds.topLeft.dy - 2, 100, 50));
                    break;
                }
              }
            }
          }
        }
      }

      // FOR MANUAL ASSESSMENT INPUT ==============================================================================================
      List<AssessmentVariableResults> manualVariableAircraftSystem = [];
      List<AssessmentVariableResults> manualVariableAbnormal = [];

      for (var ele in assessmentVariableResults) {
        if (ele.assessmentVariableCategory == "Aircraft System or Procedures" && ele.assessmentVariableName != "") {
          manualVariableAircraftSystem.add(ele);
        } else if (ele.assessmentVariableCategory == "Abnormal or Emer.Proc" && ele.assessmentVariableName != "") {
          manualVariableAbnormal.add(ele);
        }
      }

      List<String> textManual = ["Aircraft System/Procedures", "Abnormal/Emer.Proc"];

      List<MatchedItem> matchedManual = PdfTextExtractor(document)
          .findText(textManual, startPageIndex: 0);

      for (var value in matchedManual) {
        MatchedItem matchedItem = value;
        Rect textBounds = value.bounds;

        if (matchedItem.text == "Aircraft System/Procedures") {
          var minusBounds = 12;
          for (var manual in manualVariableAircraftSystem) {
            document.pages[0].graphics.drawString(
                manual.assessmentVariableName.toTitleCase(), PdfStandardFont(PdfFontFamily.helvetica, 7),
                brush: PdfBrushes.black,
                bounds: Rect.fromLTWH(textBounds.topLeft.dx, textBounds.topLeft.dy + minusBounds, 500, 300),
                format: PdfStringFormat(lineSpacing: 2));

            minusBounds += 10;
          }
        } else if (matchedItem.text == "Abnormal/Emer.Proc") {
          var minusBounds = 12;
          for (var manual in manualVariableAbnormal) {
            document.pages[0].graphics.drawString(
                manual.assessmentVariableName.toTitleCase(), PdfStandardFont(PdfFontFamily.helvetica, 7),
                brush: PdfBrushes.black,
                bounds: Rect.fromLTWH(textBounds.topLeft.dx, textBounds.topLeft.dy + minusBounds, 500, 300),
                format: PdfStringFormat(lineSpacing: 2));

            minusBounds += 10;
          }
        }
      }

      // ================================= PAGE 2 ========================================================

      // Overall Performance

      var overallPerformance = assessmentResults.overallPerformance.round();

      double coordinateFromLeft = 62.1;

      switch (overallPerformance.toString()) {
        case "1":
          coordinateFromLeft = 62.1;
          break;

        case "2":
          coordinateFromLeft = 167.1;
          break;

        case "3":
          coordinateFromLeft = 273.1;
          break;

        case "4":
          coordinateFromLeft = 383.1;
          break;

        case "5":
          coordinateFromLeft = 500.1;
          break;
      }

      // Overall Performance
      document.pages[1].graphics.drawString(
          "O", PdfStandardFont(PdfFontFamily.helvetica, 30, style: PdfFontStyle.bold),
          brush: PdfBrushes.black,
          bounds: Rect.fromLTWH(coordinateFromLeft, 46, 100, 50));

      // ======================================== FOR NOTES ====================================================
      List<MatchedItem> notes = PdfTextExtractor(document)
          .findText(["Notes"], startPageIndex: 1);

      for (var matchedVariable in notes) {
        MatchedItem matchedItem = matchedVariable;
        Rect textBounds = matchedItem.bounds;
        switch (matchedItem.text) {
          case "Notes":
            document.pages[1].graphics.drawString(
                assessmentResults.notes, PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
                brush: PdfBrushes.black,
                bounds: Rect.fromLTWH(textBounds.topLeft.dx, textBounds.topLeft.dy + 15, 500, 300),
                format: PdfStringFormat(lineSpacing: 6));
            break;
        }
      }

      List<String> signatureText = [
        "only if recommendations is made",
        "Candidate Name:",
        "Chief Pilot Training & Standards"
      ];
      List<MatchedItem> signatureMatchedItem = PdfTextExtractor(document).findText(signatureText, startPageIndex: 1);

      for (var item in signatureMatchedItem) {
        MatchedItem matchedItem = item;
        Rect textBounds = matchedItem.bounds;

        switch (matchedItem.text) {
          case "only if recommendations is made":
            var instructorSignatureUrl = assessmentResults.instructorSignatureUrl;
            var response = await get(Uri.parse(instructorSignatureUrl));
            var data = response.bodyBytes;

            PdfBitmap image = PdfBitmap(data);

            document.pages[1].graphics
                .drawImage(image, Rect.fromLTWH(textBounds.topLeft.dx, textBounds.center.dy - 50, 70, 50));
            break;

          case "Candidate Name:":
            document.pages[1].graphics.drawString(
              assessmentResults.examineeName,
              PdfStandardFont(PdfFontFamily.helvetica, 10),
              brush: PdfBrushes.black,
              bounds: Rect.fromLTWH(textBounds.topLeft.dx + 20, textBounds.topLeft.dy + 8, 300, 50),
            );

            if (assessmentResults.examineeSignatureUrl != "") {
              var instructorSignatureUrl = assessmentResults.examineeSignatureUrl;
              var response = await get(Uri.parse(instructorSignatureUrl));
              var data = response.bodyBytes;

              PdfBitmap image = PdfBitmap(data);
              document.pages[1].graphics
                  .drawImage(image, Rect.fromLTWH(textBounds.topLeft.dx, textBounds.center.dy - 70, 70, 50));
            }
            break;

          case "Chief Pilot Training & Standards":
            if (assessmentResults.cptsSignatureUrl != "") {
              var instructorSignatureUrl = assessmentResults.cptsSignatureUrl;
              var response = await get(Uri.parse(instructorSignatureUrl));
              var data = response.bodyBytes;

              PdfBitmap image = PdfBitmap(data);
              document.pages[1].graphics
                  .drawImage(image, Rect.fromLTWH(textBounds.topLeft.dx + 15, textBounds.center.dy + 20, 70, 50));
            }
            break;
        }
      }

      log("JALANJALAN");

      // ======================================== FOR DECLARATION ====================================================
      switch (assessmentResults.sessionDetails) {
        case NewAssessment.keySessionDetailsTraining:
          List<String> declarationTextTraining = [
            'Satisfactory',
            'Further Training Req.',
            'Cleared for Check',
            'Stop Training, TS7 Rised'
          ];
          List<MatchedItem> declarationMatchedItem =
          PdfTextExtractor(document).findText(declarationTextTraining, startPageIndex: 1);

          for (var item in declarationMatchedItem) {
            var textDeclaration = item.text;
            var boundsDeclarations = item.bounds;

            if (textDeclaration == assessmentResults.declaration) {
              document.pages[1].graphics.drawString(
                  "v", PdfStandardFont(PdfFontFamily.helvetica, 15, style: PdfFontStyle.bold),
                  brush: PdfBrushes.black,
                  bounds: Rect.fromLTWH(boundsDeclarations.topLeft.dx - 28, boundsDeclarations.topLeft.dy - 5, 100, 50));
            }
          }
          break;

        case NewAssessment.keySessionDetailsCheck:
          List<String> declarationTextCheck = [
            'PASS',
            'FAIL'
          ];
          List<MatchedItem> declarationMatchedItem =
          PdfTextExtractor(document).findText(declarationTextCheck, startPageIndex: 1);

          for (var item in declarationMatchedItem) {
            var textDeclaration = item.text;
            var boundsDeclarations = item.bounds;

            if (textDeclaration.toLowerCase().trim() == assessmentResults.declaration.toLowerCase().trim()) {
              document.pages[1].graphics.drawString(
                  "v", PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
                  brush: PdfBrushes.black,
                  bounds: Rect.fromLTWH(boundsDeclarations.topLeft.dx - 75, boundsDeclarations.topLeft.dy - 10, 100, 50));
            }
          }
          break;
      }

      log("AAAAAAAAAAAAAAAAAAAAAa");


      // Save into download directory

      // Save and dispose the document.
      String pathSavePDF =
          "/storage/emulated/0/Download/${assessmentResults.examineeName}-${Util.convertDateTimeDisplay(assessmentResults.date.toString())}.pdf";

      String cacheSavePDF =
          '${tempDir?.path}/${assessmentResults.examineeName}-${Util.convertDateTimeDisplay(assessmentResults.date.toString())}.pdf';

      var bytes = await document.save();

      File(pathSavePDF).writeAsBytesSync(bytes);

      File(cacheSavePDF).writeAsBytesSync(bytes);

      document.dispose();

      return cacheSavePDF;
    } catch (e) {
      log("Exception in AssessmentResultRepo on makePDFSimulator: $e");
    }
    return "Failed";
  }
}
