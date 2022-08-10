// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './Item.sol';
import './Coordenate.sol';
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
  address payable client;
  Restaurant restaurant;
  Item[] items;
  uint128 total_price;
  address payable delivery;
  uint128 delivery_price;
  address payable platform;
  uint128 platform_tip;
  int128 distance;
  Coordenate destination;
  uint16 status;
}