// Copyright (C) 2019 lucasvo

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

pragma solidity >=0.4.23;

import "ds-test/test.sol";

import "../pile.sol";
import "./mock/token.sol";

contract Hevm {
    function warp(uint256) public;
}


contract PileTest is DSTest {
    Pile pile;
    TokenMock tkn;

    Hevm hevm;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1234567);
        tkn = new TokenMock();
        pile = new Pile(address(tkn));
    }

    function testSetupPrecondition() public {
        tkn.setBalanceOfReturn(0);
        assertEq(pile.want(),0);
    }

    function borrow(uint loan, uint wad) public {
        uint totalBalance = pile.Balance();
        uint totalDebt = pile.Debt();

        pile.borrow(loan, wad);

        (uint debt, uint balance, uint fee, uint  chi) = pile.loans(loan);
        assertEq(pile.Balance(), totalBalance + wad);
        assertEq(pile.Debt(), totalBalance + wad);
        assertEq(debt, wad);
        assertEq(balance, wad);

    }

    function withdraw(uint loan, uint wad) public {
        uint totalBalance = pile.Balance();
        (,uint balance, ,) = pile.loans(loan);
        assertEq(balance,wad);

        pile.withdraw(loan,wad,address(this));

        assertEq(totalBalance-wad, pile.Balance());
        (,uint newBalance, ,) = pile.loans(loan);
        assertEq(balance-wad, newBalance);
        assertEq(tkn.transferFromCalls(),1);

        assertEq(tkn.dst(),address(pile));
        assertEq(tkn.src(),address(this));
        assertEq(tkn.wad(),wad);
    }

    function repay(uint loan, uint wad) public {
        uint totalDebt = pile.Debt();

        pile.repay(loan, wad, address(this));

        (uint debt,uint balance, ,) = pile.loans(loan);
        assertEq(totalDebt-wad, pile.Debt());
        assertEq(debt,0);
        assertEq(balance,0);

        assertEq(tkn.transferFromCalls(),2);
        assertEq(tkn.dst(),address(this));
        assertEq(tkn.src(),address(pile));
        assertEq(tkn.wad(),wad);

    }

    function testSimpleBorrow() public {
        uint loan  = 1;
        uint wad = 100;
        borrow(loan,wad);
    }

    function testSimpleWithdraw() public {
        uint loan  = 1;
        uint wad = 100;
        borrow(loan,wad);
        withdraw(loan, wad);
    }
    function testSimpleRepay() public {
        uint loan  = 1;
        uint wad = 100;
        borrow(loan,wad);
        withdraw(loan, wad);
        repay(loan, wad);
    }

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function testDrip() public {
        uint fee = uint(1000000564701133626865910626); // 5 % / day
        pile.file(fee, fee);
        (uint debt1, uint chi1, uint speed1, uint rho1 ) = pile.fees(fee);
        assertEq(speed1, fee);
        assertEq(rho1, now);
        assertEq(debt1, 0);
        hevm.warp(now + 1 days);

        (debt1,  chi1,  speed1,  rho1 ) = pile.fees(fee);
        assertEq(speed1, fee);
        assertEq(debt1, 0);
        assertTrue(rho1 != now);

        pile.drip(fee);

        (uint debt2, uint chi2, uint speed2, uint rho2 ) = pile.fees(fee);
        assertEq(speed2, fee);
        assertEq(rho2, now);
        assertEq(debt2, 0);

        assertTrue(chi1 != chi2);
    }

    function checkDebt(uint loan, uint should) public {
        (uint debt,,,) = pile.loans(loan);
        assertEq(debt, should);
    }

    function checkDebt(uint loan, uint should, uint tolerance) public {
        (uint debt,,,) = pile.loans(loan);
        assertEq(debt/tolerance, should/tolerance);
    }

    function testSingleCompoundSec() public  {
        /*
        Compound period in pile is in seconds
        compound seconds = (1+r/n)^nt

        fee = (1+(r/n))*10^27 (27 digits precise)

        Example:
        given a 1.05 interest per day (seconds per day 3600 * 24)

        i = (1+r/(3600*24))^(3600*24) would result in r = 0.051271065957324097526787272 per second compound

        fee = (1+(0.051271065957324097526787272/(3600*24)))*10^27
        fee = 1000000593415115246806684338

        */
        uint fee  = 1000000593415115246806684338; // 5 % per day compound in seconds
        uint loan = 1;
        uint principal = 66 ether;
        fileFee(fee, loan);
        borrow(loan, principal);

        // one day later
        hevm.warp(now + 1 days);
        pile.collect(loan);

        uint should = calculateDebt(fee, principal,uint(3600*24));
        checkDebt(loan, should);
    }


    function testSingleCompoundDay() public {
        /*
        Compound period in pile is in seconds
        compound seconds = (1+r/n)^nt

        fee = (1+(r/n))*10^27 (27 digits precise)

        Example: compound in seconds should result in 1.05 interest per day

        given i = 1.05
        solve equation for r
        i = (1+r/n)^nt
        r = n * (i^(1/n)-1

        use calculated r for fee equation
        fee = (1+((n * (i^(1/n)-1)/n))*10^27

        simplified
        fee = i^(1/n) * 10^27

        fee = 1.05^(1/(3600*24)) * 10^27 // round 27 digit
        fee = 1000000564701133626865910626

        */

        uint fee = uint(1000000564701133626865910626); // 5 % day
        pile.file(fee, fee);
        uint loan = 1;
        uint principal = 66 ether;
        pile.file(loan, fee, 0);
        borrow(loan, principal);

        checkDebt(loan, 66 ether);

        // two days later
        hevm.warp(now + 2 days);
        pile.collect(loan);

        checkDebt(loan, 72.765 ether);// 66 ether * 1,05**2
    }


    function testSingleCompoundYear() public {
        /*

        i = 1.12 // 12%
        n = 24 * 3600 * 365

        simplified fee
        fee = i^(1/n) * 10^27

        fee = 1.12^(1/(3600*24*365)) * 10^27
        fee = 1000000003593629043335673583
        */

        uint fee = uint(1000000003593629043335673583); // 12 % per year
        pile.file(fee, fee);
        uint loan = 1;
        uint principal = 66 ether;
        pile.file(loan, fee, 0);
        borrow(loan, principal);

        checkDebt(loan, 66 ether);

        // on year later
        hevm.warp(now + 365 days);
        pile.collect(loan);

        checkDebt(loan, 73.92 ether);// 66 ether * 1,12
    }

    function testDoubleDripFee() public {
        uint fee = uint(1000000564701133626865910626); // 5 % / daily
        pile.file(fee, fee);
        uint loan = 1;
        uint principal = 66 ether;
        pile.file(loan, fee, 0);
        borrow(loan, principal);
        (uint debt1,,uint fee1 ,uint chi1) = pile.loans(loan);
        assertEq(debt1, 66 ether);
        assertEq(fee, fee1);

        (, uint chiF, , ) = pile.fees(fee);

        uint start = now;
        //  1 day  later
        hevm.warp(start + 1 days);
        pile.collect(loan);

        (,  chiF, , ) = pile.fees(fee);
        (uint debt2,,uint fee2 ,uint chi2) = pile.loans(loan);
        assertEq(debt2, 69.3 ether); // 66 ether * 1,05**1
        assertEq(fee, fee2);
        assertTrue(chi1 != chi2);

        // 2 day later
        hevm.warp(start + 3 days);
        pile.collect(loan);

        (,  chiF, , ) = pile.fees(fee);
        (uint debt3,,uint fee3 ,uint chi3) = pile.loans(loan);
        assertEq(debt3, 76.40325  ether); //  66 ether * 1,05**3
        assertEq(fee, fee3);
        assertTrue(chi2 != chi3);
    }


    function fileFee(uint fee, uint loan) public {
        pile.file(fee, fee);
        pile.file(loan, fee, 0);
    }

    function calculateDebt(uint fee, uint principal, uint time) internal pure returns(uint z) {
        z = rmul(principal, rpow(fee,time,ONE));
    }

    function testFeeDifferentIntervals() public {
        uint fee = uint(1000000564701133626865910626); // 5 % / daily
        uint loan = 1;
        uint principal = 66 ether;
        fileFee(fee, loan);
        borrow(loan, principal);

        uint start = now;
        // half day later
        hevm.warp(start + 12 hours);
        pile.collect(loan);

        checkDebt(loan,  calculateDebt(fee, principal,uint(3600*12))); // 67.629875055333349329
        // 24,5  days later
        hevm.warp(start + 25 days);
        pile.collect(loan);

        uint tolerance = 10; // ignore last digit
        checkDebt(loan,  calculateDebt(fee, principal,uint(3600*24*25)),tolerance);
        pile.collect(loan); // should have no effect
        checkDebt(loan,  calculateDebt(fee, principal,uint(3600*24*25)),tolerance);
    }

}
