import 'package:bloc_test/bloc_test.dart';
import 'package:core/domain/model/sub_category_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:mockito/mockito.dart';

import '../../../helper/test_helper.mocks.dart';

void main() {
  late SubcategoryBloc registerBloc;
  late MockFirestoreRepository mockFirestoreRepository;
  late List<SubCategoryModel> subCategoryList;
  late SubCategoryModel subCategoryModel;
  const categoryName = "categoryName";
  const categoryColor = 0;

  setUp(() {
    mockFirestoreRepository = MockFirestoreRepository();
    registerBloc = SubcategoryBloc(mockFirestoreRepository);
    subCategoryModel = SubCategoryModel(
      subCategoryId: '1',
      subCategoryName: 'categoryName',
      subCategoryColor: 0,
    );
    subCategoryList = [
      SubCategoryModel(
        subCategoryId: '1',
        subCategoryName: '',
        subCategoryColor: 0,
      )
    ];
  });

  blocTest<SubcategoryBloc, SubcategoryState>(
    'Should emit [GetSubcategoryEvent] when data is get successfully',
    build: () {
      when(mockFirestoreRepository.getSubCategory())
          .thenAnswer((_) async => ResourceUtil.success(subCategoryList));
      return registerBloc;
    },
    act: (bloc) => bloc.add(const GetSubcategoryEvent()),
    expect: () => [
      SubcategoryLoading(),
      SubcategoryHasData(subCategoryList),
    ],
    verify: (bloc) {
      verify(mockFirestoreRepository.getSubCategory());
      return const GetSubcategoryEvent().props;
    },
  );

  blocTest<SubcategoryBloc, SubcategoryState>(
    'Should emit [UpdateSubcategoryEvent] when data is updated successfully',
    build: () {
      when(mockFirestoreRepository.updateSubCategory(
        subCategoryId: subCategoryModel.subCategoryId,
        categoryName: categoryName,
        categoryColor: categoryColor,
      )).thenAnswer((_) async => ResourceUtil.success(null));
      return registerBloc;
    },
    act: (bloc) => bloc.add(UpdateSubcategoryEvent(subCategoryModel)),
    expect: () => [
      SubcategoryLoading(),
      const SubcategoryUpdated(),
    ],
    verify: (bloc) {
      verify(mockFirestoreRepository.updateSubCategory(
        subCategoryId: subCategoryModel.subCategoryId,
        categoryName: categoryName,
        categoryColor: categoryColor,
      ));
      return UpdateSubcategoryEvent(subCategoryModel).props;
    },
  );
}
