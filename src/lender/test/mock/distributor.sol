// Copyright (C) 2019 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import "tinlake-math/math.sol";
import "tinlake-auth/auth.sol";

import "../../../test/mock/mock.sol";

contract DistributorMock is Mock {
    function balance() public returns (uint) {
        return call("balance");
    }
    function repayTranches(uint amount) public {
        calls["repay_tranches"]++;
        values_uint["repay_tranches_amount"] = amount;
    }
}