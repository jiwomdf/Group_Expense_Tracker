import 'package:bloc/bloc.dart';
import 'package:core/domain/model/category_model.dart';
import 'package:core/repository/firestore_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final FirestoreRepository _firestoreRepository;

  CategoryBloc(this._firestoreRepository) : super(CategoryLoading()) {
    on<UpdateCategoryEvent>((event, emit) async {
      var category = await _firestoreRepository.updateCategory(
        categoryId: event.categoryModel.categoryId,
        categoryName: event.categoryModel.categoryName,
        categoryColor: event.categoryModel.categoryColor,
      );
      switch (category.status) {
        case Status.success:
          emit(const CategoryUpdated());
          break;
        case Status.error:
          emit(CategoryError(category.failure?.message ?? ""));
          break;
      }
    });

    on<GetCategoryEvent>((event, emit) async {
      emit(CategoryLoading());
      var category = await _firestoreRepository.getCategory();
      switch (category.status) {
        case Status.success:
          emit(CategoryHasData(category.data ?? []));
          break;
        case Status.error:
          emit(CategoryError(category.failure?.message ?? ""));
          break;
      }
    });

    on<ResetCategoryEvent>((event, emit) async {
      emit(CategoryLoading());
    });
  }
}
