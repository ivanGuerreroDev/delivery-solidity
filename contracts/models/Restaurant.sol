// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import './Image.sol';
import './Coodernate.sol';
import './Schedule.sol';

struct Restaurant{
  address id;
  string name;
  string _address;
  Image logo;
  Image banner;
  Coodernate location;
  uint64 min_order;
  uint64 products;
  mapping(string => Schedule) schedules;
}