// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './Item.sol';
import './Coodernate.sol';
import './Restaurant.sol';

/*
* Status list:
* 0: pending
* 1: preparing
* 2: shipping
* 3: accepted
* 4: canceled
*/

struct Order {
  uint id;
  address client;
  Restaurant restaurant;
  Item[] items;
  uint64 total_price;
  address shipper;
  uint64 shipping_price;
  address platform;
  uint64 platform_tip;
  int128 distance;
  Coodernate destination;
  uint64 status;
}