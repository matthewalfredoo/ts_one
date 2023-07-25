import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ts_one/data/assessments/assessment_results.dart';
import 'package:ts_one/data/assessments/assessment_variable_results.dart';
import 'package:ts_one/data/assessments/new_assessment.dart';
import 'package:ts_one/data/users/user_preferences.dart';
import 'package:ts_one/util/util.dart';

abstract class AssessmentResultsRepo{
  Future<List<AssessmentResults>> addAssessmentResults(List<AssessmentResults> assessmentResults, NewAssessment newAssessment);

  Future<List<AssessmentResults>> getAllAssessmentResults();

  Future<List<AssessmentResults>> getAssessmentResultsFilteredByDate(DateTime startDate, DateTime endDate);

  Future<List<AssessmentResults>> getAssessmentResultsByCurrentUserNotConfirm();

  Future<List<AssessmentResults>> getAssessmentResultsNotConfirmByCPTS();

  Future<List<AssessmentVariableResults>> getAssessmentVariableResult(String idAssessment);

  Future<void> updateAssessmentResultForExaminee(AssessmentResults assessmentResults);

  Future<List<AssessmentResults>> getAllAssessmentResultsPaging(int startAt, String sortBy);
}

class AssessmentResultsRepoImpl implements AssessmentResultsRepo {
  AssessmentResultsRepoImpl({
    FirebaseFirestore? db, UserPreferences? userPreferences
  }) : _db = db ?? FirebaseFirestore.instance, _userPreferences = userPreferences;

  final FirebaseFirestore? _db;
  final UserPreferences? _userPreferences;

  @override
  Future<List<AssessmentResults>> addAssessmentResults
      (List<AssessmentResults> assessmentResults, NewAssessment newAssessment) async {
    List<AssessmentResults> assessmentResultsList = AssessmentResults.extractDataFromNewAssessment(newAssessment);
    try{
      for(var assessmentResult in assessmentResultsList){
        assessmentResult.id = "assessment-result-${assessmentResult.examineeStaffIDNo}-${Util.convertDateTimeDisplay(assessmentResult.date.toString())}";
        await _db!
            .collection(AssessmentResults.firebaseCollection)
            .doc(assessmentResult.id)
            .set(assessmentResult.toFirebase());

        for(var assessmentVariableResult in assessmentResult.variableResults) {
          assessmentVariableResult.id = "assessment-variable-result-${assessmentVariableResult.assessmentVariableId}-${assessmentResult.examineeStaffIDNo}-${Util.convertDateTimeDisplay(assessmentResult.date.toString())}";
          assessmentVariableResult.assessmentResultsId = assessmentResult.id;
          await _db!
              .collection(AssessmentVariableResults.firebaseCollection)
              .doc(assessmentVariableResult.id)
              .set(assessmentVariableResult.toFirebase());
        }
      }
    }
    catch(e){
      log("Exception on assessment results repo: ${e.toString()}");
    }
    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAllAssessmentResults() async {
    List<AssessmentResults> assessmentResultsList = [];
    try{
      QuerySnapshot querySnapshot = await _db!
          .collection(AssessmentResults.firebaseCollection)
          .get();

      for(var doc in querySnapshot.docs){
        AssessmentResults assessmentResults = AssessmentResults.fromFirebase(doc.data() as Map<String, dynamic>);
        QuerySnapshot querySnapshot2 = await _db!
            .collection(AssessmentVariableResults.firebaseCollection)
            .where(AssessmentVariableResults.keyAssessmentResultsId, isEqualTo: assessmentResults.id)
            .get();
        for(var doc2 in querySnapshot2.docs){
          AssessmentVariableResults assessmentVariableResults = AssessmentVariableResults.fromFirebase(doc2.data() as Map<String, dynamic>);
          assessmentResults.variableResults.add(assessmentVariableResults);
        }
        assessmentResultsList.add(assessmentResults);
      }
    }
    catch(e){
      log("Exception on assessment results repo: ${e.toString()}");
    }
    return assessmentResultsList;
  }

  @override
  Future<List<AssessmentResults>> getAssessmentResultsFilteredByDate(DateTime startDate, DateTime endDate) async {
    List<AssessmentResults> assessmentResultsList = [];
    try{
      QuerySnapshot querySnapshot = await _db!
          .collection(AssessmentResults.firebaseCollection)
          .where(AssessmentResults.keyDate, isGreaterThanOrEqualTo: startDate)
          .where(AssessmentResults.keyDate, isLessThanOrEqualTo: endDate)
          .get();

      for(var doc in querySnapshot.docs){
        AssessmentResults assessmentResults = AssessmentResults.fromFirebase(doc.data() as Map<String, dynamic>);
        QuerySnapshot querySnapshot2 = await _db!
            .collection(AssessmentVariableResults.firebaseCollection)
            .where(AssessmentVariableResults.keyAssessmentResultsId, isEqualTo: assessmentResults.id)
            .get();
        for(var doc2 in querySnapshot2.docs){
          AssessmentVariableResults assessmentVariableResults = AssessmentVariableResults.fromFirebase(doc2.data() as Map<String, dynamic>);
          assessmentResults.variableResults.add(assessmentVariableResults);
        }
        assessmentResultsList.add(assessmentResults);
      }
    }
    catch(e){
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
      log(
          "Exception in AssessmentResultRepo on getAssessmentResultsNotConfirmByCPTS: $e");
      log(
          "Exception in AssessmentResultRepo on getAssessmentResultsByCurrentUserNotConfirm: $e");
    }

    return assessmentResults;
  }

  int assessmentVariableCollectionComparator(DocumentSnapshot a,
      DocumentSnapshot b) {
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
        assessmentVariableResults.add(AssessmentVariableResults.fromFirebase(
            element.data()));
      }

    } catch (e) {
      log("Exception in AssessmentResultRepo on getAssessmentVariableResult: $e");
    }

