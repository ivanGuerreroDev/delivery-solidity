// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import './Image.sol';
import './Coordenate.sol';
import './Schedule.sol';

struct Restaurant{
  address payable id;
  string name;
  string _address;
  Image logo;
  Image banner;
  Coordenate location;
  uint64 min_order;
  Schedule[] schedules;
  uint64 products;
}