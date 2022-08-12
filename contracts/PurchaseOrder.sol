// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./Warehouse.sol";
import "./Payable.sol";

uint256 constant ELIGIBLE_FOR_REFUND_BEFORE = 100; // in blocks time

error PurchaseLimitReached(uint256 _id, address _customer);
error PurchaseOrderNotFound(uint256 _id, address _customer);
error NotEligibleForReturn(uint256 _id, address _customer);
error RequestedExceedsPurchaseOrderQuantity(
    uint256 _id,
    address _customer,
    uint256 _requested,
    uint256 _actual
);
error InvalidPurchaseOrderAmountSent(uint256 _amountSent, uint256 _totalPrice);
error PurchaseOrderIsAlreadyRefunded(uint256 _id, address _customer);

struct Item {
    uint256 id;
    uint256 quantity;
}

struct Order {
    Item item;
    uint256 createdAt; // in blocks time
    address createdBy;
    bool isRefunded;
}

contract PurchaseOrder is Payable {
    Catalog private catalog;
    Warehouse private warehouse;
    mapping(uint256 => mapping(address => Order)) private orders;
    mapping(uint256 => address[]) private customers;

    constructor(Catalog _catalog, Warehouse _warehouse) {
        catalog = _catalog;
        warehouse = _warehouse;
    }

    event PurchaseOrderCreated(
        uint256 _id,
        uint256 _quantity,
        address _customer
    );

    event RefundRequested(uint256 _id, uint256 _quantity, address _customer);

    function submitOrder(uint256 _id, uint256 _quantity) external payable {
        require(_quantity > 0, "quantity cannot be 0");

        address createdBy = tx.origin;

        if (_hasPurchaseOrder(_id)) {
            revert PurchaseLimitReached(_id, createdBy);
        }

        uint256 totalPrice = catalog.getProduct(_id).price * _quantity;
        if (msg.value != totalPrice) {
            revert InvalidPurchaseOrderAmountSent(msg.value, totalPrice);
        }

        warehouse.subQuantity(_id, _quantity);

        orders[_id][createdBy] = Order({
            item: Item({id: _id, quantity: _quantity}),
            createdAt: block.number,
            createdBy: createdBy,
            isRefunded: false
        });

        customers[_id].push(createdBy);
        emit PurchaseOrderCreated(_id, _quantity, createdBy);
    }

    function requestRefund(uint256 _id, uint256 _quantity) external {
        address requestedBy = tx.origin;

        if (!_hasPurchaseOrder(_id)) {
            revert PurchaseOrderNotFound(_id, requestedBy);
        }

        Order storage order = orders[_id][requestedBy];
        if (block.number - order.createdAt > ELIGIBLE_FOR_REFUND_BEFORE) {
            revert NotEligibleForReturn(_id, requestedBy);
        }

        if (_quantity > order.item.quantity) {
            revert RequestedExceedsPurchaseOrderQuantity(
                _id,
                requestedBy,
                _quantity,
                order.item.quantity
            );
        }

        if (order.isRefunded) {
            revert PurchaseOrderIsAlreadyRefunded(_id, requestedBy);
        }

        uint256 amountToRefund = catalog.getProduct(_id).price * _quantity;
        send(tx.origin, amountToRefund);

        warehouse.addQuantity(_id, _quantity);
        order.isRefunded = true;
        emit RefundRequested(_id, _quantity, requestedBy);
    }

    function listCustomers(uint256 _id) external view returns (address[] memory) {
        return customers[_id];
    }

    function _hasPurchaseOrder(uint256 _id) private view returns (bool) {
        return orders[_id][tx.origin].item.id != 0;
    }
}
