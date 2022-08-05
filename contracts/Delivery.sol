// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './models/Order.sol';
import './models/Restaurant.sol';
import './models/Product.sol';
import './models/Item.sol';
import './models/Image.sol';
import './utils/Geo.sol';

contract Delivery {
    mapping(address => mapping(uint => Order)) public orders;
    mapping(address => Restaurant) public restaurants;
    mapping(address => mapping(uint => Product)) public products;
    mapping(uint => Category) public categories;

    uint256 public nextOrderId = 0;
    uint256 public nextProductId = 0;
    uint256 public nextCategoryId = 0;

    receive() external payable {}

    fallback() external payable {}

    function addCategory (string _name, Image _image) public {
        nextCategoryId++;
        categories[nextCategoryId] = Category(_name, _image);
    }

    function addProduct (address restaurant, string name, string description, uint64 price, uint64 discount, string imageHash, string ipfsInfo, uint64 category) public {
        Restaurant r = restaurants[restaurant];
        r.products++;
        Category c = categories[category];
        nextProductId++;
        Product p = Product(nextProductId, name, description, Image(imageHash, ipfsInfo), price, discount, c);
        products[restaurant][nextProductId] = p;
    }

    function addRestaurant(address restaurantAddress, string name, string _address, string logo, string banner, uint64 minOrder, mapping(string => Schedule) schedule) public {  
        Restaurant restaurant = Restaurant(restaurantAddress, name, _address, logo, banner, minOrder, schedule);
        restaurants[restaurantAddress] = restaurant;
    }

    function addOrder(
        address restaurantAddress,
        address shipper,
        address shipper_price,
        address platform,
        uint64 platform_tip,
        Item[] items,
        Coodernate destination
    ) public returns (Order){
        Item[] itemsOrder;
        uint64 total_price = 0;
        for (uint i=0; i<items.length; i++) {
            total_price += ( items[i].product.price - items[i].product.discount + items[i].product.tax) * items[i].quantity;
        }
        int128 distance = Geo.getDistance(
            destination.lat, 
            destination.lng, 
            restaurants[restaurantAddress].location.lat, 
            restaurants[restaurantAddress].location.lng
        );
        uint256 orderId = nextOrderId++;
        Order newOrder = Order(
            orderId,
            msg.sender,
            items,
            total_price,
            shipper,
            shipper_price * distance,
            platform,
            platform_tip,
            distance,
            destination
        );
        orders[msg.sender][orderId] = newOrder;
        return newOrder;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceBySender(address _address)
        public
        view
        returns (uint256)
    {
        return balances[_address];
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function transferBySend(
        address _from,
        address payable _to,
        uint256 amount
    ) public returns (bool) {
        balances[_from] -= amount;
        bool sent = _to.send(amount);
        require(sent, "Failed to send Ether");
        return sent;
    }

    function TransferByTransfer(
        address _from,
        address payable _to,
        uint256 amount
    ) public {
        balances[_from] -= amount;
        _to.transfer(amount);
    }

    function TransferByCall(
        address _from,
        address payable _to,
        uint256 amount
    ) public returns (bool) {
        balances[_from] -= amount;
        (bool sent, ) = _to.call{value: amount, gas: 1000}("");
        require(sent, "Failed to send Ether");
        return sent;
    }
}
