<?php
/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

require 'src/social/service/DataRequestHandler.php';
require 'src/social/service/PersonHandler.php';
require 'src/social/spi/ActivityService.php';
require 'src/social/spi/PersonService.php';
require 'src/social/spi/AppDataService.php';
require 'src/social/spi/MessagesService.php';
require 'src/social/service/ActivityHandler.php';
require 'src/social/service/AppDataHandler.php';
require 'src/social/service/MessagesHandler.php';
require 'src/common/SecurityToken.php';
require 'src/common/BlobCrypter.php';
require 'src/social/converters/InputConverter.php';
require 'src/social/converters/InputJsonConverter.php';
require 'src/social/converters/OutputConverter.php';
require 'src/social/converters/OutputJsonConverter.php';
require 'src/social/service/RequestItem.php';
require 'src/social/service/RestRequestItem.php';
require 'src/social/service/RpcRequestItem.php';
require 'src/social/spi/GroupId.php';
require 'src/social/spi/UserId.php';
require 'src/social/spi/CollectionOptions.php';
require 'src/common/Cache.php';
require 'src/social/model/ComplexField.php';
require 'src/social/model/Name.php';
require 'src/social/model/Enum.php';
require 'src/social/model/Person.php';
require 'src/social/model/ListField.php';
require 'src/social/model/Photo.php';
require 'src/social/spi/RestfulCollection.php';
require 'src/social/spi/DataCollection.php';
require 'src/social/service/ResponseItem.php';
require 'src/social/oauth/OAuth.php';

/**
 * Common base class for API servlets.
 */
abstract class ApiServlet extends HttpServlet {
  protected $handlers = array();

  protected static $DEFAULT_ENCODING = "UTF-8";

  public static $PEOPLE_ROUTE = "people";
  public static $ACTIVITY_ROUTE = "activities";
  public static $APPDATA_ROUTE = "appdata";
  public static $MESSAGE_ROUTE = "messages";
  public static $INVALIDATE_ROUTE = "cache";

  public function __construct() {
    parent::__construct();
    $this->setNoCache(true);
    $this->handlers[self::$PEOPLE_ROUTE] = new PersonHandler();
    $this->handlers[self::$ACTIVITY_ROUTE] = new ActivityHandler();
    $this->handlers[self::$APPDATA_ROUTE] = new AppDataHandler();
    $this->handlers[self::$MESSAGE_ROUTE] = new MessagesHandler();
    $this->handlers[self::$INVALIDATE_ROUTE] = new InvalidateHandler();
    if (isset($_SERVER['CONTENT_TYPE']) && (strtolower($_SERVER['CONTENT_TYPE']) != $_SERVER['CONTENT_TYPE'])) {
      // make sure the content type is in all lower case since that's what we'll check for in the handlers
      $_SERVER['CONTENT_TYPE'] = strtolower($_SERVER['CONTENT_TYPE']);
    }
    $acceptedContentTypes = array('application/atom+xml', 'application/xml', 'application/json');
    if (isset($_SERVER['CONTENT_TYPE'])) {
      // normalize things like "application/json; charset=utf-8" to application/json
      foreach ($acceptedContentTypes as $contentType) {
        if (strpos($_SERVER['CONTENT_TYPE'], $contentType) !== false) {
          $_SERVER['CONTENT_TYPE'] = $contentType;
          $this->setContentType($contentType);
          break;
        }
      }
    }
    if (isset($GLOBALS['HTTP_RAW_POST_DATA'])) {
      if (! isset($_SERVER['CONTENT_TYPE']) || ! in_array($_SERVER['CONTENT_TYPE'], $acceptedContentTypes)) {
        throw new Exception("When posting to the social end-point you have to specify a content type, supported content types are: 'application/json', 'application/xml' and 'application/atom+xml'");
      }
    }
  }

  public function getSecurityToken() {
    // see if we have an OAuth request
    $request = OAuthRequest::from_request();
    $appUrl = $request->get_parameter('oauth_consumer_key');
    $userId = $request->get_parameter('xoauth_requestor_id'); // from Consumer Request extension (2-legged OAuth)
    $signature = $request->get_parameter('oauth_signature');
    if ($appUrl && $signature) {
      //if ($appUrl && $signature && $userId) {
      // look up the user and perms for this oauth request
      $oauthLookupService = Config::get('oauth_lookup_service');
      $oauthLookupService = new $oauthLookupService();
      $token = $oauthLookupService->getSecurityToken($request, $appUrl, $userId, $this->getContentType());
      if ($token) {
        $token->setAuthenticationMode(AuthenticationMode::$OAUTH_CONSUMER_REQUEST);
        return $token;
      } else {
        return null; // invalid oauth request, or 3rd party doesn't have access to this user
      }
    } // else, not a valid oauth request, so don't bother


    // look for encrypted security token
    $token = isset($_POST['st']) ? $_POST['st'] : (isset($_GET['st']) ? $_GET['st'] : '');
    if (empty($token)) {
      if (Config::get('allow_anonymous_token')) {
        // no security token, continue anonymously, remeber to check
        // for private profiles etc in your code so their not publicly
        // accessable to anoymous users! Anonymous == owner = viewer = appId = modId = 0
        // create token with 0 values, no gadget url, no domain and 0 duration
        $gadgetSigner = Config::get('security_token');
        return new $gadgetSigner(null, 0, 0, 0, 0, '', '', 0, Config::get('container_id'));
      } else {
        return null;
      }
    }
    if (count(explode(':', $token)) != 7) {
      $token = urldecode(base64_decode($token));
    }
    $gadgetSigner = Config::get('security_token_signer');
    $gadgetSigner = new $gadgetSigner();
    return $gadgetSigner->createToken($token);
  }

  protected abstract function sendError(ResponseItem $responseItem);

  protected function sendSecurityError() {
    $this->sendError(new ResponseItem(ResponseError::$UNAUTHORIZED, "The request did not have a proper security token nor oauth message and unauthenticated requests are not allowed"));
  }

  /**
   * Delivers a request item to the appropriate DataRequestHandler.
   */
  protected function handleRequestItem(RequestItem $requestItem) {
    if (! isset($this->handlers[$requestItem->getService()])) {
      throw new SocialSpiException("The service " . $requestItem->getService() . " is not implemented", ResponseError::$NOT_IMPLEMENTED);
    }
    $handler = $this->handlers[$requestItem->getService()];
    return $handler->handleItem($requestItem);
  }

  protected function getResponseItem($result) {
    if ($result instanceof ResponseItem) {
      return $result;
    } else {
      return new ResponseItem(null, null, $result);
    }
  }

  protected function responseItemFromException($e) {
    if ($e instanceof SocialSpiException) {
      return new ResponseItem($e->getCode(), $e->getMessage(), null);
    }
    return new ResponseItem(ResponseError::$INTERNAL_ERROR, $e->getMessage());
  }
}