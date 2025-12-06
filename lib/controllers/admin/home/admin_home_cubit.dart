import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nationalidbarcode/controllers/admin/home/admin_home_states.dart';

class AdminHomeCubit extends Cubit<AdminHomeStates> {
  AdminHomeCubit() : super(AdminHomeInitialState());
  static AdminHomeCubit get(context) => BlocProvider.of(context);

}