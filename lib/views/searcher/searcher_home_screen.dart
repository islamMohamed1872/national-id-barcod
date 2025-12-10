import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../controllers/admin/search_ids/search_ids_cubit.dart';
import '../../../controllers/admin/search_ids/search_ids_states.dart';
import '../admin/search_ids/search_ids_screen.dart';

class SearcherHomeScreen extends StatelessWidget {
  const SearcherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchIdsCubit(),
      child: const SearchIDsScreen(
        isSearcher: true, // we will add this parameter
      ),
    );
  }
}
