// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

error Unauthorized(string msg);

contract AccessControl {
    address private owner;

    constructor() {
        owner = tx.origin;
    }

    modifier isAdmin() {
        if (tx.origin != owner) {
            revert Unauthorized("Only admins can request the resource.");
        }
        _;
    }

    modifier isCustomer() {
        if (tx.origin == owner) {
            revert Unauthorized("Only customers can request the resource.");
        }
        _;
    }
}
