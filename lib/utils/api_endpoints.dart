class ApiEndpoints {
  static const String login = "/user/login/";
  static const String registerUser = "/user/register/";
  static const String logout = "/user/logout/";

  static const String registerGarage = "/garages/register/";
  static String garageBranches(int garageId) => "/garages/$garageId/branches/";

  static const String jobCards = "/jobcard/jobcards/";
  static String jobCardDetail(int id) => "/jobcard/jobcards/$id/";
  static const String manageJobs = "/jobcard/manage/";

  static const String labourSearch = "/labour/search/";
  static const String labourCreate = "/labour/create/";
  static String jobCardLabour(int jobcardId) => "/labour/jobcard/$jobcardId/";

  static const String spares = "/spare/spare-create";
}
