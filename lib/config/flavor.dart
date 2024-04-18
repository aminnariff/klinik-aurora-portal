import 'package:klinik_aurora_portal/env/development.dart';
import 'package:klinik_aurora_portal/env/production.dart';
import 'package:klinik_aurora_portal/env/staging.dart';

enum Flavor {
  development,
  staging,
  production,
}

Flavor environment = Flavor.staging;

class Environment {
  static String get appName {
    switch (environment) {
      case Flavor.development:
        return "FBB Gateway Dev";
      case Flavor.staging:
        return "FBB Gateway Staging";
      case Flavor.production:
        return "FBB Gateway";

      default:
        return "FBB Gateway";
    }
  }

  static dynamic data(String value) {
    switch (environment) {
      case Flavor.development:
        return DevelopmentEnvironment().data[value];
      case Flavor.staging:
        return StagingEnvironment().data[value];
      case Flavor.production:
        return ProductionEnvironment().data[value];
      default:
        return ProductionEnvironment().data[value];
    }
  }

  static String get appUrl {
    return data('appUrl');
  }

  static String get imageUrl {
    return data('imageUrl');
  }

  static String get provisioningUrl {
    return data('provisioningUrl');
  }

  static String get cfsUrl {
    return data('cfsUrl');
  }

  static String get paymentUrl {
    return data('paymentUrl');
  }
}
