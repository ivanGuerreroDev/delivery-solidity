// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './models/Order.sol';
import './models/Coordenate.sol';
import './models/Restaurant.sol';
import './models/Product.sol';
import './models/Item.sol';
import './models/Image.sol';
import './utils/Geo.sol';

contract Delivery {
    mapping(address => Order[]) public orders;
    mapping(address => Restaurant) public restaurants;
    mapping(address => Product[]) public products;
    Category[] public categories;

    uint128 penalty_unit = 2000;

    uint256 public nextOrderId = 0;
    uint256 public nextProductId = 0;
    uint256 public nextCategoryId = 0;

    receive() external payable {}

    fallback() external payable {}

    function addCategory (string memory _name, Image memory _image) public {
        nextCategoryId++;
        categories[nextCategoryId] = Category(_name, _image);
    }

    function addProduct (address restaurant, string memory name, string memory description, uint64 price, uint64 discount, uint64 tax, string memory imageHash, string memory ipfsInfo, uint64 category) public {
        Restaurant memory r = restaurants[restaurant];
        r.products++;
        Category memory c = categories[category];
        nextProductId++;
        Product memory p = Product(nextProductId, name, description, Image(imageHash, ipfsInfo), price, discount, tax, c);
        products[restaurant][nextProductId] = p;
    }

    function addRestaurant(string memory name, string memory _address, string memory logo_hash, string memory logo_ipfs, string memory banner_hash, string memory banner_ipfs, Coordenate memory location, uint64 minOrder, Schedule[] memory _schedules) public {  
        Image memory logo = Image(logo_hash, logo_ipfs);
        Image memory banner = Image(banner_hash, banner_ipfs);
        Restaurant memory restaurant = Restaurant(payable(msg.sender), name, _address, logo, banner, location, minOrder, _schedules, 0);
        restaurants[msg.sender] = restaurant;
    }

    /*
    *   Creación de Ordenes
    */
    function addOrder(
        address payable restaurantAddress,
        address payable delivery,
        uint128 delivery_price,
        address payable platform,
        uint128 platform_tip,
        Item[] memory items,
        Coordenate memory destination
    ) public returns (Order memory ){
        Item[] memory itemsOrder;
        uint64 total_price = 0;
        for (uint i=0; i<items.length; i++) {
            total_price += ( items[i].product.price - items[i].product.discount + items[i].product.tax) * items[i].quantity;
        }
        int distance = Geo.getDistance(
            destination.lat, 
            destination.lng, 
            restaurants[restaurantAddress].location.lat, 
            restaurants[restaurantAddress].location.lng
        );
        uint udistance;
        if(distance < 0) {
            udistance = uint(-distance);
        }
        else {
            udistance = uint(distance);
        }
        uint256 orderId = nextOrderId++;
        uint16 status_pending = 0;
        Order memory newOrder = Order( 
            orderId,
            payable(msg.sender),
            restaurants[restaurantAddress],
            items,
            total_price,
            delivery,
            delivery_price * uint128(udistance),
            platform,
            platform_tip,
            uint128(udistance),
            destination,
            status_pending
        );
        orders[msg.sender][orderId] = newOrder;
        return newOrder;
    }

    function getOrder(address restaurantAddress, uint256 orderId) public view returns (Order memory ) {
        return orders[restaurantAddress][orderId];
    }

    function getPendingOrders(address restaurantAddress) public view returns (Order[] memory ) {
        Order[] memory pendingOrders = new Order[](0);
        uint count = 0;
        for (uint i=0; i < orders[restaurantAddress].length; i++) {
            if (orders[restaurantAddress][i].status == 0) {
                pendingOrders[count] = orders[restaurantAddress][i];
                count++;
            }
        }
        return pendingOrders;
    }

    function getOrders(address restaurantAddress) public view returns (Order[] memory ) {
        return orders[restaurantAddress];
    }


    /*
    * Aceptacion de Ordenes
    */
    function acceptOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == restaurants[restaurantAddress].id, "You aren't the restaurant owner.");
        Order memory order = orders[restaurantAddress][orderId];
        order.status = 1;
    }

    /*
    * Entregar pedido al delivery
    */
    function deliverToDelivery(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == restaurants[restaurantAddress].id, "You aren't the restaurant owner.");
        Order memory order = orders[restaurantAddress][orderId];
        order.status = 2;
    }

    /*
    * Aceptar pedido del restaurante
    */
    function recieveDelivery(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].delivery, "You aren't the delivery of this order.");
        Order memory order = orders[restaurantAddress][orderId];
        order.status = 3;
    }

    /*
    * Entregar orden
    */
    function deliverOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].delivery, "You aren't the delivery of this order.");
        Order memory order = orders[restaurantAddress][orderId];
        order.status = 4;
    }

    /*
    * Aceptar pedido del delivery
    */
    function recieveOrder(address restaurantAddress, uint256 orderId) public {
        require(msg.sender == orders[restaurantAddress][orderId].client, "You aren't the owner of this order.");
        Order memory order = orders[restaurantAddress][orderId];
        order.status = 5;
    }

    /*
    *   Cancelar pedido
    */
    function cancelOrder(address restaurantAddress, uint256 orderId) public {
        Order memory order = orders[restaurantAddress][orderId];
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
        order.status = 6;
    }

    /*
    *   Refund
    */
    function refund(address restaurantAddress, uint256 orderId) payable public {
        Order memory order = orders[restaurantAddress][orderId];
        address requestor = msg.sender;
        if(order.status == 0){
            require(requestor == order.client, "You can't refund this order.");
            order.client.transfer(order.total_price + order.delivery_price + order.platform_tip);
        } else if(order.status == 1){
            if(requestor == order.client){
                require(msg.value >= penalty_unit, "You need send more amount for pay penalty.");
                order.restaurant.id.transfer(order.total_price);
                order.client.transfer(order.delivery_price + order.platform_tip);
            }else if(requestor == order.restaurant.id){
                require(msg.value >= penalty_unit, "You need send more amount for pay penalty.");
                order.client.transfer(order.total_price + order.delivery_price + order.platform_tip + penalty_unit);
            }
        } 
        
        
        
        /*else if(order.status == 2){
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
        }*/
    }
}
