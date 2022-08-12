// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AccessControl.sol";
import "./Catalog.sol";
import "./Warehouse.sol";
import "./PurchaseOrder.sol";

contract Store is AccessControl {
    Catalog private catalog;
    Warehouse private warehouse;
    PurchaseOrder private purchaseOrder;

    constructor() {
        catalog = new Catalog();
        warehouse = new Warehouse(catalog);
        purchaseOrder = new PurchaseOrder(catalog, warehouse);
    }

    function addProduct(uint256 _id, uint256 _price) external isAdmin {
        warehouse.addProduct(_id, _price, 0);
    }

    function addProduct(uint256 _id, uint256 _price, uint256 _quantity) external isAdmin {
        warehouse.addProduct(_id, _price, _quantity);
    }

    function addQuantity(uint256 _id, uint256 _quantity) external isAdmin {
        warehouse.addQuantity(_id, _quantity);
    }

    function listAvailableProducts() external view returns (Product[] memory) {
        return warehouse.listAvailableProducts();
    }

    function submitOrder(uint256 _id, uint256 _quantity) external payable isCustomer {
        purchaseOrder.submitOrder{value: msg.value}(_id, _quantity);
    }

    function requestRefund(uint256 _id, uint256 _quantity) external isCustomer {
        purchaseOrder.requestRefund(_id, _quantity);
    }

    function listCustomers(uint256 _id) external view returns (address[] memory) {
        return purchaseOrder.listCustomers(_id);
    }

    function getBalance() external view isAdmin returns (uint256) {
        return purchaseOrder.getBalance();
    }
}