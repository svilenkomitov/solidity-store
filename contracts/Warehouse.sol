// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./Catalog.sol";

error InsufficientQuantity(uint256 _id, uint256 _requested, uint256 _available);

contract Warehouse {
    Catalog private catalog;
    Product[] private availableProducts;
    mapping(uint256 => uint256) private availableProductsIndexes;
    mapping(uint256 => uint256) private inventory;

    constructor(Catalog _catalog) {
        catalog = _catalog;
    }

    event ProductQuantityUpdated(uint256 _id, uint256 _quantity);

    function addProduct(uint256 _id, uint256 _price, uint256 _quantity) public {
        catalog.addProduct(_id, _price);

        if (_quantity > 0) {
            availableProducts.push(catalog.getProduct(_id));

            uint256 index = uint256(availableProducts.length - 1);
            availableProductsIndexes[_id] = index;
            inventory[_id] += _quantity;
        }
    }

    function addQuantity(uint256 _id, uint256 _quantity) public {
        _updateQuantity(_id, _getQuantity(_id) + _quantity);
    }

    function subQuantity(uint256 _id, uint256 _quantity) public {
        if (_quantity > _getQuantity(_id)) {
            revert InsufficientQuantity(_id, _quantity, inventory[_id]);
        }
        _updateQuantity(_id, _getQuantity(_id) - _quantity);
    }

    function listAvailableProducts() public view returns (Product[] memory) {
        return availableProducts;
    }

    function _updateQuantity(uint256 _id, uint256 _quantity) private {
        if (_quantity > 0 && !_isProductAvailable(_id)) {
            availableProducts.push(catalog.getProduct(_id));

            uint256 index = uint256(availableProducts.length - 1);
            availableProductsIndexes[_id] = index;
        } else if (_quantity == 0 && _isProductAvailable(_id)) {
            uint256 index = availableProductsIndexes[_id];
            availableProducts[index] = availableProducts[
                availableProducts.length - 1
            ];
            availableProducts.pop();
        }

        inventory[_id] = _quantity;
        emit ProductQuantityUpdated(_id, _quantity);
    }

    function _isProductAvailable(uint256 _id) private view returns (bool) {
        return inventory[_id] > 0 && catalog.productExists(_id);
    }

    function _getQuantity(uint256 _id) private view returns (uint256) {
        return inventory[_id];
    }
}