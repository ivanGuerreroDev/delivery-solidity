// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import './Image.sol';
import './Product.sol';

struct Item{
    Product product;
    uint64 quantity;
    string note;
}