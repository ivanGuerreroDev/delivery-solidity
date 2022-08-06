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

    uint128 penalty_unit = 2000;

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

    /*
    *   Creación de Ordenes
    */
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
        uint16 status_pending = 0;
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
            destination,
            status_pending
        );
        orders[msg.sender][orderId] = newOrder;
        return newOrder;
    }

    function getOrder(address restaurantAddress, uint256 orderId) public view returns (Order) {
        return orders[restaurantAddress][orderId];
    }

    function getPendingOrders(address restaurantAddress) public view returns (Order[]) {
        Order[] pendingOrders = new Order[](0);
        for (uint i=0; i<orders[restaurantAddress].length; i++) {
            if (orders[restaurantAddress][i].status == 0) {
                pendingOrders.push(orders[restaurantAddress][i]);
            }
        }
        return pendingOrders;
    }

    function getOrders(address restaurantAddress) public view returns (mapping(address => mapping(uint => Order))) {
        return orders[restaurantAddress];
    }


    /*
    * Aceptacion de Ordenes
    */
    function acceptOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == restaurants[restaurantAddress].id, "You aren't the restaurant owner.");
        Order order = orders[restaurantAddress][orderId];
        order.status = 1;
    }

    /*
    * Entregar pedido al delivery
    */
    function deliverToDelivery(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == restaurants[restaurantAddress].id, "You aren't the restaurant owner.");
        Order order = orders[restaurantAddress][orderId];
        order.status = 2;
    }

    /*
    * Aceptar pedido del restaurante
    */
    function recieveDelivery(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].delivery, "You aren't the delivery of this order.");
        Order order = orders[restaurantAddress][orderId];
        order.status = 3;
    }

    /*
    * Entregar orden
    */
    function deliverOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].delivery, "You aren't the delivery of this order.");
        Order order = orders[restaurantAddress][orderId];
        order.status = 4;
    }

    /*
    * Aceptar pedido del delivery
    */
    function recieveOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].client, "You aren't the owner of this order.");
        Order order = orders[restaurantAddress][orderId];
        order.status = 5;
    }

    /*
    *   Cancelar pedido
    */
    function cancelOrder(address restaurantAddress, uint256 orderId) public {
        Order order = orders[restaurantAddress][orderId];
        require(
            (
                msg.sender == order.client
                || msg.sender == order.delivery
                || msg.sender == order.restaurant.id
                && ( 
                    order.status == 0
                    || order.status == 1
                    || order.status == 2
                    || order.status == 3
                    || order.status == 4
                )
            ), 
            "You can't cancel this order."
        );
        this.refund(restaurantAddress, orderId);
        orders[restaurantAddress].remove(orderId);
        order.status = 6;
    }

    /*
    *   Refund
    */
    function refund(address restaurantAddress, uint256 orderId) public {
        Order order = orders[restaurantAddress][orderId];
        address requestor = msg.sender;
        if(order.status == 0){
            require(requestor == order.client, "You can't refund this order.");
            order.client.transfer(order.total_price + order.shipper_price + order.platform_tip);
        } else if(order.status == 1){
            if(requestor == order.client){
                require(msg.value >= order.client_cancel_penalty, "You need send more amount for pay penalty.");
                order.restaurant.id.transfer(order.total_price);
                order.client.transfer(order.shipper_price + order.platform_tip);
            }else if(requestor == order.restaurant.id){
                require(msg.value >= order.restaurant_cancel_penalty, "You need send more amount for pay penalty.");
                order.client.transfer(order.total_price + order.shipper_price + order.platform_tip + order.restaurant_cancel_penalty);
            }
        } else if(order.status == 2){
            require(requestor == order.platform, "You can't refund this order.");
            require(order.platform.balance >= order.platform_tip, "You don't have enough money to refund this order.");
            order.platform.transfer(order.platform_tip);
        } else if(order.status == 3){
            require(requestor == order.delivery, "You can't refund this order.");
            require(order.delivery.balance >= order.shipper_price, "You don't have enough money to refund this order.");
            order.delivery.transfer(order.shipper_price);
        } else if(order.status == 4){
            require(requestor == order.platform, "You can't refund this order.");
            require(order.platform.balance >= order.platform_tip, "You don't have enough money to refund this order.");
            order.platform.transfer(order.platform_tip);
        } else if(order.status == 5){
            require(requestor == order.client, "You can't refund this order.");
            require(order.client.balance >= order.total_price, "You don't have enough money to refund this order.");
            order.client.transfer(order.total_price);
        } else if(order.status == 6){
            require(requestor == order.client, "You can't refund this order.");
            require(order.client.balance >= order.total_price, "You don't");
        }
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
