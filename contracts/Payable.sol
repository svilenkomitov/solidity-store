// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

error InsufficientBalance(uint256 _amountRequested, uint256 _availableBalance);

contract Payable {
    function send(address _to, uint256 _amount) internal {
        require(_amount > 0, "amount cannot be 0");

        if (_amount > getBalance()) {
            revert InsufficientBalance(_amount, getBalance());
        }

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "failed to send");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
