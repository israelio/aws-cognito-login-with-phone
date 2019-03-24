# change the xxxxxx:xxxxxxx to region:account_id
locals {
  cognito_pre_signup_trigger_arn = "arn:aws:lambda:xxxxxxxx:xxxxxxxx:function:auth-preSignup"
  define_auth_challenge_arn = "arn:aws:lambda:xxxxxxxx:xxxxxxxx:function:auth-defineAuthChallenge"
  create_auth_challenge - "arn:aws:lambda:xxxxxxxx:xxxxxxxx:function:auth-createAuthChallenge"
  verify_auth_challenge_response_arn = "arn:aws:lambda:xxxxxxxx:xxxxxxxx:function:auth-verifyAuthChallenge"
}

# change the xxxxxx to the region
provider "aws" {
  region = "xxxxxxxx"
}

resource "aws_cognito_user_pool" "sample-user-pool" {
  name = "sample-user-pool"

  # alias_attributes    = ["phone_number", "email"]
  username_attributes = ["phone_number", "email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  lambda_config {
    pre_sign_up                    = "${local.cognito_pre_signup_trigger_arn}"
    define_auth_challenge          = "${local.define_auth_challenge_arn}"
    create_auth_challenge          = "${local.create_auth_challenge}"
    verify_auth_challenge_response = "${verify_auth_challenge_response_arn}"

    # custom_message                 = "${aws_lambda_function.main.arn}"
    # post_authentication            = "${aws_lambda_function.main.arn}"
    # post_confirmation              = "${aws_lambda_function.main.arn}"
    # pre_authentication             = "${aws_lambda_function.main.arn}"
    # pre_token_generation           = "${aws_lambda_function.main.arn}"
    # user_migration                 = "${aws_lambda_function.main.arn}"
  }

  schema {
    attribute_data_type = "String"
    name                = "phone_number"
    required            = true
  }

  schema {
    name                     = "user_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "sample-clienti-app" {
  name         = "sample-client-app"
  user_pool_id = "${aws_cognito_user_pool.sample-user-pool.id}"

  read_attributes  = ["name", "email", "phone_number"]
  write_attributes = ["name", "email", "phone_number"]
}

# most important !
# when you use the cognito ui it will add permissions for cognito to access your triggers
# and when you want to create them without the ui you need to declare the permission to the preSignup
resource "aws_lambda_permission" "allow_presignup" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = "${local.cognito_pre_signup_trigger_arn}"
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "${aws_cognito_user_pool.sample-user-pool.arn}"
}
