// Copyright (C) 2020 Centrifuge
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
pragma solidity >=0.5.15 <0.6.0;

import { TinlakeRoot } from "../../root.sol";
import "ds-test/test.sol";
contract TestRoot is TinlakeRoot {
    constructor (address deployUsr) public TinlakeRoot(deployUsr) {
    }
    // Permissions
    // To simplify testing, we add helpers to authorize contracts on any component.

    // Needed for System Tests
    function relyBorrowerAdmin(address usr) public auth {
        relyContract(borrowerDeployer.title(), usr);
        relyContract(borrowerDeployer.shelf(), usr);
        relyContract(borrowerDeployer.pile(), usr);
        relyContract(borrowerDeployer.feed(), usr);
        relyContract(borrowerDeployer.collector(), usr); 
    }

    // Needed for System Tests
    function relyLenderAdmin(address usr) public auth {
        relyContract(lenderDeployer.juniorMemberlist(), usr);
        relyContract(lenderDeployer.seniorMemberlist(), usr);
    }

    function denyBorrowerAdmin(address usr) public auth {
        denyContract(borrowerDeployer.title(), usr);
        denyContract(borrowerDeployer.feed(), usr);
        denyContract(borrowerDeployer.shelf(), usr);
        denyContract(borrowerDeployer.pile(), usr);
        denyContract(borrowerDeployer.feed(), usr);
        denyContract(borrowerDeployer.collector(), usr);
    }
}
