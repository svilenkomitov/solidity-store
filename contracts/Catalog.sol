// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

error ProductAlreadyExists(uint256 _id);
error ProductNotFound(uint256 _id);

struct Product {
    uint256 id;
    uint256 price; // in wei
}

contract Catalog {
    mapping(uint256 => bool) private _isInCatalog;
    mapping(uint256 => Product) private products;

    event NewProductAdded(uint256 _id, uint256 _price, address _admin);

    modifier notInCatalog(uint256 _id) {
        if (productExists(_id)) {
            revert ProductAlreadyExists(_id);
        }
        _;
    }

    modifier isInCatalog(uint256 _id) {
        if (!productExists(_id)) {
            revert ProductNotFound(_id);
        }
        _;
    }

    function addProduct(uint256 _id, uint256 _price) public notInCatalog(_id) {
        products[_id] = Product({id: _id, price: _price});
        _isInCatalog[_id] = true;
        emit NewProductAdded(_id, _price, tx.origin);
    }

    function productExists(uint256 _id) public view returns (bool) {
        return _isInCatalog[_id];
    }

    function getProduct(uint256 _id) public view isInCatalog(_id) returns (Product memory) {
        return products[_id];
    }
}