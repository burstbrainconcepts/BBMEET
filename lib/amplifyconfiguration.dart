import 'package:flutter_dotenv/flutter_dotenv.dart';

String get amplifyConfig => ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "${dotenv.env['COGNITO_POOL_ID']}",
                        "AppClientId": "${dotenv.env['COGNITO_APP_CLIENT_ID']}",
                        "Region": "${dotenv.env['COGNITO_REGION']}"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH"
                    }
                }
            }
        }
    },
    "analytics": {
        "plugins": {
            "awsPinpointAnalyticsPlugin": {
                "pinpointAnalytics": {
                    "AppId": "${dotenv.env['PINPOINT_APP_ID']}",
                    "Region": "${dotenv.env['PINPOINT_REGION']}"
                },
                "pinpointTargeting": {
                    "Region": "${dotenv.env['PINPOINT_REGION']}"
                }
            }
        }
    }
}''';
