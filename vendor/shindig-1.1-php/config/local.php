<?php
$shindigConfig =  array(
                        'debug' => true,
                        'compress_javascript' => false,
                        'check_file_exists' => true,
                        'web_prefix' => '/opensocial',
                        'allow_plaintext_token' => false,
                        'token_cipher_key' => 'MySecretKey',
                        'token_hmac_key' => 'MyOtherSecret',
                        'private_key_phrase' => 'MyCertificatePassword',
                        'person_service' => 'MyPeopleService',
                        'activity_service' => 'MyActivitiesService',
                        'app_data_service' => 'MyAppDataService',
                        'messages_service' => 'MyMessagesService',
                        'oauth_lookup_service' => 'MyOAuthLookupService',
                        'cache_time' => 0
                        );
?>