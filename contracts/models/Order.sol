// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './Item.sol';
import './Coodernate.sol';
import './Restaurant.sol';

/*
* Status list:
* 0: pending
* 1: preparing
* 2: pending delivery acceptance,
* 3: shipping
* 4: pending client acceptance
* 5: delivered
* 6: canceled
*/

struct Order {
  uint id;
  address client;
  Restaurant restaurant;
  Item[] items;
  uint64 total_price;
  address delivery;
  uint64 delivery_price;
  address platform;
  uint64 platform_tip;
  int128 distance;
  Coodernate destination;
  uint64 status;
  uint64 client_cancel_penalty;
  uint64 restaurant_cancel_penalty;
  uint64 delivery_cancel_penalty;
}