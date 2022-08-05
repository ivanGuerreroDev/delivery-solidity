// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import './Image.sol';
import './Category.sol';

struct Product{
  uint id;
  string name;
  string description;
  Image image;
  uint64 price;
  uint64 discount;
  uint64 tax;
  Category category;
}