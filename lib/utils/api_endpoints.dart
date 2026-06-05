class ApiEndpoints {
  static const String login = "/user/login/";
  static const String registerUser = "/user/register/";
  static const String logout = "/user/logout/";

  static const String registerGarage = "/garages/register/";
  static String garageBranches(int garageId) => "/garages/$garageId/branches/";

  static const String jobCards = "/jobcard/jobcards/";
  static const String customerLatestJobCard = "/jobcard/customer/latest/";
  static String jobCardDetail(int id) => "/jobcard/jobcards/$id/";
  static String jobCardDocument(int id) => "/jobcard/jobcards/$id/document/";
  static const String manageJobs = "/jobcard/manage/";

  static const String labourSearch = "/labour/search/";
  static const String labourCreate = "/labour/create/";
  static String jobCardLabour(int jobcardId) => "/labour/jobcard/$jobcardId/";

  static const String spares = "/spare/spare-create";
  static const String spareSearch = "/spare/search/";
  static String spareList(int branchId) => "/spare/list/$branchId/";
  static const String spareStockAdd = "/spare/stock/add/";
  static String spareStockUpdate(int stockId) =>
      "/spare/stock/update/$stockId/";
  static String spareUpdate(int spareId) => "/spare/update/$spareId/";
  static String jobCardSpare(int jobcardId) => "/spare/jobcard/$jobcardId/";
}