    return assessmentVariableResults;
  }

  String rememberSortBy = "";
  static DocumentSnapshot? lastDocument;

  @override
  Future<List<AssessmentResults>> getAllAssessmentResultsPaging(int startAt, sortBy) async {
    List<AssessmentResults> assessmentResultsList = [];

    try {
      log("sortBy: $sortBy dan rememberSortBy: $rememberSortBy");

      // if rememberSortBy != sortBy, reset lastDocument
      if (rememberSortBy != sortBy) {
        lastDocument = null;
      }

      // if lastDocument == null, reset data that already sorting
      if (lastDocument == null) {
        await _db!
            .collection(AssessmentResults.firebaseCollection)
            .where(AssessmentResults.keyConfirmedByInstructor, isEqualTo: true)
            .orderBy(sortBy == "initial" ? AssessmentResults.keyExamineeStaffIDNo : sortBy)
            .limit(10)
            .get()
            .then((value) {
          for (var element in value.docs) {
            assessmentResultsList.add(AssessmentResults.fromFirebase(element.data()));
          }
          rememberSortBy = sortBy;
          lastDocument = value.docs.last;
        });
      } else {
        await _db!
            .collection(AssessmentResults.firebaseCollection)
            .where(AssessmentResults.keyConfirmedByInstructor, isEqualTo: true)
            .orderBy(sortBy == "initial" ? AssessmentResults.keyExamineeStaffIDNo : sortBy)
            .startAfterDocument(lastDocument!)
            .limit(10)
            .get()
            .then((value) {
          for (var element in value.docs) {
            assessmentResultsList.add(AssessmentResults.fromFirebase(element.data()));
          }
          lastDocument = value.docs.last;
        });
      }

    } catch (e) {
      log("Exception in AssessmentResultRepo on getAllAssessmentResultsPaging: $e");
      log("Exception in AssessmentResultRepo on updateAssessmentResultForExaminee: $e");
    }

    return assessmentResultsList;
  }

  @override
  Future<void> updateAssessmentResultForExaminee(AssessmentResults assessmentResults) async {
    try {
      await _db!
          .collection(AssessmentResults.firebaseCollection)
          .doc(assessmentResults.id)
          .update(assessmentResults.toFirebase());
      log("BERHASIL: ${assessmentResults.id}");

    } catch (e) {
      log("Exception in AssessmentResultRepo on updateAssessmentResultForExaminee: $e");
    }
  }
}