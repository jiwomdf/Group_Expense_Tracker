import 'package:bloc/bloc.dart';
import 'package:core/domain/model/category_model.dart';
import 'package:core/repository/firestore_repository.dart';
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

      category.fold((failure) {
        emit(CategoryError(failure.message));
      }, (data) {
        emit(const CategoryUpdated());
      });
    });

    on<GetCategoryEvent>((event, emit) async {
      emit(CategoryLoading());
      var category = await _firestoreRepository.getCategory();
      category.fold((failure) {
        emit(CategoryError(failure.message));
      }, (data) {
        emit(CategoryHasData(data));
      });
    });

    on<ResetCategoryEvent>((event, emit) async {
      emit(CategoryLoading());
    });
  }
}
