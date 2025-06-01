import 'package:bloc/bloc.dart';
import 'package:core/domain/model/sub_category_model.dart';
import 'package:core/repository/firestore_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'subcategory_event.dart';
part 'subcategory_state.dart';

class SubcategoryBloc extends Bloc<SubcategoryEvent, SubcategoryState> {
  final FirestoreRepository _firestoreRepository;

  SubcategoryBloc(this._firestoreRepository) : super(SubcategoryInitial()) {
    on<GetSubcategoryEvent>((event, emit) async {
      emit(SubcategoryLoading());
      final result = await _firestoreRepository.getSubCategory();

      switch (result.status) {
        case Status.success:
          emit(SubcategoryHasData(result.data ?? []));
          break;
        case Status.error:
          emit(SubcategoryError(result.failure?.message ?? ""));
          break;
      }
    });

    on<GetSubcategoryWithCacheEvent>((event, emit) async {
      emit(SubcategoryLoading());
      final result = await _firestoreRepository.getSubCategoryWithCache();

      switch (result.status) {
        case Status.success:
          emit(SubcategoryHasData(result.data ?? []));
          break;
        case Status.error:
          emit(SubcategoryError(result.failure?.message ?? ""));
          break;
      }
    });

    on<UpdateSubcategoryEvent>((event, emit) async {
      emit(SubcategoryLoading());
      final result = await _firestoreRepository.updateSubCategory(
          subCategoryId: event.subCategoryModel.subCategoryId,
          categoryName: event.subCategoryModel.subCategoryName,
          categoryColor: event.subCategoryModel.subCategoryColor);

      switch (result.status) {
        case Status.success:
          emit(const SubcategoryUpdated());
          break;
        case Status.error:
          emit(SubcategoryError(result.failure?.message ?? ""));
          break;
      }
    });
  }
}
