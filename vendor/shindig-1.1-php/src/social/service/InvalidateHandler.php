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

class InvalidateHandler extends DataRequestHandler {
  
  /**
   * @var InvalidateService
   */
  private $invalidateService;
  
  private static $INVALIDATE_PATH = "/cache/invalidate";
  
  private static $KEYS_PARAM = "invalidationKeys";

  public function __construct() {
    $service = Config::get('invalidate_service');
    $cache = Cache::createCache(Config::get('data_cache'), 'RemoteContent');
    $this->invalidateService = new $service($cache);
  }

  public function handleItem(RequestItem $requestItem) {
    try {
      $method = strtolower($requestItem->getMethod());
      $method = 'handle' . ucfirst($method);
      $response = $this->$method($requestItem);
    } catch (SocialSpiException $e) {
      $response = new ResponseItem($e->getCode(), $e->getMessage());
    } catch (Exception $e) {
      $response = new ResponseItem(ResponseError::$INTERNAL_ERROR, "Internal error: " . $e->getMessage());
    }
    return $response;
  }
  public function handleDelete(RequestItem $request) {
    throw new SocialSpiException("Http delete not allowed for invalidation service", ResponseError::$BAD_REQUEST);
  }

  public function handlePut(RequestItem $request) {
    throw new SocialSpiException("Http put not allowed for invalidation service", ResponseError::$BAD_REQUEST);
  }

  public function handlePost(RequestItem $request) {
    $this->handleInvalidate($request);
  }
  
  public function handleGet(RequestItem $request) {
    $this->handleInvalidate($request);
  }

  public function handleInvalidate(RequestItem $request) {
    if (!$request->getToken()->getAppId() && !$request->getToken()->getAppUrl()) {
      throw new SocialSpiException("Can't invalidate content without specifying application", ResponseError::$BAD_REQUEST);
    }
    
    $isBackendInvalidation = AuthenticationMode::$OAUTH_CONSUMER_REQUEST == $request->getToken()->getAuthenticationMode();
    $invalidationKeys = $request->getListParameter('invalidationKeys');
    $resources = array();
    $userIds = array();
    if ($request->getToken()->getViewerId()) {
      $userIds[] = $request->getToken()->getViewerId();
    }
    foreach($invalidationKeys as $key) {
      if (strpos($key, 'http') !== false) {
        if (!$isBackendInvalidation) {
          throw new SocialSpiException('Cannot flush application resources from a gadget. Must use OAuth consumer request'); 
        }
        $resources[] = $key;
      } else {
        if ($key == '@viewer') {
          continue;
        }
        if (!$isBackendInvalidation) {
          throw new SocialSpiException('Cannot invalidate the content for a user other than the viewer from a gadget.');
        }
        $userIds[] = $key;
      }
    }
    $this->invalidateService->invalidateApplicationResources($resources, $request->getToken());
    $this->invalidateService->invalidateUserResources($userIds, $request->getToken());
  }
}
