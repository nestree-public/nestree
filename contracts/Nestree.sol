pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./BaseToken.sol";

contract Nestree is BaseToken
{
    using SafeMath for uint256;

    string constant internal ERROR_DUPLICATE_ADDRESS = 'Reason: msg.sender and receivers can not be the same.';

    // MARK: token information.
    string constant public name    = 'Nestree';
    string constant public symbol  = 'EGG';
    string constant public version = '1.0.0';

    // MARK: events
    event ReferralDrop(address indexed from, address indexed to1, uint256 value1, address indexed to2, uint256 value2);
    event TransferMulti(address indexed from, address[] receivers, uint256[] amounts);

    constructor() public
    {
        totalSupply = 3000000000 * E18;
        balances[msg.sender] = totalSupply;
    }

    function referralDrop(address _to1, uint256 _value1, address _to2, uint256 _value2, address _sale, uint256 _fee) external onlyWhenNotStopped returns (bool)
    {
        require(_to1 != address(0), ERROR_ADDRESS_NOT_VALID);
        require(_to2 != address(0), ERROR_ADDRESS_NOT_VALID);
        require(_sale != address(0), ERROR_ADDRESS_NOT_VALID);
        require(balances[msg.sender] >= _value1.add(_value2).add(_fee), ERROR_VALUE_NOT_VALID);
        require(!isLocked(msg.sender, _value1.add(_value2).add(_fee)), ERROR_LOCKED);
        require(msg.sender != _to1 && msg.sender != _to2 && msg.sender != _sale, ERROR_DUPLICATE_ADDRESS);

        balances[msg.sender] = balances[msg.sender].sub(_value1.add(_value2).add(_fee));

        if(_value1 > 0)
        {
            balances[_to1] = balances[_to1].add(_value1);
        }

        if(_value2 > 0)
        {
            balances[_to2] = balances[_to2].add(_value2);
        }

        if(_fee > 0)
        {
            balances[_sale] = balances[_sale].add(_fee);
        }

        emit ReferralDrop(msg.sender, _to1, _value1, _to2, _value2);
        return true;
    }

    function transferMulti(address[] calldata _receivers, uint256[] calldata _amounts) external onlyWhenNotStopped returns (bool)
    {
        uint256 receiversLength = _receivers.length;
        uint256 amountsLength = _amounts.length;

        require(receiversLength > 0, ERROR_ADDRESS_NOT_VALID);
        require(amountsLength > 0, ERROR_ADDRESS_NOT_VALID);
        require(receiversLength == amountsLength, ERROR_ADDRESS_NOT_VALID);

        uint256 sum = 0;

        for(uint256 i=0; i<receiversLength; i++)
        {
            require(_receivers[i] != address(0), ERROR_ADDRESS_NOT_VALID);
            require(_amounts[i] > 0, ERROR_VALUE_NOT_VALID);

            sum = sum.add(_amounts[i]);
        }

        require(balances[msg.sender] >= sum, ERROR_VALUE_NOT_VALID);
        require(!isLocked(msg.sender, sum), ERROR_LOCKED);

        for(uint256 i=0; i<receiversLength; i++)
        {
            balances[_receivers[i]] = balances[_receivers[i]].add(_amounts[i]);
        }

        balances[msg.sender] = balances[msg.sender].sub(sum);

        emit TransferMulti(msg.sender, _receivers, _amounts);

        return true;
    }
}