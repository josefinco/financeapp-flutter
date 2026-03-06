import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../domain/entities/user_profile.dart';

part 'profile_remote_datasource.g.dart';

@RestApi()
abstract class ProfileRemoteDatasource {
  factory ProfileRemoteDatasource(Dio dio) = _ProfileRemoteDatasource;

  @GET('/profile')
  Future<UserProfile> getProfile();

  @PATCH('/profile')
  Future<UserProfile> updateProfile(@Body() Map<String, dynamic> body);
}
