/**
 * IMPORTANT NOTE:  THIS HAS NOT BEEN TESTED AT ALL.
 *     IT HAS NOT BEEN DEPLOYED, IT HAS NOT BEEN UNIT TESTED, IT HAS NOT BEEN CHECKED FOR VULNERABILITIES, NOTHING.
 *     THIS IS NOT READY FOR PRODUCTION.
 */


pragma solidity 0.5.2;

contract Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    /*
    
    The MIT License (MIT)

    Copyright (c) 2016 Smart Contract Solutions, Inc.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    */

    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract AtomicSwap {
    using SafeMath for uint256;
    
    address[2] public user;
    address[2] public token;
    uint256[2] public quantity;
    uint256[2] public deposited;
    bool public swap = false;
    
    constructor(address _user1, address _token1, uint256 _quantity1, address _user2, address _token2, uint256 _quantity2) public {
        user[0] = _user1;
        Token token1 = Token(_token1);  //check token1 has the requisite functions
        token[0] = _token1;
        quantity[0] = _quantity1;
        
        user[1] = _user2;
        Token token2 = Token(_token2);  //check token2 has the requisite functions
        token[1] = _token2;
        quantity[1] = _quantity2;
    }
    
    function deposit(uint256 _quantity) public {
        //if not swapped
        require(!swap);
            
        uint256 whichuser;
        //check that sender matches either user1 or user2 and token matches corresponding token
        if(msg.sender != user[0]){
            if(msg.sender != user[1]){
                revert(); //cheaper than throw, should always refund gas in production code
            }else{
                whichuser = 1;
            }
        }else{
            whichuser = 0;
        }
        if(_quantity > quantity[whichuser].sub(deposited[whichuser])){
            _quantity = quantity[whichuser].sub(deposited[whichuser]);
        }
        //try to transferfrom _quantity of _token
        Token _token = Token(token[whichuser]);
        if(_token.transferFrom(user[whichuser], address(this), _quantity)){
            //if successful, increase deposited
            deposited[whichuser] = deposited[whichuser].add(_quantity);
            require(deposited[whichuser] <= quantity[whichuser]);
        }else{
            revert();
        }
        //if deposited1 = quantity1 and deposited2 = quantity2, swap
        if(deposited[0] == quantity[0] && deposited[1] == quantity[1]){
            swap = true;
        }
    }
    
    function withdraw() public {
        uint256 whichuser;
        uint256 otheruser;
        if(msg.sender != user[0]){
            if(msg.sender != user[1]){
                revert(); //cheaper than throw, should always refund gas in production code
            }else{
                whichuser = 1;
                otheruser = 0;
            }
        }else{
            whichuser = 0;
            otheruser = 1;
        }
        //if not swapped
        if(!swap){
            //withdraw everything in corresponding token
            require(deposited[whichuser] > 0);
            Token _token = Token(token[whichuser]);
            uint256 _quantity = deposited[whichuser];
            deposited[whichuser] = 0;
            _token.transfer(user[whichuser], _quantity);
        //else
        }else{
            //withdraw everything in other token
            require(deposited[otheruser] > 0);
            Token _token = Token(token[otheruser]);
            uint256 _quantity = deposited[otheruser];
            deposited[otheruser] = 0;
            _token.transfer(user[whichuser], _quantity);
        }
    }
}
